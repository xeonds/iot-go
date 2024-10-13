package controller

import (
	"gateway/misc"
	"gateway/model"

	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

func RegisterDevice(db *gorm.DB, id, name, addr string) error {
	client := model.Client{ID: id, Name: name, Addr: addr}
	return db.Create(&client).Error
}

func GetDevices(db *gorm.DB) *[]model.Client {
	clients := new([]model.Client)
	db.Find(clients)
	return clients
}

func GetDeviceStatus(db *gorm.DB, id string) string {
	client := new(model.Client)
	db.First(client, "id = ?", id)
	return client.Status
}

func RenameDevice(db *gorm.DB, id, name string) error {
	return db.Model(&model.Client{}).Where("id = ?", id).Update("name", name).Error
}

func UnregisterDevice(db *gorm.DB, id string, conn *websocket.Conn) error {
	client := new(model.Client)
	if err := db.First(client, "id = ?", id).Error; err != nil {
		return err
	} else {
		if err := misc.RunAction(id, "unregister", db, conn); err != nil {
			return err
		}
		return db.Delete(&model.Client{}, "id = ?", id).Error
	}
}

func ControlDevice(db *gorm.DB, conn *websocket.Conn, deviceID, action string) error {
	client := new(model.Client)
	if err := db.First(client, "id = ?", deviceID).Error; err == nil {
		return misc.RunAction(deviceID, action, db, conn)
	} else {
		return err
	}
}
