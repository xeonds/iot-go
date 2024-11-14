package misc

import (
	"errors"
	"gateway/config"
	"log"
	"sync"

	"github.com/gorilla/websocket"
	"github.com/hashicorp/mdns"
)

func RunmDnsBroadcast(config *config.Config) {
	serviceName := "_iot-gateway._tcp"
	servicePort := config.Port
	instanceName := "iot-gateway-instance"

	info := []string{"gateway"}
	service, err := mdns.NewMDNSService(instanceName, serviceName, "", "", servicePort, nil, info)
	if err != nil {
		log.Fatalf("Failed to create mDNS service: %v", err)
	}

	server, err := mdns.NewServer(&mdns.Config{Zone: service})
	if err != nil {
		log.Fatalf("Failed to start mDNS server: %v", err)
	}
	defer server.Shutdown()
	log.Printf("mDNS service %s.%s:%d published", instanceName, serviceName, servicePort)
	select {}
}

// change to receive gateway api messages
func ForwardTaskToSubGateways(deviceID string, action string, conns map[string]*websocket.Conn) (map[string]string, error) {
	type SubGatewayResponse struct {
		GatewayID string
		Result    string
		Error     error
	}
	var wg sync.WaitGroup
	resultChannel := make(chan SubGatewayResponse, len(conns))
	for _, conn := range conns {
		wg.Add(1)
		go func(conn *websocket.Conn) {
			defer wg.Done()
			var result string
			if err := conn.WriteJSON(map[string]string{"device_id": deviceID, "action": action}); err != nil {
				resultChannel <- SubGatewayResponse{GatewayID: conn.RemoteAddr().String(), Error: err}
				return
			}
			if err := conn.ReadJSON(&result); err != nil {
				resultChannel <- SubGatewayResponse{GatewayID: conn.RemoteAddr().String(), Error: err}
				return
			}
			resultChannel <- SubGatewayResponse{GatewayID: conn.RemoteAddr().String(), Result: result}
		}(conn)
	}
	go func() {
		wg.Wait()
		close(resultChannel)
	}()
	finalResults := make(map[string]string)
	for res := range resultChannel {
		if res.Error != nil {
			log.Printf("子网关 %s 执行任务失败: %v", res.GatewayID, res.Error)
		} else {
			finalResults[res.GatewayID] = res.Result
		}
	}
	if len(finalResults) == 0 {
		return nil, errors.New("所有子网关任务执行失败")
	}
	return finalResults, nil
}
