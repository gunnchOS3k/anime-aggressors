#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Service and characteristic UUIDs (placeholders)
#define SERVICE_UUID        "12345678-1234-1234-1234-123456789ABC"
#define SENSOR_CHAR_UUID    "12345678-1234-1234-1234-123456789ABD"
#define GESTURE_CHAR_UUID   "12345678-1234-1234-1234-123456789ABE"
#define HAPTIC_CHAR_UUID    "12345678-1234-1234-1234-123456789ABF"
#define INFO_CHAR_UUID      "12345678-1234-1234-1234-123456789AC0"

BLEServer* pServer = NULL;
BLECharacteristic* pSensorCharacteristic = NULL;
BLECharacteristic* pGestureCharacteristic = NULL;
BLECharacteristic* pHapticCharacteristic = NULL;
BLECharacteristic* pInfoCharacteristic = NULL;

bool deviceConnected = false;
bool oldDeviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Device connected");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Device disconnected");
    }
};

class HapticCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      if (value.length() == 4) {
        uint8_t effectId = value[0];
        uint8_t intensity = value[1];
        uint16_t duration = value[2] | (value[3] << 8);
        Serial.printf("Haptic: effect=%d, intensity=%d, duration=%dms\n", 
                     effectId, intensity, duration);
        // TODO: Implement haptic feedback
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Anime Aggressors Wristband - Starting...");

  // Initialize BLE
  BLEDevice::init("Edge-IO Wristband");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create service
  BLEService *pService = pServer->getServer()->createService(SERVICE_UUID);

  // Sensor stream characteristic (notify)
  pSensorCharacteristic = pService->createCharacteristic(
    SENSOR_CHAR_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pSensorCharacteristic->addDescriptor(new BLE2902());

  // Gesture event characteristic (notify/write)
  pGestureCharacteristic = pService->createCharacteristic(
    GESTURE_CHAR_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE
  );
  pGestureCharacteristic->addDescriptor(new BLE2902());

  // Haptic control characteristic (write)
  pHapticCharacteristic = pService->createCharacteristic(
    HAPTIC_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  pHapticCharacteristic->setCallbacks(new HapticCallbacks());

  // Device info characteristic (read)
  pInfoCharacteristic = pService->createCharacteristic(
    INFO_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ
  );
  pInfoCharacteristic->setValue("{\"serial\":\"BAND001\",\"fwVersion\":\"0.1.0\",\"battery\":90}");

  // Start service and advertising
  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE advertising started");
}

void loop() {
  // Handle disconnection
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Restart advertising");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // TODO: Read IMU sensor data (200Hz for wristband)
  // TODO: Process gesture detection
  // TODO: Send sensor data via BLE
  
  delay(5); // 200Hz loop
}
