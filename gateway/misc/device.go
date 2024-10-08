package misc

import (
	"context"
	"fmt"
	"gateway/model"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/grandcat/zeroconf"
	"gorm.io/gorm"
)

func ActionExec(deviceID, action string, db *gorm.DB) error {
	client := new(model.Client)
	db.First(client, "id = ?", deviceID)
	if client.ID == "" {
		return fmt.Errorf("device %s not found", deviceID)
	}
	url := fmt.Sprintf("http://%s/control", client.Addr)
	payload := "status=" + action

	resp, err := http.Post(url, "application/x-www-form-urlencoded", strings.NewReader(payload))
	if err != nil {
		// 认为设备离线
		db.Model(client).Update("status", "-1")
		return fmt.Errorf("failed to execute HTTP request: %w", err)
	}
	defer resp.Body.Close()
	db.Model(client).Update("status", action)
	return nil
}

// 定期扫描设备并加入数据库
// @param duration 扫描间隔(s)
// @param db 数据库连接
func ScanDevices(duration int, db *gorm.DB) {
	resolver, err := zeroconf.NewResolver(nil)
	if err != nil {
		log.Fatalf("Failed to initialize mDNS resolver: %v", err)
	}
	entries := make(chan *zeroconf.ServiceEntry)

	go func(results <-chan *zeroconf.ServiceEntry) {
		for entry := range results {
			// if item id (entry.Instance as id in database) not exists, add it to database
			var count int64
			db.Find(&model.Client{ID: entry.Instance}).Count(&count)
			if count == 0 {
				db.Create(&model.Client{ID: entry.Instance, Addr: entry.AddrIPv4[0].String()})
				log.Printf("Device %s added to database\n", entry.Instance)
			} else {
				// if item's ip address changed, update it
				client := new(model.Client)
				db.First(&client, "id = ?", entry.Instance)
				if client.Addr != entry.AddrIPv4[0].String() {
					db.Model(&client).Update("addr", entry.AddrIPv4[0].String())
					log.Printf("Device %s 's ip updated from %s to %s\n", entry.Instance, client.Addr, entry.AddrIPv4[0].String())
				}
			}
		}
	}(entries)

	ctx := context.Background()

	for {
		err = resolver.Browse(ctx, "_iot-device._tcp", "local.", entries)
		if err != nil {
			log.Printf("Failed to browse mDNS: %v", err)
		}
		time.Sleep(time.Duration(duration) * time.Second)
	}
}

// 定期获取所有设备状态并更新数据库
// @param duration 扫描间隔(s)
// @param db 数据库连接
func UpdateDeviceStatus(duration int, db *gorm.DB) {
	for range time.Tick(time.Duration(duration) * time.Second) {
		var clients []model.Client
		db.Find(&clients)
		for _, client := range clients {
			url := fmt.Sprintf("http://%s/status", client.Addr)
			resp, err := http.Get(url)
			if err != nil {
				log.Printf("Failed to get status for device %s: %v", client.ID, err)
				db.Model(&client).Update("status", "-1")
				log.Printf("Device %s status updated to -1 (offline)\n", client.ID)
				continue
			}
			defer resp.Body.Close()

			body, err := io.ReadAll(resp.Body)
			if err != nil {
				log.Printf("Failed to read status for device %s: %v", client.ID, err)
				db.Model(&client).Update("status", "-1")
				log.Printf("Device %s status updated to -1 (offline)\n", client.ID)
				continue
			}
			status := string(body)

			if status != client.Status {
				db.Model(&client).Update("status", status)
				log.Printf("Device %s status updated to %s\n", client.ID, status)
			}
		}
	}
}
