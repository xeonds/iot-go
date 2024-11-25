#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
//#include <ESP8266mDNS.h>
#include <EEPROM.h>
#include <regex>
#include <ArduinoWebsockets.h>
#include <ESP8266HTTPClient.h>

using namespace websockets;

// AP 模式配置
const char *ap_ssid = "ESP8266_Setup";
const char *ap_password = "password";

// gpio configuration
const int buttonPin = 0; // GPIO0 接入按键
const int outputPin = 2; // GPIO2 输出控制电平

// button input configuration
bool buttonState = HIGH;
bool lastState = HIGH;
unsigned long pressTime = 0;
unsigned long releaseTime = 0;
bool isLongPress = false;

// store pwm value
static int pwmValue = 0;

// device configuration
const char *deviceType = "smart_light"; // 设备类别
char deviceId[13];                      // 设备唯一 ID (MAC 地址后 6 位)

ESP8266WebServer server(80);

struct Config
{
  char ssid[32];
  char password[64];
  char serverIp[16];
  char serverPort[6];
};

struct Message
{
  String Type;
  String Key;
  int Limit;
  String Value;
};

Config config;

WebsocketsClient webSocket;

void setup() {
  Serial.begin(115200);
  EEPROM.begin(sizeof(Config));

  pinMode(buttonPin, INPUT_PULLUP); // 使用内部上拉电阻
  pinMode(outputPin, OUTPUT);       // 配置为输出引脚
  analogWrite(outputPin, 0);        // 初始为低电平

  // setup websocket event handler
  webSocket.onMessage(webSocketMessage);
  webSocket.onEvent(webSocketEvent);

  server.on("/reset", handleReset);

  // 生成设备 ID
  String macAddress = WiFi.macAddress();
  macAddress.replace(":", "");
  snprintf(deviceId, sizeof(deviceId), "%s", macAddress.substring(6).c_str());

  unsigned long reconnectInterval = 1000; // initial reconnect attempt interval
  unsigned int retryCount=0;
  // try to connect to saved WiFi
  // if no wifi saved in config, start ap mode for config
  EEPROM.get(0, config);
  if (strlen(config.ssid) > 0) {
    WiFi.begin(config.ssid, config.password);
    // reconnect forever until connected to network
reconnect:
    retryCount++;
    //reconnectInterval = min(reconnectInterval * 2, 60000);
    delay(reconnectInterval);
    Serial.print(".");
    if (WiFi.status() == WL_CONNECTED ) {
      Serial.println("\nConnected to saved WiFi");
      Serial.print("IP address: ");
      Serial.println(WiFi.localIP());
      Serial.println("Trying to reach server");
      Serial.println(String(config.serverIp));
      Serial.println(String(config.serverPort));
      if (strlen(config.serverIp) > 0 && strlen(config.serverPort) > 0) {
        Serial.print("Trying to connect to saved server: ");
        Serial.print(config.serverIp); Serial.print(":"); Serial.println(config.serverPort);
        HTTPClient http;
        WiFiClient client;
        http.begin(client, "http://" + String(config.serverIp) + ":" + String(config.serverPort) + "/api/register/" + deviceId);
        http.addHeader("Content-Type", "application/json");
        String payload = "{\"deviceId\":\"" + String(deviceId) + "\", \"deviceType\":\"" + String(deviceType) + "\", \"cmds\":\"action:on->null;action:off->null;action:toggle->null;action:get_status->data.status:int;action:+->null;action:-->null;action.pwm:int->null;action:reset->null;\"}";
        int httpCode = http.POST(payload);
        if (httpCode != HTTP_CODE_OK) {
          Serial.printf("Failed to connect, error: %s\n", http.errorToString(httpCode).c_str());
          http.end();
        } else {
          Serial.println("Device registered successfully");
          webSocket.connect("ws://" + String(config.serverIp) + ":" + String(config.serverPort) + "/ws/device/" + String(deviceId));
          Serial.println("Server connected");
        }
      } else { goto config; }
    } else if (retryCount < 16) { goto reconnect; }
  } else {
config:
    server.on("/configure", handleConfigure);
    server.on("/", handleRoot);
    setupAP();
  }

  server.begin();
  return;
}

void loop() {
  buttonState = digitalRead(buttonPin);
  if (buttonState == LOW && lastState == HIGH) {
    pressTime = millis();
    isLongPress = false;
  } 
  if (buttonState = LOW) {
    if (!isLongPress && millis() - pressTime >= 5000) { // press longer than 5s
      handleReset();
      isLongPress=true;
    }
  }
  if (buttonState==HIGH && lastState==LOW) {
    releaseTime = millis();
    if (!isLongPress && releaseTime - pressTime < 5000) {
      pwmValue = (pwmValue%256+256)%256;
      pwmValue = pwmValue - (pwmValue%16);
      pwmValue = (pwmValue+16)%256;
      analogWrite(outputPin, pwmValue);
      if (webSocket.available()) {
        webSocket.send("data.status:" + String(pwmValue));
      }
    }
  }
  lastState = buttonState;

  server.handleClient();
  // websocket autoreconnect
  if (webSocket.available()) {
    webSocket.poll();
  } else if (strlen(config.serverIp)>0 && strlen(config.serverPort)>0) {
    // reconnect attempt in every loop
    Serial.println("Attempting to reconnect to WebSocket server...");
    if (webSocket.connect("ws://" + String(config.serverIp) + ":" + String(config.serverPort) + "/ws/device/" + String(deviceId))) {
      Serial.println("reconnect success");
    }
  }

  delay(10);
}

// WiFi init
void setupAP()
{
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
  html += "ServerIP: <input type='text' name='ip'><br>";
  html += "ServerPort: <input type='text' name='port'><br>";
  html += "<input type='submit' value='Configure'>";
  html += "</form></body></html>";
  server.send(200, "text/html", html);
}
void handleConfigure() {
  String newSsid = server.arg("ssid");
  String newPassword = server.arg("password");
  String newServerIp = server.arg("ip");
  String newServerPort = server.arg("port");

  strncpy(config.ssid, newSsid.c_str(), sizeof(config.ssid));
  strncpy(config.password, newPassword.c_str(), sizeof(config.password));
  strncpy(config.serverIp, newServerIp.c_str(), sizeof(config.serverIp));
  strncpy(config.serverPort, newServerPort.c_str(), sizeof(config.serverPort));

  EEPROM.put(0, config);
  EEPROM.commit();

  server.send(200, "text/plain", "Configuration saved. Rebooting...");
  delay(1000);
  ESP.restart();
}
void handleReset() {
  for (int i = 0; i < sizeof(Config) + 16 + 16; i++) {
    EEPROM.write(i, 0);
  }
  EEPROM.commit();
  server.send(200, "text/plain", "Device reset success. Rebooting...");
  delay(1000);
  ESP.restart();
}

void webSocketMessage(WebsocketsMessage message) {
  Serial.printf("WebSocket Received Text: %s\n", message.data().c_str());
  String dsl = message.data();
  Message msg;
  if (!ParseDSL(dsl, msg)) {
    Serial.println("Invalid DSL format");
    return;
  }

  if (msg.Type == "info") {
    if (msg.Value == "cmds") {
      webSocket.send("data.cmds: \"action:on->null;action:off->null;action:toggle->null;action:get_status->data.status:int;action:+->null;action:-->null;action.pwm:int->null;action:reset->null\"");
    }
  }
  if (msg.Type == "action") {
    if (msg.Value == "on") {
      pwmValue = 255;
      analogWrite(outputPin, pwmValue);
      webSocket.send("data.status:" + String(pwmValue));
    } else if (msg.Value == "off") {
      pwmValue = 0;
      analogWrite(outputPin, pwmValue);
      webSocket.send("data.status:" + String(pwmValue));
    } else if (msg.Value == "toggle") {
      pwmValue = (pwmValue == 0) ? 255 : 0;
      analogWrite(outputPin, pwmValue);
      webSocket.send("data.status:" + String(pwmValue));
    } else if (msg.Value == "get_status") {
      webSocket.send("data.status:" + String(pwmValue));
    } else if (msg.Value == "+") {
      pwmValue = min(pwmValue + 16, 255);
      analogWrite(outputPin, pwmValue);
      webSocket.send("data.status:" + String(pwmValue));
    } else if (msg.Value == "-") {
      pwmValue = max(pwmValue - 16, 0);
      analogWrite(outputPin, pwmValue);
      webSocket.send("data.status:" + String(pwmValue));
    } else if (msg.Key == "pwm") {
      pwmValue = msg.Value.toInt();
      analogWrite(outputPin, constrain(pwmValue, 0, 255));
      webSocket.send("data.status:" + String(pwmValue));
    } else if (msg.Value == "reset") {
      for (int i = 0; i < sizeof(Config) + 16 + 16; i++) {
        EEPROM.write(i, 0);
      }
      EEPROM.commit();
      ESP.restart();
    }
  }
}

void webSocketEvent(WebsocketsEvent event, String data)
{
  if (event == WebsocketsEvent::ConnectionOpened) {
    Serial.println("WebSocket Connected");
  } else if (event == WebsocketsEvent::ConnectionClosed) {
    Serial.println("WebSocket Disconnected");
  } else if (event == WebsocketsEvent::GotPing) {
    Serial.println("WebSocket Got a Ping!");
  } else if (event == WebsocketsEvent::GotPong) {
    Serial.println("WebSocket Got a Pong!");
  }
}

bool ParseDSL(String &dsl, Message &message) {
  std::regex pattern(R"(^(\w+)(?:\.(\w+))?(?:\[(\d+)\])?(?::(.+))?$)");
  std::smatch matches;

  std::string dslStr = dsl.c_str();

  if (!std::regex_match(dslStr, matches, pattern)) {
    Serial.println("Invalid DSL format");
    return false;
  }

  message.Type = matches[1].str().c_str();

  if (matches[2].matched) {
    message.Key = matches[2].str().c_str();
  } else {
    message.Key = "";
  }

  if (matches[3].matched) {
    message.Limit = std::stoi(matches[3].str());
  } else {
    message.Limit = 0;
  }

  if (matches[4].matched) {
    message.Value = matches[4].str().c_str();
  } else {
    message.Value = "";
  }

  return true;
}
