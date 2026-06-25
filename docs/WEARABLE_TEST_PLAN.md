# Wearable Prototype Test Plan

**Last updated:** 2026-06-24  
**Tracks:** F (dev-board mule), G (EVT+)  
**Status:** Plan documented — **hardware-in-loop tests not yet executed**

---

## 1. Purpose

Validate Edge-IO wearables from bench mule through EVT with repeatable procedures and recorded evidence. Supports honest STATUS updates — no "validated" claims without logs.

---

## 2. Test environments

| Environment | Hardware | Tracks |
|-------------|----------|--------|
| **Bench** | nRF52840 DK + IMU + DRV2605L breakouts | F2–F5 |
| **Strap mule** | DK on wrist strap | F6–F8 |
| **EVT wristband** | Integrated PCB + enclosure | G6 |
| **Host** | Chrome desktop + Web Bluetooth (or serial sniffer) | All |

---

## 3. Bench bring-up (F2–F5)

Reference: `hardware/wristband/test/bringup-checklist.md`

| Test ID | Procedure | Pass criteria | Evidence |
|---------|-----------|---------------|----------|
| B-01 | Power DK via USB | LED/boot log | Photo + serial log |
| B-02 | I2C scan IMU | Address detected | Log |
| B-03 | IMU stream 100 Hz | Stable samples 60 s | CSV capture |
| B-04 | BLE advertise | Visible in nRF Connect | Screenshot |
| B-05 | SensorNotify 22 bytes | Hex matches `EDGE_IO_PROTOCOL.md` | Sniffer log |
| B-06 | GestureNotify 12 bytes | seq increments; gesture_id valid | Sniffer log |
| B-07 | HapticWrite | Actuator fires per effect_id | Video |
| B-08 | Battery ADC | `battery_pct` plausible 0–100 | Log |

**Current status:** Not executed in CI; firmware compile unverified.

---

## 4. Latency measurement (F7)

| Test ID | Procedure | Pass criteria |
|---------|-----------|---------------|
| L-01 | IMU spike → GestureNotify on wire | Timestamp delta logged |
| L-02 | GestureNotify → host `performance.now()` | p50 < 50 ms, p95 < 80 ms |
| L-03 | 10 min continuous stream | Drop rate < 1% |
| L-04 | Connection interval sweep | Document 7.5 vs 15 ms impact |

**Method:**

1. Firmware logs `gesture_ts_us` in packet (or GPIO toggle on notify).
2. Host records receive time in Web Bluetooth callback.
3. Minimum 100 gestures per tester; report percentiles.

---

## 5. Game integration (F6)

| Test ID | Procedure | Pass criteria |
|---------|-----------|---------------|
| G-01 | Map gesture → dodge | Player dodges in vertical slice |
| G-02 | Map gesture → attack | Attack triggers |
| G-03 | Keyboard-only match | Full match without device |
| G-04 | Simultaneous 2 wearables | 2P couch without cross-talk |

Software path: `packages/edgeio` → `apps/web` mapper. **G-01–G-04:** software-only pass possible with fake packets; hardware pass requires F3.

---

## 6. Haptic feel (F8)

| Test ID | Procedure | Pass criteria |
|---------|-----------|---------------|
| H-01 | Intensity sweep 0–255 | Monotonic perceived strength |
| H-02 | Accessibility cap at 128 | Respects host setting |
| H-03 | 30 min intermittent haptics | No actuator overheat |
| H-04 | Subjective panel (n≥5) | ≥ 3/5 "acceptable" for ack pulse |

---

## 7. Wear testing (strap mule / EVT)

| Test ID | Procedure | Pass criteria |
|---------|-----------|---------------|
| W-01 | 30 min continuous wear | No skin marking or pain |
| W-02 | 2 h play session | Runtime meets PWR-01 |
| W-03 | Sweat simulation (light exercise) | IPX4 target — no ingress |
| W-04 | Strap adjustment range | COMF-01 circumference range |

**Safety gate:** SAFE-06 review before W-01 on non-team volunteers.

---

## 8. EVT validation matrix (G6)

Full matrix: `hardware/wristband/test/evt-validation-plan.md`

Summary categories:

- Electrical (power, charge, sleep current)
- BLE (range, reconnect, throughput)
- IMU (orientation, false positive rate)
- Haptics (consistency lot)
- Mechanical (drop 1 m to carpet, strap pull)
- Firmware (DFU, rollback)

**Exit:** ≥ 90% tests pass; failures have tracked engineering responses.

---

## 9. Regression policy

| Change type | Re-run tests |
|-------------|--------------|
| BLE packet layout | B-05, B-06, L-01–L-04 |
| Gesture algorithm | F7, G-01–G-02 |
| PCB antenna | L-03, BLE range |
| Battery/cell | W-02, charge safety |
| Enclosure | W-01–W-03 |

---

## 10. Evidence storage

Store under `hardware/wristband/test/evidence/` or `hardware/ring/test/evidence/` (create per milestone):

```text
evidence/
  YYYY-MM-DD_bench_B-05_sensor_notify.log
  YYYY-MM-DD_latency_L-02_summary.json
  README.md   # index of runs
```

Do not commit large binary captures without `.gitignore` rules — link from VALIDATION_REPORT if stored externally.

---

## 11. Current honest summary

| Area | Status |
|------|--------|
| Bench bring-up | Not executed |
| Latency | Not measured |
| Game integration | Fake packet / mapper tests only |
| EVT matrix | Template only |
| Safety review | Not started |

---

## Related documents

- [WEARABLE_PRODUCT_REQUIREMENTS.md](./WEARABLE_PRODUCT_REQUIREMENTS.md)
- [WEARABLE_EVT_DVT_PVT_PLAN.md](./WEARABLE_EVT_DVT_PVT_PLAN.md)
- [EDGE_IO_PROTOCOL.md](./EDGE_IO_PROTOCOL.md)
- `firmware/ring/README.md`
