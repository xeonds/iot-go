package test

import (
	"log"
	"testing"

	"github.com/grandcat/zeroconf"
)

func TestMain(m *testing.M) {
	// 发布mDNS服务
	server, err := zeroconf.Register(
		"iot-gateway",           // 服务名称
		"_iot._tcp",             // 服务类型
		"local.",                // 域
		1883,                    // 端口
		[]string{"iot gateway"}, // 服务文本信息
		nil,                     // 网络接口
	)
	if err != nil {
		log.Fatalf("Failed to register mDNS service: %v", err)
	}
	defer server.Shutdown()
	log.Println("mDNS service started for IoT gateway on _iot._tcp...")
}
