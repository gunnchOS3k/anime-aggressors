# Animation Taste Rubric

Used with the Game Taste Gate for motion presentation and game feel.  
Automated tooling may flag failures; it must not assign Q5.

---

## Scoring bands (per clip / move)

| Band | Criteria |
|------|----------|
| **Fail (≤Q0–Q1)** | No visible skeletal change; stick/proxy only when model claimed; identical poses across distinct moves; frozen T-pose |
| **Proxy (Q1–Q2)** | Distinct motion; weight/timing approximate; silhouette OK at thumb distance; still reads as procedural / unfinished |
| **Directional (Q3 claim needs human)** | Clear anticipation, contact, recovery; lane grammar matches fighter fantasy; readable at play speed |
| **Polished (Q4–Q5 human only)** | Ship timing, secondary motion, juice sync; owner taste approved |

---

## Checklist (per fighter move class)

1. **Anticipation** — wind-up readable before active frames  
2. **Contact** — hit moment syncs with feedback (stop/flash/SFX)  
3. **Recovery** — not truncated or endlessly mushy  
4. **Distinctness** — move not a clone of another class on same fighter  
5. **Lane identity** — Ember heat lean ≠ Rook planted weight ≠ Juno snap, etc.  
6. **Hierarchy** — animation never relies on nameplate/UI to sell identity  

---

## Evidence

- Prefer Godot runtime renders / BattleScene captures over Blender-only stills.  
- Label source honestly in `artifacts/taste_gate/contact_sheet/manifest.json`.  
- Pixel evidence only when device campaign exists.

---

## Related

- `docs/quality/GAME_TASTE_GATE.md`  
- `docs/design/ROSTER_MOTION_IDENTITY_BIBLE.md`  
- `docs/design/GOLDEN_VERTICAL_SLICE.md`
