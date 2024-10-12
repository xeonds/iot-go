package misc

import (
	"gateway/config"
	"log"

	"github.com/grandcat/zeroconf"
)

func RunmDnsBroadcast(config *config.Config) {
	serviceName := "_iot-gateway._tcp"
	serviceDomain := "local."
	servicePort := config.Port
	instanceName := "iot-gateway-instance"

	server, err := zeroconf.Register(instanceName, serviceName, serviceDomain, servicePort, []string{"gateway"}, nil)
	if err != nil {
		log.Fatalf("Failed to register mDNS service: %v", err)
	}
	defer server.Shutdown()
	log.Printf("mDNS service %s.%s:%d published", instanceName, serviceName, servicePort)
	select {}
}
