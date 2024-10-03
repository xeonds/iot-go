package main

import (
	"context"
	"gateway/config"
	"gateway/misc"
	"gateway/model"
	"log"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/gin-gonic/gin"
	"github.com/grandcat/zeroconf"
	"github.com/robfig/cron/v3"
	"github.com/xeonds/libgc"
	"gorm.io/gorm"
)

func main() {
	config := libgc.LoadConfig[config.Config]()
	db := libgc.NewDB(&config.DB, func(db *gorm.DB) error {
		return db.AutoMigrate(&model.Client{})
	})
	mqtt := initMQTT()

	go discoverDevices(db)

	router := gin.Default()
	router.POST("/register/:id", registerDevice(db))
	router.POST("/control/:id/:action", controlDevice(db, mqtt))
	router.GET("/devices", getDevices(db))

	crontab := cron.New(cron.WithSeconds())
	if _, err := crontab.AddFunc("0 15 * * * *", func() {
		rules := new(misc.Rules)
		db.Find(rules)
		for _, rule := range rules.Match(time.Now().String()) {
			misc.ActionExec(rule.DeviceID, rule.Action, mqtt)
		}
	}); err != nil {
		log.Fatal("Failed to start feed update daemon")
	}
	crontab.Start()

	log.Fatal(router.Run(config.Port))
}

func discoverDevices(db *gorm.DB) {
	resolver, err := zeroconf.NewResolver(nil)
	if err != nil {
		log.Fatalln("Failed to initialize resolver:", err.Error())
	}

	entries := make(chan *zeroconf.ServiceEntry, 4)
	go func(results <-chan *zeroconf.ServiceEntry) {
		for entry := range results {
			log.Printf("Found device: %v at %v:%v\n", entry.Instance, entry.AddrIPv4, entry.Port)
			var client model.Client
			db.First(&client, "id = ?", entry.Instance)
			if client.ID == "" {
				client.ID = entry.Instance
				client.Name = "Unknown"
				client.Addr = entry.AddrIPv4[0].String()
				db.Create(&client)
			}
		}
	}(entries)
	ctx := context.Background()
	err = resolver.Browse(ctx, "_http._tcp", "local.", entries)
	if err != nil {
		log.Fatalln("Failed to browse:", err.Error())
	}
	<-ctx.Done()
}

func registerDevice(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		name := c.PostForm("name")
		addr := c.ClientIP()
		client := model.Client{ID: id, Name: name, Addr: addr}
		db.Create(&client)
		c.JSON(200, gin.H{"status": "ok"})
	}
}

func getDevices(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		clients := new([]model.Client)
		db.Find(clients)
		c.JSON(200, clients)
	}
}

func controlDevice(db *gorm.DB, mqtt mqtt.Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		action := c.Param("action")
		var client model.Client
		db.First(&client, "id = ?", id)
		misc.ActionExec(client.ID, action, mqtt)
		c.JSON(200, gin.H{"status": "ok"})
	}
}

func initMQTT() mqtt.Client {
	opts := mqtt.NewClientOptions().AddBroker("tcp://localhost:1883")
	opts.SetClientID("gateway")
	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatal(token.Error())
	}
	return client
}
