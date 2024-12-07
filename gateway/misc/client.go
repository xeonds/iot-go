package misc

import (
	"fmt"
	"gateway/model"
	"log"
	"time"

	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

// 定期获取所有设备状态并更新数据库
func MonitorDeviceConnections(connections map[string]*websocket.Conn, db *gorm.DB, duration int) {
	ticker := time.NewTicker(time.Duration(duration) * time.Second) // 30秒检测一次心跳
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			for deviceID, conn := range connections {
				if conn == nil {
					continue
				}
				if err := conn.WriteMessage(websocket.PingMessage, []byte{}); err != nil {
					log.Printf("设备 %s 心跳检测失败，标记为离线", deviceID)
					db.Model(&model.Client{}).Where("id = ?", deviceID).Update("status", "-1")
					connections[deviceID] = nil
				}
			}
		}
	}
}

// RunAction 向设备发送指令并更新数据库
// TODO: support multi-line commands, like a;b;c;, and support commands like gateway.suspend:1500;
func RunAction(deviceID, action string, db *gorm.DB, conn *websocket.Conn) error {
	if conn == nil {
		return fmt.Errorf("device %s not connected", deviceID)
	}

	client := new(model.Client)
	db.First(client, "id = ?", deviceID)
	if client.ID == "" {
		return fmt.Errorf("device %s not found", deviceID)
	}
	if err := conn.WriteMessage(websocket.TextMessage, []byte(action)); err != nil {
		db.Model(client).Update("status", "-1")
		return fmt.Errorf("failed to send WebSocket message: %w", err)
	}
	return nil
}

func RunActions(deviceID string, actions []string, db *gorm.DB, conn *websocket.Conn) error {
	for _, action := range actions {
		if parsed, err := ParseDSL(action); err != nil {
			return err
		} else {
			if parsed.Type == "gateway" {
				switch parsed.Key {
				case "suspend":
					time.Sleep(time.Duration(parsed.Limit) * time.Second)
					continue
				}
			} else {
				if err := RunAction(deviceID, action, db, conn); err != nil {
					return err
				}
			}
		}
	}
	return nil
}
