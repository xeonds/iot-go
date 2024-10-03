#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>

// 定义服务和特征的UUID
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// 全局变量
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// 当BLE设备连接或断开时调用的回调函数
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

// 当特征值被写入时调用的回调函数
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();

      if (value.length() > 0) {
        // 假设value的格式是SSID:Password
        std::string ssid = value.substr(0, value.find(':'));
        std::string password = value.substr(value.find(':') + 1);

        // 在这里连接Wi-Fi
        // 你需要添加你的Wi-Fi连接代码
        Serial.println("Received Wi-Fi credentials:");
        Serial.println("SSID: " + ssid);
        Serial.println("Password: " + password);
        
        // 连接Wi-Fi的代码（示例）
        // WiFi.begin(ssid.c_str(), password.c_str());
      }
    }
};

void setup() {
  Serial.begin(115200);

  // 创建BLE设备
  BLEDevice::init("ESP32_BLE_WiFi");

  // 创建BLE服务器
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // 创建BLE服务
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // 创建BLE特征
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_WRITE
                    );

  pCharacteristic->setCallbacks(new MyCallbacks());

  // 启动服务
  pService->start();

  // 启动广播
  pServer->getAdvertising()->start();
  Serial.println("Waiting a client connection to notify...");
}

void loop() {
  // 检测设备连接状态
  if (deviceConnected && !oldDeviceConnected) {
    // 设备连接时
    Serial.println("Device connected");
  }

  if (!deviceConnected && oldDeviceConnected) {
    // 设备断开连接时
    Serial.println("Device disconnected");
    BLEDevice::startAdvertising(); // 重新开始广播
  }

  oldDeviceConnected = deviceConnected;

  // 这里可以添加其他任务
}
