package main

import (
	"fmt"
	"log"
	"math/rand/v2"
	"net/url"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/xeonds/libgc"
)

type Config struct {
	ServerIP string `json:"server_ip"`
	DeviceID string `json:"device_id"`
}

func getSensor() string {
	temp := 20 + rand.Float64()*10
	return fmt.Sprintf("status.temperature:%.2f", temp)
}

func main() {
	config := libgc.LoadConfig[Config]()
	u := url.URL{Scheme: "ws", Host: config.ServerIP, Path: "/ws/device/" + config.DeviceID}
	var wg sync.WaitGroup

	recv := make(chan string)
	send := make(chan string)
	// handler
	realTimeMode := false
	go func() {
		for msg := range recv {
			switch msg {
			case "action:real_time_mode_on":
				log.Println("turning on")
				realTimeMode = true
			case "action:real_time_mode_off":
				log.Println("turning off")
				realTimeMode = false
			case "action:get_temperature":
				send <- getSensor()
			default:
				log.Println("unknown action")
			}
		}
	}()
	// sender
	go func() {
		ticker := time.NewTicker(time.Second * 1)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				if realTimeMode {
					send <- getSensor()
				}
			}
		}
	}()
	for {
		log.Printf("connecting to %s", u.String())

		c, _, err := websocket.DefaultDialer.Dial(u.String(), nil)
		if err != nil {
			log.Println("dial:", err)
			time.Sleep(time.Second * 5) // Wait before retrying
			continue
		}
		log.Println("connected")
		defer c.Close()

		// recv messages from conn
		go func() {
			wg.Add(1)
			for {
				_, message, err := c.ReadMessage()
				if err != nil {
					log.Println("read:", err)
					wg.Done()
					return
				}
				recv <- string(message)
			}
		}()
		// send messages to conn in chan
		go func() {
			wg.Add(1)
			for {
				select {
				case message := <-send:
					err := c.WriteMessage(websocket.TextMessage, []byte(message))
					if err != nil {
						log.Println("write:", err)
						wg.Done()
						return
					}
					log.Println("sent:", message)
				}
			}
		}()

		wg.Wait()
		log.Println("connection closed, retrying in 3 seconds")
		time.Sleep(time.Second * 3)
	}
}
