package model

import "github.com/gorilla/websocket"

type Client struct {
	ID     string `gorm:"primarykey" json:"id"`
	Name   string `json:"name"`
	Addr   string `json:"addr"`
	Status string `json:"status"`
}

type Rule struct {
	DeviceID  string `json:"device_id"`
	Condition string `json:"condition"`
	Action    string `json:"action"`
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
