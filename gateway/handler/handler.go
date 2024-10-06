package handler

import (
	"gateway/misc"
	"gateway/model"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func RegisterDevice(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		name := c.PostForm("name")
		addr := c.ClientIP()
		client := model.Client{ID: id, Name: name, Addr: addr}
		db.Create(&client)
		c.JSON(200, gin.H{"status": "ok"})
	}
}

func GetDevices(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		clients := new([]model.Client)
		db.Find(clients)
		c.JSON(200, clients)
	}
}

func GetDeviceStatus(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		client := new(model.Client)
		db.First(client, "id = ?", id)
		c.JSON(200, gin.H{"status": client.Status})
	}
}

func ControlDevice(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		action := c.Param("action")
		var client model.Client
		db.First(&client, "id = ?", id)
		misc.ActionExec(client.ID, action, db)
		c.JSON(200, gin.H{"status": "ok"})
	}
}
