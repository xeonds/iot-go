package main

import (
	"fmt"
	"log"
	"net/http"
	"net/url"
	"time"

	"github.com/gorilla/websocket"
	"github.com/hashicorp/mdns"
	"github.com/xeonds/libgc"
)

type Config struct {
	ServerIP   string `json:"server_ip"`
	DeviceID   string `json:"device_id"`
	Registered bool   `json:"registered"`
}

var status int

var actions = []string{
	"action:open",
	"action:close",
	"action:+",
	"action:-",
	"action:get_status",
}

func getStatus() string {
	return fmt.Sprintf("data.luminous:%d", status)
}

func main() {
	// Discover server by _iot-gateway._tcp using mDNS
	config := libgc.LoadConfig[Config]()

	entriesCh := make(chan *mdns.ServiceEntry, 4)
	mdns.Lookup("_iot-gateway._tcp", entriesCh)
	var serverIP, serverPort string
	select {
	case entry := <-entriesCh:
		serverIP = entry.AddrV4.String()
		serverPort = fmt.Sprintf("%d", entry.Port)
	case <-time.After(5 * time.Second):
		log.Fatal("mDNS lookup timed out")
	}
	log.Println("server found:", serverIP, serverPort)
	u := url.URL{Scheme: "ws", Host: fmt.Sprintf("%s:%s", serverIP, serverPort), Path: "/ws/device/" + config.DeviceID}

	var c *websocket.Conn
	recv := make(chan string)
	send := make(chan string)

	log.Println("registering")
	form := url.Values{}
	for _, action := range actions {
		form.Add("actions", action)
	}
	resp, err := http.PostForm("http://"+serverIP+":"+serverPort+"/api/register/"+config.DeviceID, form)
	if err != nil {
		log.Fatal(err)
	}
	if resp.StatusCode != 200 {
		log.Print("failed to register: already registered")
	}
	// libgc.SaveConfig(config)
	status = 0

	// handler
	go func() {
		for msg := range recv {
			switch msg {
			case "action:open":
				log.Println("turning on")
				status = 256
			case "action:get_status":
				send <- getStatus()
			case "action:close":
				status = 0
				send <- getStatus()
			case "action:+":
				if status < 256 {
					status += 32
				}
				send <- getStatus()
			case "action:-":
				if status > 0 {
					status -= 32
				}
				send <- getStatus()
			default:
				log.Println("unknown message:", msg)
			}
		}
	}()

	// connection guard
	go func() {
		for range time.Tick(time.Second * 2) {
			log.Printf("connecting to %s", u.String())
			var err error
			c, _, err = websocket.DefaultDialer.Dial(u.String(), nil)
			if err != nil {
				log.Println("dial:", err)
				continue
			}
			log.Println("connected")
			startListenAndSend(send, recv, c)
			log.Println("disconnected, reconnecting in 2 seconds")
		}
	}()

	// recv messages from conn
	select {}
}

func startListenAndSend(send, recv chan string, c *websocket.Conn) {
	go func() {
		for {
			if _, message, err := c.ReadMessage(); err != nil {
				log.Println("read:", err)
				return
			} else {
				recv <- string(message)
			}
		}
	}()
	// send messages to conn in chan
	go func() {
		for message := range send {
			if err := c.WriteMessage(websocket.TextMessage, []byte(message)); err != nil {
				log.Println("write:", err)
				return
			}
			log.Println("sent:", message)
		}
	}()
	select {}
}
