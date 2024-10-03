package model

type Client struct {
	ID        string `gorm:"primarykey" json:"id"`
	Name      string `gorm:"unique;not null" json:"name"`
	Addr      string `gorm:"unique;not null" json:"addr"`
	Heartbeat int    `gorm:"not null" json:"heartbeat"`
	Status    string `gorm:"not null" json:"status"`
}

type Rule struct {
	DeviceID  string `json:"device_id"`
	Condition string `json:"condition"`
	Action    string `json:"action"`
}
