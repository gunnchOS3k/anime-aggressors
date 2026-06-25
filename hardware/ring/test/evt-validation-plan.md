# Ring EVT Validation Plan

## Goals

Validate ring form factor only after wristband mule proves protocol and gesture quality.

## Matrix

| Test | Method | Pass criteria |
|------|--------|---------------|
| BLE pairing | Web Bluetooth / nRF Connect | Pair < 60 s |
| Sensor rate | Logic analyzer / host log | Stable notify rate 100–200 Hz target |
| Gesture accuracy | Scripted motions | > 90% on swipe/thrust/tap suite |
| Latency | High-speed camera + host timestamp | < 50 ms motion-to-notify p95 |
| Haptic feel | User panel (n≥5) | ≥ 4/5 clarity rating |
| Battery | Discharge test | ≥ 3 h active play target |
| Thermal | 30 min soak | No hot-spot > 45°C skin-contact |

## Sign-off

EVT passes when all P0 rows pass. Failures feed DVT revision.
