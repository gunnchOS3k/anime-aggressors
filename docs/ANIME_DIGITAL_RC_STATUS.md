# FULL PRODUCT Continuation IV — Anime Digital RC Ready

**Status:** Digital RC validation architecture + evidence path on Godot — **private/dev only**  
**Token:** `ANIME_DIGITAL_RC_READY`

## Tokens

| Token | Earned? | Notes |
|-------|---------|-------|
| `ANIME_DIGITAL_RC_READY` | **YES when** `playtest-evidence/digital_rc_validation.json` reports `token_earned: true` | Requires beta content + RC runner |
| Final store RC / public deploy | **NO** | Forbidden |
| Final art/audio complete | **NO** | See `content/missing_assets.json` |

## Validation coverage

| Gate | Evidence |
|------|----------|
| Godot headless load | `--quit-after 2` |
| Smoke | `tests/smoke_runner.gd` (includes beta + digital_rc suites) |
| Long AI sim | `cpu_battle_scene_eval.json` (7×7×5) + runner |
| Net fault injection | `NetworkSim.run_loopback_test` + private netplay stack |
| Replay verify | `ReplayStore.self_test` |
| Save migration | `GameState.migrate_save_if_needed` v1→v2 |
| Standalone package | `builds/digital-rc/` via `package-anime-standalone.mjs` |
| Clean install | `builds/digital-rc/CLEAN_INSTALL.md` |
| Performance thresholds | `playtest-evidence/digital_rc_performance.json` |

## Verify

```bash
node scripts/package-anime-standalone.mjs
node scripts/validate-anime-digital-rc.mjs
GODOT="/Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
"$GODOT" --headless --path game-godot -s res://tests/rc_validation_runner.gd
```

## Honesty

Does not claim public matchmaking, store packaging, or final painted/audio content.
