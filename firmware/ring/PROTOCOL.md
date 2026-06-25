# Firmware BLE Protocol (Ring / Wristband)

Canonical binary layout is defined in `docs/EDGE_IO_PROTOCOL.md`. Firmware must match `packages/edgeio` encode/decode.

## Service UUID (placeholder — finalize before EVT)

```
0000edge-0000-1000-8000-00805f9b34fb
```

## Characteristics

| Char | UUID suffix | Direction | Size | Purpose |
|------|-------------|-----------|------|---------|
| SENSOR | ...0001 | Notify | 22 B | IMU + battery |
| GESTURE | ...0002 | Notify | 12 B | Classified gesture |
| HAPTIC | ...0003 | Write | 4 B | Host → device rumble |
| INFO | ...0004 | Read | JSON | serial, fwVersion, battery |

## SensorNotify (22 bytes, LE)

```
u32 seq
u32 timestamp_ms
i16 ax, ay, az, gx, gy, gz
u8 battery_pct
u8 flags
```

## GestureNotify (12 bytes, LE)

```
u32 seq
u32 timestamp_ms
u8 gesture_id
u8 confidence
u8 device_id
u8 reserved
```

## HapticWrite (4 bytes, LE)

```
u8 effect_id
u8 intensity
u16 duration_ms
```

## Migration note

Existing `firmware/ring/src/main.cpp` JSON notify path is **deprecated**. Wristband mule is the reference implementation target.
