package main

import (
	"fmt"
	"gateway/config"
	"gateway/handler"
	"gateway/misc"
	"gateway/model"
	"log"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/grandcat/zeroconf"
	"github.com/xeonds/libgc"
	"gorm.io/gorm"
)

func main() {
	config := libgc.LoadConfig[config.Config]()
	db := libgc.NewDB(&config.DB, func(db *gorm.DB) error {
		return db.AutoMigrate(&model.Client{}, &model.Rule{})
	})

	router := gin.Default()
	router.POST("/register/:id", handler.RegisterDevice(db))
	router.POST("/control/:id/:action", handler.ControlDevice(db))
	router.POST("/status/:id", handler.GetDeviceStatus(db))
	router.POST("/rename/:id/:name", handler.RenameDevice(db))
	router.POST("/unregister/:id", handler.UnregisterDevice(db))
	router.GET("/devices", handler.GetDevices(db))

	go func() {
		for range time.Tick(1 * time.Minute) {
			rules := new(misc.Rules)
			db.Find(rules)
			for _, rule := range rules.Match(time.Now().String()) {
				misc.ActionExec(rule.DeviceID, rule.Action, db)
			}
		}
	}()
	go misc.ScanDevices(5, db)
	go misc.UpdateDeviceStatus(5, db)
	go mDnsBroadcast()
	go log.Fatal(router.Run(fmt.Sprintf(":%d", config.Port)))
}

func mDnsBroadcast() {
	serviceName := "_iot-gateway._tcp"
	serviceDomain := "local."
	servicePort := 1234 // 这个是你服务器 API 所使用的端口
	instanceName := "iot-gateway-instance"

	// 发布 mDNS 服务
	server, err := zeroconf.Register(instanceName, serviceName, serviceDomain, servicePort, []string{"gateway"}, nil)
	if err != nil {
		log.Fatalf("Failed to register mDNS service: %v", err)
	}
	defer server.Shutdown()
	log.Printf("mDNS service %s.%s:%d published", instanceName, serviceName, servicePort)
	// 模拟一直运行服务
	select {}
}
