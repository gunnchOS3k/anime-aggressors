#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <BMI270.h>
#include <DRV2605L.h>

// BLE Configuration
#define SERVICE_UUID "12345678-1234-1234-1234-123456789abc"
#define CHARACTERISTIC_UUID "87654321-4321-4321-4321-cba987654321"

// IMU Configuration
BMI270 imu;
DRV2605L haptics;

// BLE Server
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Gesture Detection
struct IMUData {
  float accelX, accelY, accelZ;
  float gyroX, gyroY, gyroZ;
  unsigned long timestamp;
};

struct GestureData {
  String type;
  float confidence;
  unsigned long timestamp;
};

// Gesture detection variables
float gestureThreshold = 2.0;
unsigned long lastGestureTime = 0;
const unsigned long gestureCooldown = 100; // ms

// BLE Server Callbacks
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

// IMU Data Reading
IMUData readIMU() {
  IMUData data;
  
  // Read accelerometer
  data.accelX = imu.getAccelX();
  data.accelY = imu.getAccelY();
  data.accelZ = imu.getAccelZ();
  
  // Read gyroscope
  data.gyroX = imu.getGyroX();
  data.gyroY = imu.getGyroY();
  data.gyroZ = imu.getGyroZ();
  
  data.timestamp = millis();
  
  return data;
}

// Gesture Detection
GestureData detectGesture(IMUData data) {
  GestureData gesture;
  gesture.type = "none";
  gesture.confidence = 0.0;
  gesture.timestamp = data.timestamp;
  
  // Check for gesture cooldown
  if (data.timestamp - lastGestureTime < gestureCooldown) {
    return gesture;
  }
  
  // Detect swipe gestures
  if (abs(data.accelX) > gestureThreshold || abs(data.accelY) > gestureThreshold) {
    if (abs(data.accelX) > abs(data.accelY)) {
      gesture.type = data.accelX > 0 ? "swipe_right" : "swipe_left";
    } else {
      gesture.type = data.accelY > 0 ? "swipe_up" : "swipe_down";
    }
    gesture.confidence = min(abs(data.accelX), abs(data.accelY)) / gestureThreshold;
    lastGestureTime = data.timestamp;
  }
  
  // Detect thrust gesture
  if (data.accelZ > 3.0) {
    gesture.type = "thrust";
    gesture.confidence = min(data.accelZ / 3.0, 1.0);
    lastGestureTime = data.timestamp;
  }
  
  // Detect tap gesture
  if (abs(data.accelZ) > 1.5 && abs(data.accelZ) < 2.5) {
    gesture.type = "tap";
    gesture.confidence = 0.8;
    lastGestureTime = data.timestamp;
  }
  
  return gesture;
}

// Haptic Feedback
void triggerHaptic(String gestureType) {
  if (!deviceConnected) return;
  
  // Different haptic patterns for different gestures
  if (gestureType == "swipe_left" || gestureType == "swipe_right") {
    haptics.setWaveform(0, 1); // Light tap
    haptics.setWaveform(1, 0);
  } else if (gestureType == "thrust") {
    haptics.setWaveform(0, 3); // Strong impact
    haptics.setWaveform(1, 0);
  } else if (gestureType == "tap") {
    haptics.setWaveform(0, 2); // Medium tap
    haptics.setWaveform(1, 0);
  }
  
  haptics.go();
}

// Send BLE Data
void sendBLEData(IMUData imuData, GestureData gesture) {
  if (!deviceConnected) return;
  
  // Create JSON-like string
  String data = "{";
  data += "\"accel\":{\"x\":" + String(imuData.accelX, 2) + ",\"y\":" + String(imuData.accelY, 2) + ",\"z\":" + String(imuData.accelZ, 2) + "},";
  data += "\"gyro\":{\"x\":" + String(imuData.gyroX, 2) + ",\"y\":" + String(imuData.gyroY, 2) + ",\"z\":" + String(imuData.gyroZ, 2) + "},";
  data += "\"gesture\":\"" + gesture.type + "\",";
  data += "\"confidence\":" + String(gesture.confidence, 2) + ",";
  data += "\"timestamp\":" + String(imuData.timestamp) + ",";
  data += "\"battery\":" + String(analogRead(A0) * 100 / 1023);
  data += "}";
  
  pCharacteristic->setValue(data.c_str());
  pCharacteristic->notify();
}

void setup() {
  Serial.begin(115200);
  Serial.println("Edge-IO Ring starting...");
  
  // Initialize I2C
  Wire.begin();
  
  // Initialize IMU
  if (!imu.begin()) {
    Serial.println("Failed to initialize BMI270");
    while (1);
  }
  Serial.println("BMI270 initialized");
  
  // Initialize Haptics
  if (!haptics.begin()) {
    Serial.println("Failed to initialize DRV2605L");
  } else {
    Serial.println("DRV2605L initialized");
  }
  
  // Initialize BLE
  BLEDevice::init("Edge-IO Ring");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  BLEService *pService = pServer->getService();
  if (pService == NULL) {
    pService = pServer->createService(SERVICE_UUID);
  }
  
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  
  pCharacteristic->setValue("Edge-IO Ring Ready");
  pCharacteristic->addDescriptor(new BLE2902());
  
  pService->start();
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE advertising started");
}

void loop() {
  // Handle BLE connection
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Start advertising");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
  
  // Read IMU data
  IMUData imuData = readIMU();
  
  // Detect gestures
  GestureData gesture = detectGesture(imuData);
  
  // Send data via BLE
  sendBLEData(imuData, gesture);
  
  // Trigger haptic feedback
  if (gesture.type != "none") {
    triggerHaptic(gesture.type);
    Serial.println("Gesture detected: " + gesture.type + " (confidence: " + String(gesture.confidence, 2) + ")");
  }
  
  delay(10); // 100Hz sampling rate
}