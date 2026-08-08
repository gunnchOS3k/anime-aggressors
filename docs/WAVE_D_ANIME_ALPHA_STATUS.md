# FULL PRODUCT Wave D — Anime Aggressors Alpha depth (Godot path)

**Status:** IN_PROGRESS toward Alpha — **NOT Alpha exit**, **NOT content-complete**, **NOT RC**  
**Branch focus:** ADR-GAME-AA-001 digital Alpha depth only (Godot).  
**Token:** `WAVE_D_ANIME_ALPHA_DEPTH` (feature progress, not exit)

## Delivered this wave

| Item | Status | Notes |
|------|--------|-------|
| 7 playable fighters | KEEP | Roster unchanged; still proxy art (`REQUIRES_ART_PRODUCTION`) |
| Aura uniqueness in combat scripts | DONE (Alpha depth) | `aura_identity.gd` applied from `fighter.gd` + `hit_resolver.gd` (not YAML-only) |
| Arcade ladder mode | DONE (minimum Alpha) | Mode Select → Arcade Ladder → 7 CPU bouts |
| Modes beyond Versus+Training | PARTIAL | Arcade added; online lobby still EXTERNAL / not this wave |
| Competitive CPU | HARDENED | Observation model, tiers 1–5, no `aura=100` forge, seeded RNG |
| Batch match harness | DONE | `batch_match_harness.gd` + headless runner (abbreviated, deterministic) |
| Stages toward 6 launch | DONE (greybox) | 5 competitive + 1 training; 3 new greybox layouts; art `REQUIRES_ART_PRODUCTION` |

## Honest Alpha exit gaps (still open)

1. Final fighter art / animation (proxy only).
2. Stage art beyond greybox.
3. Online private lobby + spectator (client/protocol).
4. Large-scale competitive CPU eval on full matches (harness is abbreviated).
5. Local multi ruleset variants polish / playtest signoff.
6. Content-complete / RC claims are **forbidden** until the above close.

## How to verify

```bash
# Quit-safe project load
Godot --headless --path game-godot --quit-after 2

# Full smoke (includes wave_d_alpha suite)
Godot --headless --path game-godot -s res://tests/smoke_runner.gd

# Batch CPU harness
Godot --headless --path game-godot -s res://tests/batch_match_harness_runner.gd

npm test
```

## IP

No copyrighted franchise assets. Original fighter/stage names only.
