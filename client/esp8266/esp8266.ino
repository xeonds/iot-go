#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ESP8266mDNS.h>
#include <PubSubClient.h>
#include <EEPROM.h>

// AP 模式配置
const char *ap_ssid = "ESP8266_Setup";
const char *ap_password = "password";

const int buttonPin = 0;  // GPIO0 接入按键
const int outputPin = 2;  // GPIO2 输出控制电平

// 设备配置
const char *deviceType = "smart_light"; // 设备类别
char deviceId[13];                      // 设备唯一 ID (MAC 地址后 6 位)

ESP8266WebServer server(80);

struct WiFiCredentials
{
  char ssid[32];
  char password[64];
};

WiFiCredentials savedCredentials;

void setup() {
  Serial.begin(115200);
  EEPROM.begin(sizeof(WiFiCredentials));

  pinMode(buttonPin, INPUT_PULLUP);  // 使用内部上拉电阻
  pinMode(outputPin, OUTPUT);        // 配置为输出引脚
  digitalWrite(outputPin, LOW);      // 初始为低电平

  // 生成设备 ID
  String macAddress = WiFi.macAddress();
  macAddress.replace(":", "");
  snprintf(deviceId, sizeof(deviceId), "%s", macAddress.substring(6).c_str());

  // 尝试连接保存的 WiFi
  // 如果连接失败，启动 AP 模式配网
  server.on("/configure", handleConfigure);
  EEPROM.get(0, savedCredentials);
  if (strlen(savedCredentials.ssid) > 0)
  {
    WiFi.begin(savedCredentials.ssid, savedCredentials.password);
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20)
    {
      delay(500);
      Serial.print(".");
      attempts++;
    }
    if (WiFi.status() == WL_CONNECTED)
    {
      Serial.println("\nConnected to saved WiFi");
      Serial.print("IP address: ");
      Serial.println(WiFi.localIP());

      server.on("/status", HTTP_GET, []() {
        server.send(200, "text/plain", String(digitalRead(outputPin)));
      });
      server.on("/control", HTTP_POST, []() {
        int status = server.arg("status").toInt();
        digitalWrite(outputPin, status);
        server.send(200, "text/plain", "OK");
      });
      server.on("/info", HTTP_GET, []() {
        server.send(200, "application/json", "{\"category\":\"" + String(deviceType) + "\",\"id\":\"" + String(deviceId) + "\"}");
      });
      server.on("/reboot", HTTP_POST, []() {
        server.send(200, "text/plain", "Rebooting...");
        delay(1000);
        ESP.restart();
      });
      server.on("/reset", HTTP_POST, []() {
        for (int i = 0; i < sizeof(WiFiCredentials); i++) { EEPROM.write(i, 0); }
        EEPROM.commit();
        server.send(200, "text/plain", "EEPROM reset. Rebooting...");
        delay(1000);
        ESP.restart();
      });
      server.begin();

      if (!MDNS.begin(String(deviceType) + "-" + String(deviceId)))
      {
        Serial.println("Error starting mDNS");
        return;
      }
      MDNS.addService("iot-device", "tcp", 80);
      return;
    }
  }
  server.on("/", handleRoot);
  server.begin();
  setupAP();
}

void loop() {
  server.handleClient();
  MDNS.update();
  // TODO: long press to reset WiFi settings
  // TODO: short click to switch on/off
}

// WiFi init
void setupAP() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP(ap_ssid, ap_password);
  Serial.println("AP mode started");
  Serial.print("IP address: ");
  Serial.println(WiFi.softAPIP());
}
void handleRoot() {
  String html = "<html><body>";
  html += "<h1>ESP8266 WiFi Setup</h1>";
  html += "<form action='/configure' method='post'>";
  html += "SSID: <input type='text' name='ssid'><br>";
  html += "Password: <input type='password' name='password'><br>";
  html += "<input type='submit' value='Configure'>";
  html += "</form></body></html>";
  server.send(200, "text/html", html);
}
void handleConfigure() {
  String newSsid = server.arg("ssid");
  String newPassword = server.arg("password");

  strncpy(savedCredentials.ssid, newSsid.c_str(), sizeof(savedCredentials.ssid));
  strncpy(savedCredentials.password, newPassword.c_str(), sizeof(savedCredentials.password));

  EEPROM.put(0, savedCredentials);
  EEPROM.commit();

  server.send(200, "text/plain", "Configuration saved. Rebooting...");
  delay(1000);
  ESP.restart();
}
