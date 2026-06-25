# Ring Hardware Requirements

**Last updated:** 2026-06-24  
**Phase:** Target form factor — **after wristband EVT/DVT**  
**Honest status:** Planning and target BOM template only — **no KiCad, no Gerbers, no EVT**

---

## Scope

Electrical, mechanical, and RF requirements for the **Edge-IO ring** form factor. **Do not start ring PCB layout until wristband Gate E2 (EVT validation) passes.**

---

## Sequencing policy

| Prerequisite | Reason |
|--------------|--------|
| Wristband mule F7 latency pass | Protocol and gesture algorithms validated |
| Wristband EVT E2 pass | Power, BLE, haptic lessons learned |
| Wristband DVT yield data | Manufacturing risk understood |

Ring miniaturization amplifies battery and antenna constraints — skipping wristband path is **not approved**.

---

## Requirements gates

### Gate R0 — Planning (current)

| Item | Requirement | Status |
|------|-------------|--------|
| R0-1 | Target BOM template | Done — `bom/edgeio-ring-target-bom.csv` |
| R0-2 | README honesty | Done — no fab-ready claims |
| R0-3 | EVT validation plan template | Done — `test/evt-validation-plan.md` |
| R0-4 | Product requirements documented | Done — `docs/WEARABLE_PRODUCT_REQUIREMENTS.md` |

### Gate R1 — Electrical design ready (G2 ring)

| Item | Requirement | Status |
|------|-------------|--------|
| R1-1 | KiCad `edgeio-ring.kicad_*` | **Not started** |
| R1-2 | Ring-appropriate antenna (PCB or ceramic) | Not started |
| R1-3 | Cell fits ring ID with protection | Not started |
| R1-4 | IMU placement vs finger orientation study | Not started |
| R1-5 | Thermal model for charge in metal/ceramic enclosure | Not started |

### Gate R2 — Fabrication (G5 ring)

| Item | Requirement | Status |
|------|-------------|--------|
| R2-1 | Real Gerbers + drill | **Missing — do not fake** |
| R2-2 | Enclosure `edgeio-ring.step` | **Missing — do not fake** |
| R2-3 | Ring sizing kit definition (sizes 6–12) | Not started |
| R2-4 | RF performance sample (n≥5) | Not started |

### Gate R3 — EVT validation (G6 ring)

| Item | Requirement | Status |
|------|-------------|--------|
| R3-1 | 5 ring units assembled | Not started |
| R3-2 | Runtime honest report (may be < wristband) | Not started |
| R3-3 | Comfort 30 min wear (n≥10) | Not started |
| R3-4 | BLE range ≥ 3 m line-of-sight | Not started |

---

## Electrical requirements (target)

| ID | Requirement | Target / note |
|----|-------------|---------------|
| RG-E-01 | MCU | nRF52840 or size-optimized variant (TBD) |
| RG-E-02 | IMU | 6-axis — placement critical for finger gestures |
| RG-E-03 | Haptic | Mini LRA or ERM; DRV2605L or integrated driver (TBD) |
| RG-E-04 | Battery | 80–150 mAh class (runtime risk — document honestly) |
| RG-E-05 | Wireless | BLE 5.x peripheral |
| RG-E-06 | Charge | Wireless coil or contacts — safety rated |

**Runtime honesty:** Ring may **not** meet 3–6 h active play without breakthrough cell density. Document measured runtime; do not market wristband numbers for ring.

---

## Mechanical requirements (target)

| ID | Requirement | Target |
|----|-------------|--------|
| RG-M-01 | US ring sizes | 6–12 (pilot kit) |
| RG-M-02 | Weight | < 12 g assembled (target) |
| RG-M-03 | Inner diameter tolerance | ± 0.1 mm per size (TBD with CM) |
| RG-M-04 | Skin contact materials | Hypoallergenic interior finish |
| RG-M-05 | No sharp PCB edges | Enclosure encapsulation required |

---

## RF requirements

| ID | Requirement | Note |
|----|-------------|------|
| RG-RF-01 | Antenna keep-out | Metal ring band complicates — engineering spike required |
| RG-RF-02 | BLE qualification | FCC/CE before retail |
| RG-RF-03 | SAR / RF exposure | Assess per form factor |

---

## Cost and manufacturing risks

| Risk | Mitigation |
|------|------------|
| Small battery | Set honest runtime expectations |
| Ring sizing inventory | Start with adjustable dev ring or 3-size pilot |
| Assembly yield | Wristband DVT learnings first |
| RF detuning on finger | EVT matrix includes on-body vs bench |

---

## File expectations (when R1 starts)

```text
hardware/ring/
  edgeio-ring.kicad_pro
  edgeio-ring.kicad_sch
  edgeio-ring.kicad_pcb
  bom/edgeio-ring-bom.csv
  fab/gerbers.zip          # Real only
  enclosure/edgeio-ring.step # Real only
```

**Current repo:** README + target BOM + test templates only.

---

## Related documents

- [../wristband/REQUIREMENTS.md](../wristband/REQUIREMENTS.md)
- [../../docs/WEARABLE_EVT_DVT_PVT_PLAN.md](../../docs/WEARABLE_EVT_DVT_PVT_PLAN.md)
- [README.md](./README.md)
