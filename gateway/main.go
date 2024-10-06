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
	go log.Fatal(router.Run(fmt.Sprintf(":%d", config.Port)))
}
