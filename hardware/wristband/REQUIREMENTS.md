# Wristband Hardware Requirements

**Last updated:** 2026-06-24  
**Phase:** Mule → EVT (wristband first)  
**Honest status:** Dev-board mule BOM only — **no schematic, no PCB, no Gerbers**

---

## Scope

Electrical and mechanical requirements for the **Edge-IO wristband** line, starting with dev-board mule and progressing to EVT PCB. Ring requirements are in `hardware/ring/REQUIREMENTS.md`.

---

## Requirements gates

### Gate M0 — Mule planning (current)

| Item | Requirement | Status |
|------|-------------|--------|
| M0-1 | Dev-board BOM CSV with required columns | Done — `bom/dev-board-mule-bom.csv` |
| M0-2 | Bring-up checklist | Done — `test/bringup-checklist.md` |
| M0-3 | PlatformIO target documented | Done — `firmware/ring/platformio.ini` |
| M0-4 | Binary protocol spec | Done — `docs/EDGE_IO_PROTOCOL.md` |

### Gate M1 — Mule bench validated (Track F)

| Item | Requirement | Status |
|------|-------------|--------|
| M1-1 | IMU data on serial/log | Not verified |
| M1-2 | BLE binary notify on sniffer | **Blocked** — firmware JSON mismatch |
| M1-3 | HapticWrite bench test | Not verified |
| M1-4 | Latency L-02 p50 < 50 ms | Not measured |
| M1-5 | `pio run` success logged | Not in CI |

**Do not proceed to EVT layout until M1-1 through M1-4 pass.**

### Gate E0 — EVT schematic ready (G2)

| Item | Requirement | Status |
|------|-------------|--------|
| E0-1 | KiCad project in `hardware/wristband/` | Not started |
| E0-2 | nRF52840 power domains per Nordic ref | Not started |
| E0-3 | IMU I2C pull-ups documented | Not started |
| E0-4 | DRV2605L netlist + I2C address | Not started |
| E0-5 | Battery protection + charger IC | Not started |
| E0-6 | SWD or Tag-Connect footprint | Not started |
| E0-7 | Antenna keep-out documented | Not started |
| E0-8 | Safety review SAFE-01–SAFE-03 | Not started |

### Gate E1 — EVT fabrication (G5)

| Item | Requirement | Status |
|------|-------------|--------|
| E1-1 | DRC clean PCB | Not started |
| E1-2 | Real `fab/gerbers.zip` | **Missing — do not fake** |
| E1-3 | Pick-place + assembly drawing | Not started |
| E1-4 | EVT BOM ≠ all TBD on critical ICs | Not started |
| E1-5 | Enclosure STEP for fit check | Not started |

### Gate E2 — EVT validation (G6)

| Item | Requirement | Status |
|------|-------------|--------|
| E2-1 | 5 units assembled | Not started |
| E2-2 | EVT matrix ≥ 90% pass | Not started |
| E2-3 | 3 h runtime on 3 units | Not started |

---

## Electrical requirements

| ID | Requirement | Target / note |
|----|-------------|---------------|
| WR-E-01 | MCU | nRF52840 class |
| WR-E-02 | IMU | 6-axis, I2C, 100 Hz sample |
| WR-E-03 | Haptic | DRV2605L or qualified alternate (TBD) |
| WR-E-04 | BLE | Peripheral; custom GATT per protocol doc |
| WR-E-05 | Battery | LiPo pouch 150–300 mAh (mule/EVT TBD) |
| WR-E-06 | Charge | USB-C or magnetic pogo — rated current |
| WR-E-07 | Sleep current | Target < 50 µA (EVT measurement) |
| WR-E-08 | ESD | USB and exposed pads protected |

---

## Mechanical requirements

| ID | Requirement | Target |
|----|-------------|--------|
| WR-M-01 | Wrist circumference | 150–210 mm adjustable strap |
| WR-M-02 | Weight | < 45 g assembled (EVT target) |
| WR-M-03 | IP rating | IPX4 splash (EVT target) |
| WR-M-04 | IMU axis | Consistent with palm-facing gesture set |

---

## BOM policy

- Use `TBD` for unverified MPNs.
- Files: `bom/dev-board-mule-bom.csv`, future `bom/evt-bom.csv`.
- Do not copy ring BOM parts without wristband fit validation.

---

## Related documents

- [../../docs/WEARABLE_PRODUCT_REQUIREMENTS.md](../../docs/WEARABLE_PRODUCT_REQUIREMENTS.md)
- [../../docs/WEARABLE_EVT_DVT_PVT_PLAN.md](../../docs/WEARABLE_EVT_DVT_PVT_PLAN.md)
- [README.md](./README.md)
- [test/evt-validation-plan.md](./test/evt-validation-plan.md)
