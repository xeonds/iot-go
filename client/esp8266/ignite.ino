#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#include <WiFiUdp.h>
#include <PubSubClient.h>
#include <Button2.h>

// 定义配置模式的WiFi热点名称和密码
const char* ssid = "devName";
const char* password = "00000000";

// MQTT服务器地址和端口
const char* mqttServer = "192.168.1.100"; // 网关的IP地址
const int mqttPort = 1883;
const char* mqttTopic = "home/esp8266/light";

WiFiClient espClient;
PubSubClient client(espClient);
Button2 button(0); // GPIO0

int brightness = 0; // 亮度等级
bool lightState = false; // 灯的状态
unsigned long lastDebounceTime = 0; // 防抖动时间
const unsigned long debounceDelay = 50; // 防抖动延迟

void setup() {
  pinMode(LED_BUILTIN, OUTPUT); // 设置内置LED为输出
  Serial.begin(115200);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");

  client.setServer(mqttServer, mqttPort);
  client.setCallback(callback);

  button.setLongClickHandler(longPress);
  button.setClickHandler(singleClick);
}

void loop() {
  ArduinoOTA.handle();
  button.loop();
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
}

void singleClick() {
  if (millis() - lastDebounceTime > debounceDelay) {
    lastDebounceTime = millis();
    brightness = (brightness + 1) % 4; // 4个亮度等级
    updateLight();
  }
}

void longPress() {
  // 在这里添加蓝牙配网代码
}

void updateLight() {
  switch (brightness) {
    case 0:
      analogWrite(LED_BUILTIN, 0); // 关闭
      lightState = false;
      break;
    case 1:
      analogWrite(LED_BUILTIN, 51); // 1/8亮度
      lightState = true;
      break;
    case 2:
      analogWrite(LED_BUILTIN, 102); // 1/4亮度
      lightState = true;
      break;
    case 3:
      analogWrite(LED_BUILTIN, 153); // 3/8亮度
      lightState = true;
      break;
    case 4:
      analogWrite(LED_BUILTIN, 204); // 1/2亮度
      lightState = true;
      break;
    case 5:
      analogWrite(LED_BUILTIN, 255); // 最亮
      lightState = true;
      break;
  }
  client.publish(mqttTopic, lightState ? "ON" : "OFF");
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  if (message == "ON") {
    brightness = 5;
    updateLight();
  } else if (message == "OFF") {
    brightness = 0;
    updateLight();
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP8266Client")) {
      Serial.println("connected");
      client.subscribe(mqttTopic);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}
