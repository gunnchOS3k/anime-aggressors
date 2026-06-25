# Hardware Prototype Plan

**Status:** Planning — no fabrication-ready KiCad/Gerber package in repo  
**Last updated:** 2026-06-24  
**Recommendation:** **Wristband / dev-board mule first**, custom ring PCB second

---

## Strategy

1. **Prove protocol + latency** on nRF52840 DK + breakout boards (weeks).
2. **EVT wristband** on semi-custom PCB (months).
3. **Ring form factor** only after wristband validates IMU placement, BLE, and haptics (EVT/DVT).
4. **Never commit fake Gerbers** — use checklists and `.gitkeep` until real outputs exist.

---

## Phase map: Mule → EVT → DVT → PVT

| Phase | Goal | Exit evidence |
|-------|------|---------------|
| **Mule** | Binary BLE + gesture + haptic on bench | Demo video; latency p50 < 50 ms |
| **EVT** | Integrated wristband PCB, 5–10 units | EVT validation matrix pass |
| **DVT** | Design for assembly, enclosure, RF | 50-unit build; DFM review |
| **PVT** | Pilot production | Yield > 95%; battery life 3–6 h |

---

## Dev-board mule (first prototype)

### Recommended stack

- **MCU:** Nordic nRF52840 DK (or Dongle)
- **IMU:** BMI270 or ICM-42688 breakout (I2C)
- **Haptic:** DRV2605L breakout + ERM or LRA
- **Power:** DK USB power initially; LiPo + charger module for wearable strap test

### Mule BOM (indicative — verify before purchase)

See `hardware/wristband/bom/dev-board-mule-bom.csv` (target). Columns:

```csv
category,reference,part_name,manufacturer,manufacturer_part_number,quantity,purpose,status,notes
```

Use `TBD` for unconfirmed MPNs. **Do not invent verified part numbers.**

| category | reference | part_name | status | notes |
|----------|-----------|-----------|--------|-------|
| mcu | DK1 | nRF52840 DK | TBD | PlatformIO target exists |
| imu | IMU1 | 6-axis IMU breakout | TBD | BMI270 or ICM-42688 |
| haptic | HAP1 | DRV2605L breakout | TBD | I2C |
| actuator | ACT1 | ERM or LRA | TBD | Match DRV2605 library |
| power | BAT1 | LiPo 200mAh | TBD | Bench only with protection |
| misc | — | Jumper wires, strap | TBD | Wrist mount for IMU feel |

**Budget estimate:** $80–150 USD (dev kit + breakouts).

---

## Custom ring (later)

Target file expectations when engineering begins — **files do not exist today**:

```text
hardware/ring/
  edgeio-ring.kicad_pro
  edgeio-ring.kicad_sch
  edgeio-ring.kicad_pcb
  bom/edgeio-ring-bom.csv
  bom/edgeio-ring-bom-with-alternates.csv
  fab/gerbers.zip
  fab/drill.zip
  fab/pick-place.csv
  fab/assembly-drawing.pdf
  fab/schematic.pdf
  enclosure/edgeio-ring.step
  enclosure/edgeio-ring.stl
  test/bringup-checklist.md
  test/evt-validation-plan.md
```

Until then: `hardware/ring/README.md` + checklists only.

---

## Schematic checklist

- [ ] nRF52840 power domains decoupled per Nordic reference
- [ ] IMU I2C pull-ups sized (typ 2.2k–4.7k)
- [ ] DRV2605L I2C address strap documented
- [ ] Battery: protection IC + fuse; charging path rated for wearable
- [ ] USB-C or pogo debug pads for factory
- [ ] SWD header or Tag-Connect for flash
- [ ] Antenna keep-out per Nordic layout guide (PCB antenna or chip antenna)
- [ ] ESD on USB/exposed pads
- [ ] Netlist ↔ BOM cross-check

---

## PCB layout checklist

- [ ] 4-layer stack if RF performance required (recommended for ring)
- [ ] IMU placed near center of wear surface (ring) or dorsal wrist
- [ ] Haptic actuator mechanically isolated from IMU (reduce false gestures)
- [ ] Ground pour continuity under RF section
- [ ] DRC clean; impedance control on antenna feed if applicable
- [ ] Test points: SWD, I2C, battery voltage
- [ ] Assembly drawing with refdes polarity for battery connector

---

## Battery & safety checklist

- [ ] Cell vendor certification (UN38.3) before ship
- [ ] Protection: over-charge, over-discharge, over-current
- [ ] Thermal: no charge above 45°C ambient
- [ ] Enclosure venting if sealed
- [ ] Drop test plan (1 m onto carpet + concrete edge cases)
- [ ] Skin contact materials: hypoallergenic strap option documented
- [ ] Failure mode: battery swell → stop ship gate

**Target runtime:** 3–6 hours active (PRD wearable section).

---

## Firmware bring-up checklist

- [ ] `pio run` succeeds for nRF52840 DK env
- [ ] IMU WHO_AM_I read passes
- [ ] 100 Hz SensorNotify on BLE
- [ ] GestureNotify on bench motion scripts
- [ ] HapticWrite triggers actuator
- [ ] Battery ADC calibrated to battery_pct
- [ ] DFU bootloader flash procedure documented
- [ ] Binary protocol matches `docs/EDGE_IO_PROTOCOL.md`

---

## Prototype validation matrix

| ID | Test | Method | Pass threshold |
|----|------|--------|----------------|
| HW-01 | BLE connect | Web Bluetooth or nRF Connect | < 60 s first pair |
| HW-02 | Sensor rate | Count notifies / 10 s | ≥ 95 Hz average |
| HW-03 | Gesture latency | Host timestamp − device ts | p50 < 50 ms, p95 < 80 ms |
| HW-04 | Notify drop | 1 h soak, seq gaps | < 1% dropped |
| HW-05 | Haptic response | HapticWrite → feel | < 30 ms actuator start |
| HW-06 | Battery runtime | Full stream until cutoff | ≥ 3 h active |
| HW-07 | Reconnect | Power cycle device | < 5 s auto-reconnect |
| HW-08 | False positive rate | 10 min idle | < 2 spurious gestures |
| HW-09 | Sim integration | swipeR → dodge in game | 90% intended actions in playtest |
| HW-10 | Thermal | 30 min continuous | Surface < 40°C |

Record results in `hardware/wristband/test/evt-validation-plan.md` when executed.

---

## Latency measurement plan

1. Sync host clock with device boot time on connect (ping exchange — future protocol extension).
2. Log `(seq, timestamp_ms, host_rx_ms)` for each GestureNotify.
3. Compute `latency = host_rx_ms - mapped_device_time`.
4. Report p50, p95, max over N ≥ 1000 events.
5. Compare: mule on desk vs worn on wrist vs ring form (later).

**Tools:** Serial log + browser Performance API, or logic analyzer on GPIO toggle synced with notify.

---

## Haptic feel test plan

| Scenario | effect_id | Expected feel |
|----------|-----------|---------------|
| Gesture ack | 1 | Light tick |
| Hit confirm (host-driven) | 3 | Strong impact |
| Low battery | 4 | Double pulse |
| Error / disconnect | 5 | Buzz |

Panel of 5 testers rate 1–5 clarity; mean ≥ 3.5 to pass.

---

## DFM / manufacturing handoff checklist

- [ ] BOM with manufacturer MPNs and alternates CSV
- [ ] Gerbers + drill + IPC-356 netlist
- [ ] Pick-place centroid file
- [ ] Assembly drawing PDF
- [ ] Test procedure (ICT or functional jig)
- [ ] Firmware binary + version pin in DEVICE_INFO
- [ ] Packaging insert with pairing URL
- [ ] RMA / bricked device recovery path (SWD pads accessible)

---

## Directory status (honest)

| Path | Exists | Notes |
|------|--------|-------|
| `hardware/ring/README.md` | Yes | Aspirational specs — not EVT |
| `hardware/ring/bom.csv` | Partial | Minimal columns; needs canonical format |
| `hardware/wristband/bom.csv` | Partial | Minimal |
| KiCad / Gerbers / STEP | **No** | Do not fabricate from README alone |

---

## Related documents

- [EDGE_IO_PROTOCOL.md](./EDGE_IO_PROTOCOL.md)
- [STATUS.md](./STATUS.md) — Hardware readiness
- [decisions/ADR-0001-firmware-stack.md](./decisions/ADR-0001-firmware-stack.md)
- [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md) §26
