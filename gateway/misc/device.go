package misc

import mqtt "github.com/eclipse/paho.mqtt.golang"

func ActionExec(deviceID, action string, client mqtt.Client) error {
	token := client.Publish("home/"+deviceID+"/control", 0, false, action)
	token.Wait()
	return nil
}
