#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ESP8266mDNS.h>
#include <EEPROM.h>
#include <Regexp.h>
#include <ArduinoWebsockets.h>
#include <ESP8266HTTPClient.h>

using namespace websockets;

// AP 模式配置
const char *ap_ssid = "ESP8266_Setup";
const char *ap_password = "password";

const int buttonPin = 0; // GPIO0 接入按键
const int outputPin = 2; // GPIO2 输出控制电平

// 设备配置
const char *deviceType = "smart_light"; // 设备类别
char deviceId[13];                      // 设备唯一 ID (MAC 地址后 6 位)

ESP8266WebServer server(80);

struct WiFiCredentials
{
  char ssid[32];
  char password[64];
};

struct Message
{
  String Type;
  String Key;
  int Limit;
  String Value;
};

WiFiCredentials savedCredentials;

WebsocketsClient webSocket;

void setup()
{
  Serial.begin(115200);
  EEPROM.begin(sizeof(WiFiCredentials));

  pinMode(buttonPin, INPUT_PULLUP); // 使用内部上拉电阻
  pinMode(outputPin, OUTPUT);       // 配置为输出引脚
  analogWrite(outputPin, 0);        // 初始为低电平

  // 生成设备 ID
  String macAddress = WiFi.macAddress();
  macAddress.replace(":", "");
  snprintf(deviceId, sizeof(deviceId), "%s", macAddress.substring(6).c_str());

  // 尝试连接保存的 WiFi
  // 如果连接失败，启动 AP 模式配网
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

      // Start mDNS responder
      if (!MDNS.begin(deviceId))
      {
        Serial.println("Error setting up MDNS responder!");
        return;
      }
      Serial.println("mDNS responder started");

    mdns:
      // Check the EEPROM and try to ping the server
      String savedServerIp;
      String savedServerPort;
      EEPROM.get(sizeof(WiFiCredentials), savedServerIp);
      EEPROM.get(sizeof(WiFiCredentials) + 16, savedServerPort);

      if (savedServerIp.length() > 0 && savedServerPort.length() > 0)
      {
        Serial.print("Trying to connect to saved server: ");
        Serial.print(savedServerIp);
        Serial.print(":");
        Serial.println(savedServerPort);

        int pingAttempts = 0;
        bool serverReachable = false;
        Serial.println("Server found");
        HTTPClient http;
        WiFiClient client;
        http.begin(client, "http://" + savedServerIp + ":" + savedServerPort + "/api/register/" + deviceId);
        int httpCode = http.GET();
        if (httpCode != HTTP_CODE_OK)
        {
          Serial.printf("Failed to connect, error: %s\n", http.errorToString(httpCode).c_str());
          http.end();
          return;
        }
        Serial.println("Device registered successfully");

        webSocket.onMessage(webSocketMessage);
        webSocket.onEvent(webSocketEvent);
        webSocket.connect("ws://" + savedServerIp + ":" + savedServerPort + "/ws/device/" + String(deviceId));
        Serial.println("Server connected");
      }
      Serial.println("Failed to reach server, finding by mDNS");
      delay(2000);
    find_mdns:
      MDNS.queryService("iot-gateway", "tcp", 10000);
      Serial.print(".");
      if (MDNS.port(0)==0)
      {
        delay(500);
        goto find_mdns;
      }
      else
      {
        Serial.println("Server found: " + MDNS.IP(0).toString() + ":" + MDNS.port(0));
        // Save the first found server's info to EEPROM
        String serverIp = MDNS.IP(0).toString();
        String serverPort = String(MDNS.port(0));
        EEPROM.put(sizeof(WiFiCredentials), serverIp);
        EEPROM.put(sizeof(WiFiCredentials) + 16, serverPort);
        EEPROM.commit();
        Serial.println("Server info saved to EEPROM");
        goto mdns;
      }
      return;
    }
  }
  server.on("/configure", handleConfigure);
  server.on("/", handleRoot);
  server.begin();
  setupAP();
}

void loop()
{
  server.handleClient();
  MDNS.update();
  webSocket.poll();
  // TODO: long press to reset WiFi settings
  // TODO: short click to switch on/off
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

void handleRoot()
{
  String html = "<html><body>";
  html += "<h1>ESP8266 WiFi Setup</h1>";
  html += "<form action='/configure' method='post'>";
  html += "SSID: <input type='text' name='ssid'><br>";
  html += "Password: <input type='password' name='password'><br>";
  html += "<input type='submit' value='Configure'>";
  html += "</form></body></html>";
  server.send(200, "text/html", html);
}
void handleConfigure()
{
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

void webSocketMessage(WebsocketsMessage message)
{
  Serial.printf("WebSocket Received Text: %s\n", message.data().c_str());
  String dsl = message.data();
  Message msg;
  if (!ParseDSL(dsl, msg))
  {
    Serial.println("Invalid DSL format");
    return;
  }

  static int pwmValue = 0;

  if (msg.Type == "action")
  {
    if (msg.Value == "on")
    {
      pwmValue = 1023;
      analogWrite(outputPin, pwmValue);
    }
    else if (msg.Value == "off")
    {
      pwmValue = 0;
      analogWrite(outputPin, pwmValue);
    }
    else if (msg.Value == "toggle")
    {
      pwmValue = (pwmValue == 0) ? 1023 : 0;
      analogWrite(outputPin, pwmValue);
    }
    else if (msg.Value == "get_status")
    {
      String status = (pwmValue > 0) ? "on" : "off";
      webSocket.send("data.status:" + status);
    }
    else if (msg.Value == "+")
    {
      pwmValue = min(pwmValue + 64, 1023);
      analogWrite(outputPin, pwmValue);
    }
    else if (msg.Value == "-")
    {
      pwmValue = max(pwmValue - 64, 0);
      analogWrite(outputPin, pwmValue);
    }
    else if (msg.Key == "pwm")
    {
      pwmValue = msg.Value.toInt();
      analogWrite(outputPin, constrain(pwmValue, 0, 1023));
    }
    else if (msg.Value == "reset")
    {
      for (int i = 0; i < sizeof(WiFiCredentials) + 16 + 16; i++)
      {
        EEPROM.write(i, 0);
      }
      EEPROM.commit();
      ESP.restart();
    }
  }
}

void webSocketEvent(WebsocketsEvent event, String data)
{
  if (event == WebsocketsEvent::ConnectionOpened)
  {
    Serial.println("WebSocket Connected");
  }
  else if (event == WebsocketsEvent::ConnectionClosed)
  {
    Serial.println("WebSocket Disconnected");
  }
  else if (event == WebsocketsEvent::GotPing)
  {
    Serial.println("WebSocket Got a Ping!");
  }
  else if (event == WebsocketsEvent::GotPong)
  {
    Serial.println("WebSocket Got a Pong!");
  }
}

bool ParseDSL(String &dsl, Message &message)
{
  MatchState ms;
  ms.Target((char *)dsl.c_str());

  // Regular expression pattern
  const char *pattern = "^([%w_]+)(?:%.([%w_]+))?(?:%[(%d+)%])?(?::(.+))?$";
  char result = ms.Match(pattern);

  if (result == REGEXP_NOMATCH)
  {
    Serial.println("Invalid DSL format");
    return false;
  }

  // Extract matches
  char buf[50];
  ms.GetCapture(buf, 0);
  message.Type = String(buf);

  ms.GetCapture(buf, 1);
  message.Key = String(buf);

  ms.GetCapture(buf, 2);
  message.Limit = atoi(buf);

  ms.GetCapture(buf, 3);
  message.Value = String(buf);

  return true;
}