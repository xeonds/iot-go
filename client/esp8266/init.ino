#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ESP8266mDNS.h>
#include <PubSubClient.h>
#include <EEPROM.h>

// AP 模式配置
const char* ap_ssid = "ESP8266_Setup";
const char* ap_password = "password";

// 设备配置
const char* deviceCategory = "smart_light";  // 设备类别
char deviceId[13];  // 设备唯一 ID (MAC 地址后 6 位)

// IoT 服务器配置
const char* iotServerService = "iot_server";  // mDNS 服务名
char mqttServer[64];
int mqttPort = 1883;
char mqttTopic[64];

ESP8266WebServer server(80);
WiFiClient espClient;
PubSubClient client(espClient);

struct WiFiCredentials {
  char ssid[32];
  char password[64];
};

WiFiCredentials savedCredentials;

void setup() {
  Serial.begin(115200);
  EEPROM.begin(sizeof(WiFiCredentials));

  String macAddress = WiFi.macAddress();
  macAddress.replace(":", "");
  snprintf(deviceId, sizeof(deviceId), "%s", macAddress.substring(6).c_str());
  EEPROM.get(0, savedCredentials);

  if (strlen(savedCredentials.ssid) > 0) {
    WiFi.begin(savedCredentials.ssid, savedCredentials.password);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
      delay(500);
      Serial.print(".");
      attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\nConnected to saved WiFi");
      setupMDNSAndMQTT();
      return;
    }
  }

  setupAP();
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    client.loop();
    MDNS.update();
  } else {
    server.handleClient();
  }
}

void setupAP() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP(ap_ssid, ap_password);
  server.on("/", handleRoot);
  server.on("/configure", handleConfigure);
  server.begin();
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

// 发现IoT服务器，并设置和启动MQTT
void setupMDNSAndMQTT() {
  if (!MDNS.begin(deviceId)) {
    Serial.println("Error setting up mDNS!");
    return;
  }

  Serial.println("mDNS responder started");

  // 查找 IoT 服务器
  int n = MDNS.queryService(iotServerService, "tcp");
  if (n == 0) {
    Serial.println("No IoT servers found");
    return;
  }

  // 使用第一个找到的服务器
  strncpy(mqttServer, MDNS.IP(0).toString().c_str(), sizeof(mqttServer));
  mqttPort = MDNS.port(0);

  Serial.print("IoT server found: ");
  Serial.print(mqttServer);
  Serial.print(":");
  Serial.println(mqttPort);

  // 设置 MQTT 主题
  snprintf(mqttTopic, sizeof(mqttTopic), "%s/%s", deviceCategory, deviceId);

  client.setServer(mqttServer, mqttPort);
  client.setCallback(callback);
  
  while (!client.connected()) {
    Serial.println("Connecting to MQTT...");
    if (client.connect(deviceId)) {
      Serial.println("Connected to MQTT");
      client.subscribe(mqttTopic);
    } else {
      Serial.print("Failed, rc=");
      Serial.print(client.state());
      Serial.println(" Retrying in 5 seconds");
      delay(5000);
    }
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();
}