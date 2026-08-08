# FULL PRODUCT Wave D2 — Anime Aggressors toward Alpha exit (Godot path)

**Status:** SUPERSEDED for continuation by [ANIME_ALPHA_EXIT_STATUS.md](./ANIME_ALPHA_EXIT_STATUS.md) — Wave D2 was progress-only  
**Branch:** `cursor/full-product-wave-d2-anime-alpha-exit` (from `origin/main` incl. #65)  
**Token:** `WAVE_D2_ANIME_ALPHA_EXIT_PROGRESS` (progress only)

## Delivered this wave

| Item | Status | Notes |
|------|--------|-------|
| Tutorial + interactive first-run | DONE (Alpha depth) | Mode Select + boot first-run → Tutorial → guided battle checklist |
| Extra mode beyond Versus/Training/Arcade | DONE | Items / Hazards mode (`HazardItemRuntime` pulses + pickups) |
| Per-fighter aura/special runtime | DONE (audit) | `aura_special_runtime.gd` + fighter/hit_resolver hooks; 7 distinct tags proven |
| Online architecture scaffold | DONE (scaffold) | Protocol + session state + rollback/latency policy + network sim tests — **no public deploy** |
| CPU 7×7 batch matrix | DONE | Tiers 1/3/5, deadlock + diversity metrics → `playtest-evidence/cpu_batch_matrix.json` |
| Godot headless smoke | REQUIRED green | `smoke_runner` includes `wave_d2_alpha_exit` |

## Honest remaining Alpha-exit gaps

1. Final fighter art / animation (still proxy; `REQUIRES_ART_PRODUCTION`).
2. Stage art beyond greybox layouts.
3. Public / private online lobby **implementation** (scaffold only — no deploy, no real sockets in product path).
4. Spectator UX + ranked/unranked matchmaking (not started).
5. Full-length competitive CPU eval on real BattleScene matches (matrix is abbreviated sim).
6. Local multi ruleset polish + playtest signoff.
7. Content-complete / RC claims remain **forbidden**.

## How to verify

```bash
Godot --headless --path game-godot --quit-after 2
Godot --headless --path game-godot -s res://tests/smoke_runner.gd
Godot --headless --path game-godot -s res://tests/batch_match_harness_runner.gd
npm run validate:full-scope-production
npm test
```

## IP

No copyrighted franchise assets. Original fighter/stage names only.
