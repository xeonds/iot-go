package main

import (
	"fmt"
	"gateway/config"
	"gateway/controller"
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
	gatewayConns, clientConns := make(map[string]*websocket.Conn), make(map[string]*websocket.Conn)
	router := gin.Default()
	router.GET("/ws/device/:id", handler.DeviceWebSocketHandler(db, clientConns))
	router.GET("/ws/gateway/:id", handler.GatewayWebSocketHandler(db, gatewayConns))
	api := router.Group("/api")
	{
		api.POST("/register/:id", func(c *gin.Context) {
			err := controller.RegisterDevice(db, c.Param("id"), "", c.ClientIP())
			misc.GinErrWrapper(c, err)
		})
		api.POST("/control/:id/:action", func(c *gin.Context) {
			err := controller.ControlDevice(db, clientConns[c.Param("id")], c.Param("id"), c.Param("action"))
			misc.GinErrWrapper(c, err)
		})
		api.POST("/status/:id", func(c *gin.Context) {
			c.JSON(200, controller.GetDeviceStatus(db, c.Param("id")))
		})
		api.POST("/rename/:id/:name", func(c *gin.Context) {
			err := controller.RenameDevice(db, c.Param("id"), c.Param("name"))
			misc.GinErrWrapper(c, err)
		})
		api.POST("/unregister/:id", func(c *gin.Context) {
			err := controller.UnregisterDevice(db, c.Param("id"), clientConns[c.Param("id")])
			misc.GinErrWrapper(c, err)
		})
		api.GET("/devices", func(c *gin.Context) {
			c.JSON(200, controller.GetDevices(db))
		})
	}

	if config.ParentGateway != "" {
		go handler.RegisterToParentGateway(config.ParentGateway)
	}

	go misc.MonitorDeviceConnections(clientConns, db, config.Heartbeat)
	go handler.StartGatewayCmdHandler(db)
	go handler.StartDeviceMessageHandler(db)
	go misc.RunmDnsBroadcast(config)
	go log.Fatal(router.Run(fmt.Sprintf(":%d", config.Port)))
	select {}
}
