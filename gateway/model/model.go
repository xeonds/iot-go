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

type GatewayAPIMessage struct {
	Type       string
	DeviceID   string
	DeviceName string
	Action     string
}

type DeviceAPIMessage struct {
	Conn    *websocket.Conn
	Message []byte
}
