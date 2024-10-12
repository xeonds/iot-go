package main

import (
	"fmt"
	"gateway/config"
	"gateway/handler"
	"gateway/misc"
	"gateway/model"
	"log"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/xeonds/libgc"
	"gorm.io/gorm"
)

func main() {
	config := libgc.LoadConfig[config.Config]()
	db := libgc.NewDB(&config.DB, func(db *gorm.DB) error {
		return db.AutoMigrate(&model.Client{}, &model.Rule{})
	})
	gatewayConns := new([]*websocket.Conn)
	clientConns := make(map[string]*websocket.Conn)

	router := gin.Default()
	router.GET("/ws/device", handler.DeviceWebSocketHandler(db))
	router.GET("/ws/gateway", handler.GatewayWebSocketHandler(db))
	api := router.Group("/api")
	{
		api.POST("/register/:id", handler.RegisterDevice(db))
		api.POST("/control/:id/:action", handler.ControlDevice(db, *gatewayConns, clientConns))
		api.POST("/status/:id", handler.GetDeviceStatus(db))
		api.POST("/rename/:id/:name", handler.RenameDevice(db))
		api.POST("/unregister/:id", handler.UnregisterDevice(db, *gatewayConns, clientConns))
		api.GET("/devices", handler.GetDevices(db))
	}
	go misc.MonitorDeviceConnections(clientConns, db, config.Heartbeat)
	go misc.RunmDnsBroadcast(config)
	go log.Fatal(router.Run(fmt.Sprintf(":%d", config.Port)))
	select {}
}
