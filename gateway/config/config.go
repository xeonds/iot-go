package config

import "github.com/xeonds/libgc"

type Config struct {
	DB        libgc.DatabaseConfig
	Port      int `json:"port"`
	Heartbeat int `json:"heartbeat"`
}
