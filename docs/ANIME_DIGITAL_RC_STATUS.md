# FULL PRODUCT Continuation VI — Anime Digital RC Ready

**Status:** Digital RC validation + Path A package/runtime hardening on Godot — **private/dev only**  
**Token:** `ANIME_DIGITAL_RC_READY`  
**Path:** **A** (requires closed digital art/audio blockers)

## Tokens

| Token | Earned? | Notes |
|-------|---------|-------|
| `ANIME_DIGITAL_RC_READY` | **YES when** `playtest-evidence/digital_rc_validation.json` reports `token_earned: true` **and** art/audio closure has zero `blocks_token` | Requires beta content + RC runner |
| Final store RC / public deploy | **NO** | Forbidden |
| Painted remasters | **NO** | Optional future; not required for digital RC |

## Validation coverage

| Gate | Evidence |
|------|----------|
| Art/audio closure | `scripts/validate-anime-digital-art-audio-closure.mjs` |
| Godot headless load | `--quit-after 2` |
| Smoke | `tests/smoke_runner.gd` (includes beta + digital_rc suites) |
| Long AI sim | `cpu_battle_scene_eval.json` (7×7×5) + runner |
| Net fault injection | `NetworkSim.run_loopback_test` + private netplay stack |
| Replay verify | `ReplayStore.self_test` |
| Save migration | `GameState.migrate_save_if_needed` v1→v2 |
| Corrupted profile | `GameState.recover_corrupted_profile` |
| Content/version hash | `ContentIntegrity` + anti-tamper build id |
| Controller disconnect | `ControllerWatchdog` |
| Update/rollback | `scripts/digital-rc-update-rollback.mjs` |
| Credits / crash / splash / icon | scenes + `project.godot` boot splash |
| Standalone package | `builds/digital-rc/` includes Path A assets |
| Clean install | `builds/digital-rc/CLEAN_INSTALL.md` |
| Performance thresholds | `playtest-evidence/digital_rc_performance.json` |

## Verify

```bash
node scripts/validate-anime-digital-art-audio-closure.mjs
node scripts/package-anime-standalone.mjs
node scripts/validate-anime-digital-rc.mjs
GODOT="/Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
"$GODOT" --headless --path game-godot -s res://tests/rc_validation_runner.gd
```

## Honesty

Does not claim public matchmaking, store packaging, or painted remasters.
