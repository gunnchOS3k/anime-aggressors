# Release Notes — Milestone 5 Public Demo

**Version:** 0.1.0-demo  
**Date:** 2026-07-01

---

## What is playable

- **Play Demo** — instant Ember Vale vs Rook Ironside on Skyline Arena (defaults)
- **Fighter Select** — all 7 `DEFAULT_FIGHTERS`
- **Stage Select** — Training Grid, Skyline Arena, Neon Rooftops
- **Training Mode** — flat grid, dummy behaviors, damage/position reset
- **Custom Match Setup** — rules, stage, fighters, CPU option
- Local **2P** keyboard + dual gamepad auto-map

## Roster status

| Status | Fighters |
|--------|----------|
| Production-validated | Ember Vale, Rook Ironside, Juno Spark, Kaia Windrow |
| Preview / balance-pending | Nix Calder, Orion Vell, Vesper Nyx |

## Stage status

3 production stages with distinct layouts. Additional stages available in custom setup only.

## CPU / training

- CPU levels 1–3 in custom match setup (P2 bot toggle)
- Training dummy modes: idle, shield, jump, CPU Lv1

## Controls

- P1/P2 keyboard layouts in Controls screen
- H — in-battle controls overlay
- F1–F4 — debug tools (F2 hitboxes = developer only)

## Debug tools

- F2 hitboxes/hurtboxes
- F1 debug panel
- Labs: rollback, Edge-IO, Godot prototype, derby, flagline

## Limitations

- Web browser demo only — no native install
- No online multiplayer or ranked
- No story/career polish for public path
- Mobile touch not supported
- Placeholder audio/VFX

## Documentation added

- `MILESTONE_5_PUBLIC_DEMO_READINESS.md`
- `ENGINE_MIGRATION_DECISION.md` (no migration performed)
- `DEPLOYMENT.md`, `PUBLIC_DEMO_CHECKLIST.md`
- `KNOWN_ISSUES.md`, `TRAILER_CAPTURE_CHECKLIST.md`

## Next milestone

- Manual playtest sign-off
- Public deploy + feedback collection
- Optional engine spike per ENGINE_MIGRATION_DECISION.md
- M6+ polish TBD — not in this release
