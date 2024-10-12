package handler

import (
	"errors"
	"gateway/model"
	"log"
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

// 设备消息通道
type DeviceMessage struct {
	Conn    *websocket.Conn
	Message []byte
}

// 设备处理管道
var deviceMessageChannel = make(chan DeviceMessage, 100)

// Goroutine 处理设备消息
func handleDeviceMessage(db *gorm.DB) {
	for msg := range deviceMessageChannel {
		var device model.Client
		// 解析消息并更新设备状态
		log.Printf("处理设备消息: %s", msg.Message)
		db.Model(&device).Where("device_id = ?", "example_id").Update("status", "online")
	}
}

// 启动 Goroutine 以并发处理设备消息
func StartDeviceMessageHandler(db *gorm.DB) {
	go handleDeviceMessage(db) // 后台处理设备消息
}

var deviceUpgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func DeviceWebSocketHandler(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		conn, err := deviceUpgrader.Upgrade(c.Writer, c.Request, nil)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "无法升级为 WebSocket"})
			return
		}

		defer conn.Close()

		var device model.Client

		for {
			// 读取设备发送的消息
			_, message, err := conn.ReadMessage()
			if err != nil {
				log.Println("读取消息错误:", err)
				break
			}

			log.Printf("收到设备消息: %s", message)

			// 将消息推送到 channel 中，交由 Goroutine 并发处理
			deviceMessageChannel <- DeviceMessage{Conn: conn, Message: message}
		}

		// 设备断开连接时，更新数据库
		db.Model(&device).Where("device_id = ?", device.ID).Update("status", "-1")
	}
}

var gatewayUpgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func GatewayWebSocketHandler(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		conn, err := gatewayUpgrader.Upgrade(c.Writer, c.Request, nil)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "无法升级为 WebSocket"})
			return
		}

		defer conn.Close()

		for {
			// 读取子网关的消息
			_, message, err := conn.ReadMessage()
			if err != nil {
				log.Println("子网关连接断开或读取消息失败:", err)
				break
			}

			log.Printf("收到子网关消息: %s", message)

			// 根据接收到的消息可以处理设备状态同步等逻辑
			// 假设子网关同步了设备的状态，可以更新到数据库中
			// 这里可以解析消息内容，比如是设备状态更新，或者任务执行的结果
			// 具体格式和逻辑取决于实际的协议

			// 假设消息是 JSON 格式，可以解析后更新设备状态
			// 使用伪代码解析 message 为 JSON 对象
			// err := json.Unmarshal(message, &device)
			// if err == nil {
			//     db.Model(&device).Where("device_id = ?", device.DeviceID).Update("status", device.Status)
			// }
		}
	}
}

// 用于保存每个子网关的响应
type SubGatewayResponse struct {
	GatewayID string
	Result    string
	Error     error
}

// Goroutine 并发处理子网关请求
func ForwardTaskToSubGateways(deviceID string, action string, conns []*websocket.Conn) (map[string]string, error) {
	var wg sync.WaitGroup
	resultChannel := make(chan SubGatewayResponse, len(conns)) // 使用 channel 收集每个子网关的响应

	for _, conn := range conns {
		wg.Add(1)
		go func(conn *websocket.Conn) {
			defer wg.Done()
			err := conn.WriteJSON(map[string]string{"device_id": deviceID, "action": action})
			resultChannel <- SubGatewayResponse{GatewayID: conn.RemoteAddr().String(), Result: "", Error: err}
		}(conn)
	}

	// 等待所有 Goroutines 完成
	go func() {
		wg.Wait()
		close(resultChannel)
	}()

	// 收集所有子网关的响应
	finalResults := make(map[string]string)
	for res := range resultChannel {
		if res.Error != nil {
			log.Printf("子网关 %s 执行任务失败: %v", res.GatewayID, res.Error)
		} else {
			finalResults[res.GatewayID] = res.Result
		}
	}

	if len(finalResults) == 0 {
		return nil, errors.New("所有子网关任务执行失败")
	}

	return finalResults, nil
}
