# Edge-IO Protocol — Canonical Binary Specification

**Version:** 1.0  
**Status:** Canonical for TS parser, firmware target, and Web Bluetooth  
**Implementation:** `packages/edgeio/src/parser.ts`, `gestures.ts`  
**Last updated:** 2026-06-24

> **Honesty note:** TypeScript parser and tests implement this spec. Current `firmware/ring/src/main.cpp` sends JSON strings over BLE — **not compliant**. Migration required per ADR-0001 and firmware README.

---

## Design goals

1. Fixed-size packets for predictable MTU usage.
2. Little-endian wire format.
3. Sequence numbers for drop detection.
4. Host timestamps for latency measurement.
5. Gestures normalized to app-level enum before simulation.

---

## BLE service layout (target)

| Item | UUID (placeholder — finalize before production) |
|------|--------------------------------------------------|
| Service | `12345678-1234-1234-1234-123456789abc` |
| Sensor stream (Notify) | `12345678-1234-1234-1234-123456789abd` |
| Gesture event (Notify) | `12345678-1234-1234-1234-123456789abe` |
| Haptic control (Write) | `12345678-1234-1234-1234-123456789abf` |
| Device info (Read) | `12345678-1234-1234-1234-123456789ac0` |

**Connection parameters (target):**

- Interval: 7.5–15 ms
- MTU: ≥ 23 bytes (packets fit in single notification)
- Sensor notify rate: up to 100 Hz
- Gesture notify: on detection (debounced 10–20 Hz max effective)

---

## Packet: SensorNotify (22 bytes)

High-rate IMU + metadata stream.

| Offset | Size | Type | Field | Description |
|--------|------|------|-------|-------------|
| 0 | 4 | u32 | seq | Monotonic sequence number |
| 4 | 4 | u32 | timestamp_ms | Device millis since boot |
| 8 | 2 | i16 | ax | Accelerometer X (raw device units) |
| 10 | 2 | i16 | ay | Accelerometer Y |
| 12 | 2 | i16 | az | Accelerometer Z |
| 14 | 2 | i16 | gx | Gyroscope X |
| 16 | 2 | i16 | gy | Gyroscope Y |
| 18 | 2 | i16 | gz | Gyroscope Z |
| 20 | 1 | u8 | battery_pct | 0–100 |
| 21 | 1 | u8 | flags | Bitfield (see below) |

**Constants:** `SENSOR_PACKET_SIZE = 22`

### flags bitfield

| Bit | Meaning |
|-----|---------|
| 0 | charging |
| 1 | calibrated |
| 2 | low_battery (< 15%) |
| 3–7 | reserved (0) |

### Scaling (implementation-defined, document per firmware)

Suggested for host display (not sim-authoritative):

- Accel: milli-g = raw / 16384 × 1000 (if sensor uses ±16g 16-bit)
- Gyro: milli-dps = raw / 131 (if ±2000 dps)

Firmware must document actual scale in `firmware/ring/PROTOCOL.md` when IMU driver is chosen.

---

## Packet: GestureNotify (12 bytes)

Discrete gesture events for input mapping.

| Offset | Size | Type | Field | Description |
|--------|------|------|-------|-------------|
| 0 | 4 | u32 | seq | Monotonic sequence |
| 4 | 4 | u32 | timestamp_ms | Detection time (device ms) |
| 8 | 1 | u8 | gesture_id | See enum below |
| 9 | 1 | u8 | confidence | 0–100 |
| 10 | 1 | u8 | device_id | 0–255 multi-device index |
| 11 | 1 | u8 | reserved | Must be 0 |

**Constants:** `GESTURE_PACKET_SIZE = 12`

### gesture_id enum

| ID | App name | Description |
|----|----------|-------------|
| 0 | `tap` | Short impact / tap |
| 1 | `swipeL` | Swipe left |
| 2 | `swipeR` | Swipe right |
| 3 | `swipeU` | Swipe up |
| 4 | `swipeD` | Swipe down |
| 5 | `thrust` | Forward punch/thrust |
| 6 | `doubleTap` | Two taps within window |
| 7 | `block` | Defensive block pose |
| 8 | `shake` | Shake / grab motion |

Unknown IDs map to `tap` in parser (conservative default) — log warning in debug builds.

### TypeScript normalized names

```typescript
type GestureName =
  | "swipeL" | "swipeR" | "swipeU" | "swipeD"
  | "thrust" | "tap" | "doubleTap" | "block" | "shake";
```

---

## Packet: HapticWrite (4 bytes)

Host → device haptic command. **Output-only; never required for gameplay.**

| Offset | Size | Type | Field | Description |
|--------|------|------|-------|-------------|
| 0 | 1 | u8 | effect_id | Effect library index |
| 1 | 1 | u8 | intensity | 0–255 |
| 2 | 2 | u16 | duration_ms | Duration milliseconds |

**Constants:** `HAPTIC_PACKET_SIZE = 4`

### effect_id (initial library)

| ID | Effect |
|----|--------|
| 0 | none / stop |
| 1 | light tick |
| 2 | medium tap |
| 3 | strong impact |
| 4 | success pulse |
| 5 | error buzz |

DRV2605L waveform library may map 1:1 in firmware.

---

## Parser API (TypeScript)

```typescript
parseSensorPacket(dv: DataView): SensorNotify
parseGesturePacket(dv: DataView): GestureNotify
parseHapticPacket(dv: DataView): HapticWrite

createSensorPacket(sensor: SensorNotify): Uint8Array
createGesturePacket(seq, timestampMs, gesture, confidence?, deviceId?): Uint8Array
createHapticPacket(cmd: HapticWrite): Uint8Array
```

---

## Example hex dumps

### SensorNotify

```
seq=42, ts=1000, ax=100, ay=0, az=0, gx=0, gy=0, gz=0, battery=90, flags=0
```

### GestureNotify (swipeR, confidence 95, device 1)

```
seq=7, ts=500, gesture_id=2, confidence=95, device_id=1, reserved=0
```

### HapticWrite (effect 2, intensity 200, duration 150 ms)

```
effect_id=2, intensity=200, duration_ms=150
→ bytes: 02 C8 96 00
```

---

## Host processing pipeline

```text
BLE notify bytes
  → parseGesturePacket / parseSensorPacket
  → normalizeGestureId(gesture_id)
  → mapGestureToInput(gesture)  // packages/edgeio
  → applyEdgeIOGesture(input, gesture, config)  // apps/web
  → InputFrame in pollAllInputs
  → RollbackSession (no BLE in sim)
```

**Latency measurement:**

```
latency_ms = host_receive_time - (device_boot_anchor + timestamp_ms)
```

Record p50/p95 over 1000 gestures in validation matrix.

---

## Reliability requirements

| Metric | Target | Test |
|--------|--------|------|
| Notify drop rate | < 1% in noisy RF | 1 h soak test |
| seq gaps | Detect and log | Host counter |
| Pairing time | < 60 s | Manual |
| Auto-reconnect | < 5 s | Disconnect test |

---

## Security

- Pairing user-initiated (Web Bluetooth `requestDevice`).
- No IMU upload to cloud without opt-in.
- HapticWrite rate-limited in firmware (max 20 commands/s).

---

## Compliance checklist

| Component | Compliant |
|-----------|-----------|
| `packages/edgeio` parser | Yes |
| `packages/edgeio` tests | Yes |
| `firmware/ring` | **No** (JSON legacy) |
| `docs/ble-protocol.md` (old) | Superseded by this doc |

---

## Related documents

- [INPUT_SYSTEM.md](./INPUT_SYSTEM.md)
- [HARDWARE_PROTOTYPE_PLAN.md](./HARDWARE_PROTOTYPE_PLAN.md)
- [decisions/ADR-0001-firmware-stack.md](./decisions/ADR-0001-firmware-stack.md)
