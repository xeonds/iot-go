package model

import (
	"time"

	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

type Client struct {
	ID     string `gorm:"primarykey" json:"id"`
	Name   string `json:"name"`
	Addr   string `json:"addr"`
	Status string `json:"status"`
	Cmds   string `json:"cmds"`
}

type Rule struct {
	gorm.Model
	Tasks      *[]Tasks     `gorm:"serializer:json" json:"tasks"`
	IsManual   bool         `json:"is_manual"`
	DateTime   *time.Time   `json:"date_time"`
	Repeat     string       `json:"repeat"`
	Conditions *[]Condition `gorm:"serializer:json" json:"conditions"`
	IsEnabled  bool         `json:"is_enabled"`
}
type Condition struct {
	Item       string `json:"item"`
	Comparator string `json:"comparator"`
	Value      string `json:"value"`
}
type Tasks struct {
	Commands []string `gorm:"serializer:json" json:"commands"`
	DeviceID string   `json:"device_id"`
}

type Data struct {
	ID       uint     `gorm:"primarykey" json:"id"`
	DeviceID string   `gorm:"index" json:"device_id"`
	Key      string   `gorm:"uniqueIndex" json:"key"`
	Value    []string `gorm:"serializer:json" json:"value"`
}

type DeviceAPIMessage struct {
	Conn     *websocket.Conn
	DeviceID string
	Message  []byte
}
