# Wearable Edge-IO — Product Requirements

**Last updated:** 2026-06-24  
**Track:** F (dev-board mule), G (production hardware)  
**Status:** Requirements defined — **no retail SKU exists**

---

## 1. Product promise

Edge-IO wearables (wristband first, ring later) are **optional** input and feedback devices. Players must complete a full match with keyboard/gamepad only (PRD EDGE-05).

**Promise:** Comfortable, safe motion gestures map to standard game actions with perceptible haptic acknowledgment — without requiring wearables to compete fairly.

---

## 2. Form factors and sequencing

| Form factor | Priority | Rationale |
|-------------|----------|-----------|
| **Wristband dev-board mule** | First | Room for battery, antenna, debug; validates protocol |
| **Wristband EVT PCB** | Second | Integrated product shape after mule pass |
| **Ring** | Third | Miniaturization after wristband EVT/DVT lessons |

Do not skip mule → EVT on custom ring PCB.

---

## 3. Comfort and ergonomics

| Req ID | Requirement | Target | Validation |
|--------|-------------|--------|------------|
| COMF-01 | Wristband adjustable strap | Fits 150–210 mm wrist circumference | Fit test on 5 body types |
| COMF-02 | Ring sizing | Sizes 6–12 US (TBD kit) or adjustable band | Sizing guide in box |
| COMF-03 | Weight (wristband) | < 45 g assembled (target) | Scale measurement |
| COMF-04 | Weight (ring) | < 12 g assembled (target) | Scale measurement |
| COMF-05 | Edge and protrusion | No sharp PCB edges against skin | Design review + wear test 30 min |
| COMF-06 | Strap material | Hypoallergenic silicone or woven nylon | Supplier spec sheet |
| COMF-07 | IMU placement | Consistent orientation vs hand/wrist | Repeatable gesture recognition |

---

## 4. Skin contact and sweat

| Req ID | Requirement | Target |
|--------|-------------|--------|
| SKIN-01 | Enclosure IP rating (target) | IPX4 splash-resistant (wristband EVT) |
| SKIN-02 | No bare copper against skin | Coating or enclosure barrier |
| SKIN-03 | Cleanability | Wipeable surface; no liquid ingress ports (except USB-C service) |
| SKIN-04 | Sweat exposure | 2 h continuous wear without irritation in pilot (n≥10) |

---

## 5. Sizing and industrial design

| Req ID | Requirement | Note |
|--------|-------------|------|
| ID-01 | Wristband ID sketch | CAD/STL gate — not in repo yet |
| ID-02 | Ring ID sketch | After wristband EVT |
| ID-03 | LED/haptic actuator location | Visible/vibratory feedback without blocking IMU |
| ID-04 | Branding | Original IP only; no third-party marks |

---

## 6. Battery and power

| Req ID | Requirement | Target |
|--------|-------------|--------|
| PWR-01 | Active play runtime | 3–6 h continuous gesture streaming |
| PWR-02 | Standby / connected idle | > 24 h (stretch goal) |
| PWR-03 | Battery chemistry | Single-cell LiPo or Li-ion pouch — certified cell preferred |
| PWR-04 | Capacity (wristband mule) | 150–300 mAh (TBD after power profiling) |
| PWR-05 | Capacity (ring target) | 80–150 mAh (TBD — may not meet runtime) |
| PWR-06 | `battery_pct` in SensorNotify | 0–100, updated ≥ 1/min |
| PWR-07 | Low battery warning | Host UI + optional haptic pattern |

---

## 7. Battery and charge safety

| Req ID | Requirement | Gate |
|--------|-------------|------|
| SAFE-01 | Protection IC | OVP, OCP, short-circuit on cell |
| SAFE-02 | Charging IC | CC/CV profile matched to cell |
| SAFE-03 | Charge temperature | NTC or PMIC temp guard — no charge < 0°C / > 45°C |
| SAFE-04 | USB-C or pogo charge | Rated for wearable current; no user-accessible bare pads |
| SAFE-05 | UN38.3 / cell certification | Required before pilot ship (> 10 units) |
| SAFE-06 | Safety review | **Not started** — required before EVT wear testing |

**Honest status:** Safety review not started. Do not ship pilot hardware without SAFE-01–SAFE-06 gates.

---

## 8. BLE and latency

| Req ID | Requirement | Target |
|--------|-------------|--------|
| BLE-01 | Protocol | Binary per `docs/EDGE_IO_PROTOCOL.md` |
| BLE-02 | Connection interval | 7.5–15 ms during play |
| BLE-03 | Gesture-to-host latency | p50 < 50 ms, p95 < 80 ms |
| BLE-04 | Notify drop rate | < 1% over 10 min session |
| BLE-05 | Reconnect time | < 5 s after walk in/out of range |
| BLE-06 | Pairing | User-initiated; no silent recording (SEC-01) |
| BLE-07 | Concurrent devices | 1 per player; 2+ for couch (v0.5 demo) |

---

## 9. Antenna and RF

| Req ID | Requirement | Note |
|--------|-------------|------|
| RF-01 | Antenna keep-out | Per Nordic layout guide |
| RF-02 | Metal enclosure | Not on ring v1 without RF engineering |
| RF-03 | BLE qualification | Required for commercial SKU (Track G8) |

---

## 10. Haptic feel

| Req ID | Requirement | Note |
|--------|-------------|------|
| HAP-01 | Driver | DRV2605L or equivalent (TBD on EVT) |
| HAP-02 | Host → device | HapticWrite 4-byte packet |
| HAP-03 | Intensity cap | Software cap 0–255; accessibility slider on host |
| HAP-04 | Acknowledge gesture | Optional short pulse on recognized gesture |
| HAP-05 | Never required for fairness | Output-only (PRD HAP-01) |

---

## 11. Serviceability

| Req ID | Requirement |
|--------|-------------|
| SVC-01 | Firmware update path (DFU/OTA) before pilot |
| SVC-02 | SWD or Tag-Connect for factory flash |
| SVC-03 | Strap replacement without tools (wristband) |
| SVC-04 | Battery replacement | **Not user-serviceable** on ring; wristband TBD |

---

## 12. Cost targets (planning — unverified)

| SKU | BOM target | MSRP target | Status |
|-----|------------|-------------|--------|
| Dev-board mule | $80–150 (bench) | N/A | BOM CSV exists |
| Wristband EVT (10u) | TBD | TBD | Requires sourcing |
| Ring pilot | TBD | TBD | After wristband DVT |

Use `TBD` in BOM until quotes received. Do not invent verified MPNs.

---

## 13. Manufacturing and certification risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Ring battery density | Runtime fail | Wristband first |
| BLE cert timeline | Retail delay | Plan 3–6 months cert path |
| IMU placement variance | Gesture false positives | EVT matrix + ML threshold tuning |
| Haptic LRA sourcing | Feel inconsistency | Qualify 2 actuators in DVT |
| Fake fab files | Credibility loss | Gates in `hardware/*/REQUIREMENTS.md` |

---

## 14. Related documents

- [WEARABLE_EVT_DVT_PVT_PLAN.md](./WEARABLE_EVT_DVT_PVT_PLAN.md)
- [WEARABLE_TEST_PLAN.md](./WEARABLE_TEST_PLAN.md)
- [EDGE_IO_PROTOCOL.md](./EDGE_IO_PROTOCOL.md)
- [HARDWARE_PROTOTYPE_PLAN.md](./HARDWARE_PROTOTYPE_PLAN.md)
- `hardware/wristband/REQUIREMENTS.md`
- `hardware/ring/REQUIREMENTS.md`
