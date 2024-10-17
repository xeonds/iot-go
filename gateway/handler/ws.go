package handler

import (
	"fmt"
	"gateway/model"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

// 设备消息通道
// 设备处理管道
var deviceMessageChannel = make(chan model.DeviceAPIMessage, 100)

func handleDeviceMessage(db *gorm.DB) {
	for msg := range deviceMessageChannel {
		log.Printf("处理设备消息: %s", msg.Message)
	}
}

func StartDeviceMessageHandler(db *gorm.DB) {
	go handleDeviceMessage(db) // 后台处理设备消息
}

func DeviceWebSocketHandler(db *gorm.DB, conns map[string]*websocket.Conn) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "设备 ID 不能为空"})
			return
		}
		conn, err := (&websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			}}).Upgrade(c.Writer, c.Request, nil)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "无法升级为 WebSocket"})
			return
		}
		defer conn.Close()
		conns[id] = conn
		db.FirstOrCreate(&model.Client{ID: id, Status: "online", Addr: c.ClientIP()})
		var device model.Client
		for {
			_, message, err := conn.ReadMessage()
			if err != nil {
				log.Println("读取消息错误:", err)
				break
			}
			deviceMessageChannel <- model.DeviceAPIMessage{Conn: conn, Message: message}
		}

		// 设备断开连接时，更新数据库
		db.Model(&device).Where("id = ?", device.ID).Update("status", "-1")
		conns[id] = nil
	}
}

var parentGatewayCmdChannel = make(chan struct {
	Conn    *websocket.Conn
	Message model.GatewayAPIMessage
}, 100)

// TODO: implement handle gateway api messages
func handleGatewayCmds(db *gorm.DB) {
	for msg := range parentGatewayCmdChannel {
		log.Printf("处理父网关消息: %s", msg.Message)
	}
}

func RegisterToParentGateway(parentGateway string) error {
	conn, _, err := websocket.DefaultDialer.Dial(parentGateway, nil)
	if err != nil {
		return fmt.Errorf("连接父网关 %s 失败: %v", parentGateway, err)
	}
	defer conn.Close()
	for {
		var message model.GatewayAPIMessage
		if err := conn.ReadJSON(&message); err != nil {
			log.Printf("读取父网关消息失败: %v", err)
			continue
		}
		log.Printf("收到父网关消息: %s", message)
		parentGatewayCmdChannel <- struct {
			Conn    *websocket.Conn
			Message model.GatewayAPIMessage
		}{Conn: conn, Message: message}
	}
}

func StartGatewayCmdHandler(db *gorm.DB) {
	go handleGatewayCmds(db)
}

func GatewayWebSocketHandler(db *gorm.DB, conns map[string]*websocket.Conn) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "设备 ID 不能为空"})
			return
		}
		conn, err := (&websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
		}).Upgrade(c.Writer, c.Request, nil)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "无法升级为 WebSocket"})
			return
		}
		defer conn.Close()
		conns[id] = conn
		for {
			_, message, err := conn.ReadMessage()
			if err != nil {
				log.Println("子网关连接断开或读取消息失败:", err)
				break
			}
			log.Printf("收到子网关消息: %s", message)
		}
		conns[id] = nil
	}
}
