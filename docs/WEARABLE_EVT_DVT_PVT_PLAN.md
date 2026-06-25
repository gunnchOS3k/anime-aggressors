# Wearable EVT / DVT / PVT Plan

**Last updated:** 2026-06-24  
**Track:** G — Production ring/wristband hardware  
**Honest status:** Mule planning only — **not EVT, not DVT, not PVT**

---

## Phase definitions

| Phase | Units | Purpose | Exit |
|-------|-------|---------|------|
| **Mule** | 1–3 bench | Protocol, latency, gesture algorithms | F7 pass on dev board |
| **EVT** | 5–10 | Integrated PCB + enclosure alpha | EVT validation matrix |
| **DVT** | 50 | Design for manufacturing + yield | DFM sign-off |
| **PVT** | 200+ | Pilot production | Yield > 95%, cert path clear |

**Sequencing:** Mule (Track F) → **Wristband EVT** → Wristband DVT/PVT → Ring EVT (miniaturization).

---

## G milestones mapped to phases

| Milestone | Phase | Deliverable |
|-----------|-------|-------------|
| G0 | Pre-EVT | `WEARABLE_PRODUCT_REQUIREMENTS.md` |
| G1 | Pre-EVT | Electrical requirements in `hardware/*/REQUIREMENTS.md` |
| G2 | Pre-EVT | Schematic draft (KiCad) |
| G3 | Pre-EVT | PCB layout draft |
| G4 | Pre-DVT | DFM review checklist |
| G5 | EVT | Fabrication package (real Gerbers — no fakes) |
| G6 | EVT | Bring-up + validation matrix |
| G7 | DVT | Revision after 50-unit learnings |
| G8 | PVT | Pilot production readiness |

---

## EVT (Engineering Validation Test)

### Goals

- Prove integrated wristband PCB: power, BLE, IMU, haptics, charging.
- Measure latency, battery runtime, reconnect behavior on real wearers.
- Freeze electrical BOM for DVT (with approved alternates list).

### Entry criteria (all required)

- [ ] Track F7: mule latency p50 < 50 ms
- [ ] Track F3: binary BLE notifications on silicon
- [ ] Firmware binary protocol matches `EDGE_IO_PROTOCOL.md`
- [ ] SAFE-01–SAFE-03 safety schematic review complete
- [ ] KiCad project in repo (`hardware/wristband/` — **not started**)
- [ ] EVT BOM with sourcing status ≠ all TBD for critical parts

### EVT build package (G5 gate)

```text
hardware/wristband/
  edgeio-wristband.kicad_pro      # Gate — must exist
  edgeio-wristband.kicad_sch
  edgeio-wristband.kicad_pcb
  bom/evt-bom.csv
  fab/gerbers.zip                 # Gate — real only
  fab/drill.zip
  fab/pick-place.csv
  fab/assembly-drawing.pdf
  enclosure/wristband.step          # Gate — real only
  test/evt-validation-plan.md
```

**Current repo:** Checklists and mule BOM only. **Do not claim EVT package complete.**

### EVT exit criteria

- [ ] 5 assembled units power on and pair
- [ ] EVT validation matrix ≥ 90% pass (`hardware/wristband/test/evt-validation-plan.md`)
- [ ] 3 h active runtime on ≥ 3 units
- [ ] Gesture-to-host p50 < 50 ms on wrist
- [ ] No thermal hotspot > 45°C exterior during charge
- [ ] DFU flash successful on 3/3 units

---

## DVT (Design Validation Test)

### Goals

- Validate enclosure fit, strap durability, assembly process.
- 50-unit build with yield and test-time data.
- RF/BLE performance across sample lot.

### Entry criteria

- [ ] EVT exit complete
- [ ] Enclosure revision frozen (or change-control process)
- [ ] DFM feedback incorporated (G4)
- [ ] Alternate parts qualified in `bom/*-with-alternates.csv`

### DVT exit criteria

- [ ] Assembly yield ≥ 90% first-pass
- [ ] 2 h wear test n≥20 without skin irritation reports
- [ ] BLE drop rate < 1% (10 min play per unit, sample 10)
- [ ] Haptic intensity within spec across lot
- [ ] Costed BOM within target (documented)

---

## PVT (Production Validation Test)

### Goals

- Pilot line build at target volume (200+ units).
- Certification path engaged (FCC/CE BLE, battery transport if shipping).
- Firmware OTA process validated at scale.

### Entry criteria

- [ ] DVT exit complete
- [ ] Ring program: only start ring EVT if wristband DVT lessons captured
- [ ] UN38.3 / cell cert for shipping config
- [ ] Retail packaging and SKU defined

### PVT exit criteria

- [ ] Yield > 95%
- [ ] Field trial 50 users, crash/disconnect rate documented
- [ ] Support RMA process defined
- [ ] `RELEASE_CHECKLIST` hardware section signed

---

## Ring-specific path (after wristband DVT)

Ring EVT adds constraints:

| Constraint | Implication |
|------------|-------------|
| Smaller battery | May reduce runtime — document honest limits |
| Antenna in metal ring | RF engineering required; may delay G5 |
| Comfort | Sizes 6–12; more ID iterations |

See `hardware/ring/REQUIREMENTS.md`.

---

## File honesty policy

| Claim | Allowed when |
|-------|--------------|
| "EVT planned" | This doc + requirements exist |
| "EVT in progress" | G5 fab package uploaded + PO placed |
| "EVT complete" | G6 matrix signed |
| "Fabrication-ready" | Gerbers reviewed by CM |

**Never** commit placeholder Gerbers or fake STEP files.

---

## Related documents

- [WEARABLE_PRODUCT_REQUIREMENTS.md](./WEARABLE_PRODUCT_REQUIREMENTS.md)
- [WEARABLE_TEST_PLAN.md](./WEARABLE_TEST_PLAN.md)
- [HARDWARE_PROTOTYPE_PLAN.md](./HARDWARE_PROTOTYPE_PLAN.md)
- [ROADMAP_FULL_COMPLETION.md](./ROADMAP_FULL_COMPLETION.md) — Track G
