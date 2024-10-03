#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>

void setup() {
  // 初始化串口和WiFi连接（略）
  
  // 启动mDNS服务
  if (!MDNS.begin("esp8266")) {
    Serial.println("Error setting up MDNS responder!");
    while(1) {
      delay(1000);
    }
  }
  Serial.println("mDNS responder started");

  // 添加服务
  MDNS.addService("http", "tcp", 80);
}

void loop() {
  // mDNS处理
  MDNS.update();
}
