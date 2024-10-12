package handler

import (
	"gateway/misc"
	"gateway/model"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

// TODO: execute only in one gateway in case of conflict
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

// TODO: also get subgateway's devices
func GetDevices(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		clients := new([]model.Client)
		db.Find(clients)
		c.JSON(200, clients)
	}
}

// TODO: execute in subgateway if device not in current db
func GetDeviceStatus(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		client := new(model.Client)
		db.First(client, "id = ?", id)
		c.JSON(200, gin.H{"status": client.Status})
	}
}

// TODO: execute in subgateway if device not in current db
func RenameDevice(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		name := c.Param("name")
		db.Model(&model.Client{}).Where("id = ?", id).Update("name", name)
		c.JSON(200, gin.H{"status": "ok"})
	}
}

// TODO: execute in subgateway if device not in current db
func UnregisterDevice(db *gorm.DB, gatewayConns []*websocket.Conn, clientConns map[string]*websocket.Conn) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		client := new(model.Client)
		if err := db.First(client, "id = ?", id).Error; err != nil {
			for _, conn := range gatewayConns {
				conn.WriteJSON(map[string]string{"action": "unregister", "id": id})
			}
		} else {
			clientConns[id].WriteJSON(map[string]string{"action": "unregister", "id": id})
		}
		db.Delete(&model.Client{}, "id = ?", id)
		c.JSON(200, gin.H{"status": "ok"})
	}
}

// ConcurrentExecution is a helper function to handle concurrent tasks and collect results
func ConcurrentExecution(tasks []func() map[string]string) map[string]string {
	var wg sync.WaitGroup
	resultChannel := make(chan map[string]string, len(tasks))
	finalResults := make(map[string]string)

	for _, task := range tasks {
		wg.Add(1)
		go func(task func() map[string]string) {
			defer wg.Done()
			resultChannel <- task()
		}(task)
	}

	go func() {
		wg.Wait()
		close(resultChannel)
	}()

	for res := range resultChannel {
		for k, v := range res {
			finalResults[k] = v
		}
	}

	return finalResults
}

// 执行单个设备控制任务
// 1. 如果设备在当前网关，则直接执行任务
// 2. 如果设备不在当前网关，则转发任务到子网关
// 3. 如果设备不在任何网关，则返回错误
func ControlDevice(db *gorm.DB, subGateways []*websocket.Conn, clientConns map[string]*websocket.Conn) gin.HandlerFunc {
	return func(c *gin.Context) {
		deviceID, action := c.Param("id"), c.Param("action")
		client := new(model.Client)
		tasks := []func() map[string]string{}

		if err := db.First(client, "id = ?", deviceID).Error; err != nil {
			tasks = append(tasks, func() map[string]string {
				result := make(map[string]string)
				if err := misc.RunAction(deviceID, action, db, clientConns[deviceID]); err != nil {
					result["main_gateway"] = "主网关任务执行失败"
				} else {
					result["main_gateway"] = "ok"
				}
				return result
			})
		} else {
			for _, conn := range subGateways {
				tasks = append(tasks, func() map[string]string {
					result := make(map[string]string)
					if err := conn.WriteJSON(map[string]string{"id": deviceID, "action": action}); err != nil {
						result["sub_gateway"] = "子网关任务执行失败"
					} else if err := conn.ReadJSON(&result); err != nil {
						result["sub_gateway"] = "子网关任务执行失败"
					} else {
						result["sub_gateway"] = "ok"
					}
					return result
				})
			}
		}

		finalResults := ConcurrentExecution(tasks)

		if len(finalResults) == 0 {
			c.JSON(500, gin.H{"status": "failed to control device"})
		} else {
			c.JSON(200, finalResults)
		}
	}
}
