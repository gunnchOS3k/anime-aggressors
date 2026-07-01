# Balance — Vertical Slice (Milestone 4)

**Last updated:** 2026-06-30

Balance targets for the **four production-validated** fighters. Preview fighters use baseline procedural moves with light tuning only.

---

## Production roster

| Fighter | Archetype | Weight | Run | Air | Fall | Damage | Notes |
|---------|-----------|--------|-----|-----|------|--------|-------|
| Ember Vale | Rushdown Striker | 100 | 105 | 102 | 100 | 100 | Balanced pressure, reliable recovery |
| Rook Ironside | Armored Bruiser | 125 | 85 | 88 | 108 | 118 | Heavy hits, slow movement |
| Juno Spark | Speed Confirm | 82 | 118 | 122 | 102 | 92 | Fast confirms, fragile |
| Kaia Windrow | Aerial Spacer | 96 | 98 | 112 | 96 | 96 | Extended neutral special reach |

## Preview roster (balance-pending)

| Fighter | Status | Notes |
|---------|--------|-------|
| Nix Calder | Preview | Tank tuning stub |
| Orion Vell | Preview | Baseline gravity control |
| Vesper Nyx | Preview | Neutral special spawns projectile (zoner preview) |

---

## Move tuning highlights

- **Rook** — highest neutral/special damage and knockback among production cast.
- **Juno** — fastest startup on jabs and dash attack.
- **Kaia** — `special_attack` hitbox offset for spacing.
- **Vesper Nyx** (preview) — projectile on `special_attack` for zoning experiments.

---

## CPU difficulty

| Level | Behavior |
|-------|----------|
| 1 | Sparse attacks, rare shield/dodge |
| 2 | More specials, occasional shield |
| 3 | Higher attack/shield/dodge rates, approach jumps |

---

## Training

- `training-rules`: 50% damage/launch ratios, 99 stocks, no timer, `training-grid` stage.
- Dummy modes: idle, shield, jump, CPU Lv1 (keys 1–4).
