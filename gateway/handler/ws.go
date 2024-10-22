package handler

import (
	"encoding/json"
	"fmt"
	"gateway/controller"
	"gateway/misc"
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
		mesg, err := misc.ParseDSL(string(msg.Message))
		if err != nil {
			log.Printf("解析 DSL 错误: %v", err)
			continue
		}
		switch mesg.Type {
		case "data":
			if mesg.Key == "status" {
				db.Model(&model.Client{}).Where("id = ?", msg.DeviceID).Update("status", mesg.Value)
			} else {
				// dataRecord := model.Data{DeviceID: msg.DeviceID, Key: mesg.Key}
				// if err := db.FirstOrCreate(&dataRecord, model.Data{DeviceID: msg.DeviceID, Key: mesg.Key}).Error; err != nil {
				// 	log.Printf("创建或查找数据记录错误: %v", err)
				// 	continue
				// }
				// if mesg.Limit > 0 {
				// 	db.Model(&dataRecord).First(&dataRecord)
				// 	if len(dataRecord.Value) >= mesg.Limit {
				// 		dataRecord.Value = dataRecord.Value[1:] // pop the first element
				// 	}
				// 	dataRecord.Value = append(dataRecord.Value, mesg.Value)
				// 	db.Model(&dataRecord).Update("value", dataRecord.Value)
				// } else {
				// 	db.Model(&dataRecord).Update("value", []string{mesg.Value})
				// }
			}
		}
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
		if db.First(&model.Client{}, "id = ?", id).Error != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "未注册设备"})
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
		// TODO:（设备重名）如果当前连接非空，关闭之前的连接
		conns[id] = conn
		db.FirstOrCreate(&model.Client{ID: id, Status: "online", Addr: c.ClientIP()})
		log.Printf("%s 已连接", id)
		var device model.Client
		for {
			_, message, err := conn.ReadMessage()
			if err != nil {
				log.Println("读取消息错误:", err)
				break
			}
			deviceMessageChannel <- model.DeviceAPIMessage{Conn: conn, Message: message, DeviceID: id}
		}

		// 设备断开连接时，更新数据库
		db.Model(&device).Where("id = ?", device.ID).Update("status", "-1")
		conns[id] = nil
	}
}

var parentGatewayCmdChannel = make(chan struct {
	Conn    *websocket.Conn
	Message string
}, 100)

// TODO: implement handle gateway api messages
func handleGatewayCmds(db *gorm.DB) {
	for m := range parentGatewayCmdChannel {
		msg, err := misc.ParseDSL(string(m.Message))
		if err != nil {
			log.Printf("解析 DSL 错误: %v", err)
			continue
		}
		switch msg.Type {
		case "devices":
			res := controller.GetDevices(db)
			response, err := json.Marshal(res)
			if err != nil {
				log.Printf("序列化设备列表错误: %v", err)
				continue
			}
			err = m.Conn.WriteMessage(websocket.TextMessage, response)
			if err != nil {
				log.Printf("发送设备列表错误: %v", err)
				continue
			}
		}
	}
}

func RegisterToParentGateway(parentGateway string) error {
	conn, _, err := websocket.DefaultDialer.Dial(parentGateway, nil)
	if err != nil {
		return fmt.Errorf("连接父网关 %s 失败: %v", parentGateway, err)
	}
	defer conn.Close()
	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Printf("读取父网关消息失败: %v", err)
			continue
		}
		log.Printf("收到父网关消息: %s", message)
		parentGatewayCmdChannel <- struct {
			Conn    *websocket.Conn
			Message string
		}{Conn: conn, Message: string(message)}
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