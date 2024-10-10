package handler

import (
	"gateway/misc"
	"gateway/model"
	"net/http"

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

func RenameDevice(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		name := c.Param("name")
		db.Model(&model.Client{}).Where("id = ?", id).Update("name", name)
		c.JSON(200, gin.H{"status": "ok"})
	}
}

func UnregisterDevice(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		client := new(model.Client)
		if err := db.First(client, "id = ?", id).Error; err != nil {
			c.JSON(404, gin.H{"status": "client not found"})
			return
		}

		resp, err := http.Post("http://"+client.Addr+"/reset", "", nil)
		if err != nil || resp.StatusCode != 200 {
			c.JSON(500, gin.H{"status": "failed to reset device"})
			return
		}

		db.Delete(&model.Client{}, "id = ?", id)
		c.JSON(200, gin.H{"status": "ok"})
	}
}

func ControlDevice(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if err := misc.ActionExec(c.Param("id"), c.Param("action"), db); err != nil {
			c.JSON(500, gin.H{"status": "failed to exec action"})
			return
		}
		c.JSON(200, gin.H{"status": "ok"})
	}
}
