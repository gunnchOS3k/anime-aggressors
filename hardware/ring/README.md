# 🔮 Edge-IO Ring Hardware

> **Wearable gesture controller for Anime Aggressors**

## 📋 Overview

The Edge-IO Ring is a compact wearable device that enables gesture-based input for Anime Aggressors. It features BLE connectivity, IMU sensors, haptic feedback, and a sleek design optimized for gaming.

## 🔧 Specifications

### **Core Components**
- **MCU**: nRF52840 (ARM Cortex-M4F, 64MHz)
- **Sensors**: 6-axis IMU (BMI270)
- **Haptics**: DRV2605L + ERM actuator
- **Connectivity**: BLE 5.0 (up to 2Mbps)
- **Power**: Li-Po 50-300mAh
- **Charging**: USB-C + wireless charging

### **Performance**
- **Latency**: <50ms gesture detection
- **Battery**: 8-12 hours continuous use
- **Range**: 10m BLE range
- **Sampling**: 100Hz IMU data
- **Haptics**: 0-100% intensity, 20-250Hz

## 🎯 Gesture Recognition

### **Supported Gestures**
- **Swipe Left/Right**: Dodge movements
- **Swipe Up/Down**: Jump/Crouch
- **Thrust Forward**: Heavy attacks
- **Tap**: Light attacks
- **Hold**: Special moves

### **Detection Algorithm**
```typescript
// Gesture detection pipeline
const gesture = await edgeio.detectGesture({
  accel: { x, y, z },
  gyro: { x, y, z },
  timestamp: Date.now()
});
```

## 🔌 Connectivity

### **BLE Protocol**
- **Service UUID**: `12345678-1234-1234-1234-123456789abc`
- **Characteristic**: IMU data stream
- **Security**: AES-128 encryption
- **Pairing**: Secure device authentication

### **Data Format**
```json
{
  "deviceId": "edgeio-ring-001",
  "timestamp": 1640995200000,
  "accel": { "x": 0.1, "y": 0.2, "z": 9.8 },
  "gyro": { "x": 0.0, "y": 0.0, "z": 0.0 },
  "battery": 85,
  "gesture": "swipe_right"
}
```

## 🛠️ Development

### **Firmware**
```bash
cd firmware/ring
pio run -t upload
```

### **Testing**
```bash
# Flash test firmware
pio run -t upload -e test

# Monitor serial output
pio device monitor
```

## 📊 Schematics

### **KiCad Project**
- **Main PCB**: 4-layer design
- **IMU**: BMI270 (I2C)
- **Haptics**: DRV2605L (I2C)
- **Power**: BQ24040 charger
- **Antenna**: Integrated PCB antenna

### **BOM (Bill of Materials)**
| Component | Part Number | Quantity | Cost |
|-----------|-------------|----------|------|
| MCU | nRF52840 | 1 | $8.50 |
| IMU | BMI270 | 1 | $3.20 |
| Haptics | DRV2605L | 1 | $2.80 |
| Battery | Li-Po 100mAh | 1 | $4.50 |
| **Total** | | | **$19.00** |

## 🎨 Design

### **Ergonomics**
- **Size**: 18mm inner diameter
- **Weight**: <15g
- **Material**: TPU + PC blend
- **Colors**: Black, White, Neon variants

### **Comfort Features**
- **Ventilation**: Micro-perforations for airflow
- **Grip**: Textured surface for secure fit
- **Adjustable**: 3 size options (S/M/L)

## 🔋 Power Management

### **Battery Life**
- **Gaming**: 8-10 hours
- **Standby**: 30+ days
- **Charging**: 2 hours to full

### **Power Modes**
- **Active**: 100Hz sampling, BLE streaming
- **Idle**: 10Hz sampling, BLE advertising
- **Sleep**: <1μA current draw

## 🚀 Getting Started

### **Hardware Setup**
1. **Flash Firmware**: Use PlatformIO
2. **Pair Device**: Connect via BLE
3. **Calibrate**: Run gesture calibration
4. **Test**: Use built-in gesture tester

### **Software Integration**
```typescript
import { EdgeIO } from '@anime-aggressors/edgeio';

const edgeio = new EdgeIO();
await edgeio.connect();

edgeio.onGesture((gesture) => {
  if (gesture.type === 'swipe_right') {
    player.dodge('right');
  }
});
```

## 📈 Roadmap

- **Q1 2025**: Prototype hardware
- **Q2 2025**: Mass production setup
- **Q3 2025**: Retail launch
- **Q4 2025**: Advanced features

## 🤝 Contributing

We welcome hardware contributions! See our [Contributing Guide](../CONTRIBUTING.md) for details.

## 📄 License

MIT License - see [LICENSE](../LICENSE) for details.

---

**Built with ❤️ by the Anime Aggressors team**

🔗 [GitHub](https://github.com/gunnchOS3k/anime-aggressors) • 📱 [Discord](https://discord.gg/anime-aggressors) • 🌐 [Website](https://anime-aggressors.com)
