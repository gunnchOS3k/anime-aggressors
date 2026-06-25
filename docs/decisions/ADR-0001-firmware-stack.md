# ADR-0001: Firmware Stack for Edge-IO Wearable Prototype

**Status:** Accepted (provisional — revisit after mule milestone)  
**Date:** 2026-06-24  
**Deciders:** Engineering / embedded lead  
**Context:** Anime Aggressors Edge-IO ring/wristband firmware on nRF52840

---

## Context and problem statement

The repository contains `firmware/ring/` targeting **nRF52840** via PlatformIO (`nordicnrf52` platform, Arduino framework). Current `main.cpp`:

- Uses **ESP32-style** `BLEDevice.h` APIs incompatible with standard nRF52840 Arduino stacks.
- Emits **JSON strings** over BLE notify instead of the canonical binary protocol in `docs/EDGE_IO_PROTOCOL.md`.
- References BMI270 + DRV2605L drivers without verified compile on CI or bench.

We need a firmware stack decision for the **next prototype** (dev-board mule) that minimizes time-to-demo while preserving a path to production-quality BLE, DFU, and power management.

---

## Decision drivers

1. **Time to binary protocol demo** on nRF52840 DK.
2. **Team familiarity** (TypeScript-heavy game team; limited embedded bandwidth).
3. **BLE stability** for 100 Hz SensorNotify + gesture events.
4. **DFU / field updates** before any pilot hardware ship.
5. **Migration cost** when moving from mule → EVT wristband → ring PCB.
6. **Honesty:** do not claim production firmware until measured on hardware.

---

## Options considered

### Option A — Adafruit nRF52 Arduino (Bluefruit / Nordic Arduino core)

**Description:** PlatformIO `nordicnrf52` + Arduino framework; Adafruit Bluefruit nRF52 libraries or Sandeep Mistry Arduino-nRF52 fork patterns.

| Pros | Cons |
|------|------|
| Fastest path from DK to notify characteristic | Arduino abstraction less ideal for ultra-low power |
| Large community examples for BLE UART/notify | DFU story fragmented vs Nordic official |
| Matches existing `platformio.ini` direction | Not Nordic-first support tier long-term |
| IMU/haptic Arduino libraries available | Easy to accrue technical debt |

### Option B — Zephyr / Nordic Connect SDK (NCS)

**Description:** Nordic official RTOS; BLE via SoftDevice Controller; West manifest; VS Code / nRF Connect extension.

| Pros | Cons |
|------|------|
| Nordic production path; best long-term support | Steeper learning curve for small team |
| Integrated DFU, PM, security | Longer mule timeline (weeks → months) |
| Fine-grained power management | Different build system from current PlatformIO |
| Better fit for EVT/DVT/PVT | Requires dedicated embedded owner |

### Option C — Stay on broken ESP32-API sketch

**Rejected.** Does not compile correctly on nRF52840; perpetuates protocol mismatch.

---

## Decision

**Recommend Option A — Adafruit / nRF52 Arduino path — for the dev-board mule and first wristband EVT**, with explicit migration triggers to Option B (Zephyr/NCS) documented below.

**Rationale:**

1. v0.5 public demo needs **binary GestureNotify on real silicon** sooner than NCS onboarding allows for a TS-heavy team.
2. nRF52840 DK is already configured in `platformio.ini`.
3. Canonical protocol is small (22 + 12 + 4 byte packets) — easy to implement with raw characteristic writes in Arduino.
4. Production ring (battery life, cert, OTA at scale) likely needs NCS **after** protocol and gesture algorithms are validated on mule.

---

## Implementation consequences (Option A)

1. Replace ESP32 BLE includes with **nRF52-compatible** stack (e.g. Adafruit Bluefruit or Arduino-nRF52-BLE).
2. Implement `SensorNotify`, `GestureNotify`, `HapticWrite` exactly per `docs/EDGE_IO_PROTOCOL.md`.
3. Add `TEST_MODE` compile flag emitting synthetic IMU frames (partially configured in `platformio.ini`).
4. Document IMU scale factors in `firmware/ring/PROTOCOL.md`.
5. Record `pio run` result in `docs/VALIDATION_REPORT.md` — do not claim success without log.

---

## Migration triggers to Zephyr/NCS

Migrate when **any** of:

| Trigger | Threshold |
|---------|-----------|
| Battery life | Cannot meet 3 h active on Arduino stack after optimization |
| DFU requirement | Pilot users need reliable OTA ( > 50 units ) |
| BLE cert | Commercial SKU requires qualified stack traceability |
| Team capacity | Dedicated embedded engineer onboarded |
| Code size / RTOS need | Multi-threaded gesture ML or audio on-device |

**Migration plan sketch:**

1. Port protocol layer to NCS sample (peripheral_lbs or custom GATT).
2. Reuse gesture detection C module with unit tests on host.
3. Parallel-run mule on NCS before switching EVT BOM firmware.
4. Update ADR-0002 when migration starts.

---

## Rejected alternatives summary

| Option | Reason rejected |
|--------|-----------------|
| ESP32-C3 for mule | Split ecosystem from nRF52840 ring target; BLE gamepad ecosystem differs |
| Raspberry Pi Pico W | Power/size unsuitable for ring |
| Keep JSON BLE protocol | Breaks TS parser contract; wastes MTU; harder to measure latency |

---

## References

- `firmware/ring/platformio.ini`
- `docs/EDGE_IO_PROTOCOL.md`
- `docs/HARDWARE_PROTOTYPE_PLAN.md`
- Nordic nRF52840 Product Specification
- Adafruit Bluefruit nRF52 Feather learning guide

---

## Review schedule

- **After first successful mule demo:** Confirm Arduino stack sufficient for v0.5.
- **Before wristband EVT build ( > 10 units ):**
  Re-evaluate NCS migration schedule.
