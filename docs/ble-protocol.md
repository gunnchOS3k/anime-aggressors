# BLE Protocol Specification

## Service UUIDs (Placeholder)
- **Anime Aggressors Service**: `12345678-1234-1234-1234-123456789ABC`

## Characteristics

### SENSOR_STREAM (Notify)
- **UUID**: `12345678-1234-1234-1234-123456789ABD`
- **Format**: 14 bytes
  - `t:u16` (timestamp)
  - `ax:i16, ay:i16, az:i16` (accelerometer, scale: g/16384)
  - `gx:i16, gy:i16, gz:i16` (gyroscope, scale: deg/s/131)
- **Connection**: 7.5-15ms interval, MTU up to 185

### GESTURE_EVENT (Notify/Write)
- **UUID**: `12345678-1234-1234-1234-123456789ABE`
- **Format**: 3 bytes
  - `type:u8` (0=idle,1=swipeL,2=swipeR,3=thrust,4=block,5=tap,6=doubleTap,7=shake)
  - `t:u16` (timestamp)

### HAPTIC_CTRL (Write)
- **UUID**: `12345678-1234-1234-1234-123456789ABF`
- **Format**: 4 bytes
  - `effectId:u8, intensity:u8, durationMs:u16`

### DEVICE_INFO (Read)
- **UUID**: `12345678-1234-1234-1234-123456789AC0`
- **Format**: Variable (JSON string)
  - `{"serial":"...","fwVersion":"...","battery":85}`

## Packet Examples

### Sensor Stream (14 bytes)
```
t=1000, ax=1638, ay=0, az=16384, gx=0, gy=0, gz=0
Hex: E8 03 66 06 00 00 00 40 00 00 00 00 00 00
```

### Gesture Event (3 bytes)
```
type=3 (thrust), t=1000
Hex: 03 E8 03
```

### Haptic Control (4 bytes)
```
effectId=1, intensity=128, durationMs=500
Hex: 01 80 F4 01
```
