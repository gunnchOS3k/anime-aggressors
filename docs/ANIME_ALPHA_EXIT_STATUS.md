# FULL PRODUCT Continuation III — Anime Aggressors Alpha Exit (Godot path)

**Status:** Alpha-exit **digital systems complete** on private/loopback + real BattleScene CPU eval path — **NOT Beta**, **NOT RC**, **NOT content-complete**  
**Branch:** `cursor/full-product-anime-alpha-exit` (from `origin/main` @ #66 / `436af24`)  
**Base:** merged #66 (tutorial, Items/Hazards, aura hooks, online scaffold, abbreviated CPU matrix)

## Tokens

| Token | Earned? | Evidence |
|-------|---------|----------|
| `ANIME_PRIVATE_NETPLAY_DIGITAL_PASS` | **YES** | `playtest-evidence/private_netplay_digital_pass.json` + smoke `anime_alpha_exit` |
| `ANIME_COMPETITIVE_AI_DIGITAL_VALIDATED` | **YES** | `playtest-evidence/cpu_battle_scene_eval.json` (245 = 7×7×5 real BattleScene matches) |
| Beta / RC | **NO** | Forbidden |
| Content-complete | **NO** | Art marked below |

## What shipped (this continuation)

### 1. Real private netplay stack (host / loopback)
- Host-authoritative private room + guest join
- DEV in-process matchmaking queue
- Signed input sync + rollback session (`rollback_session_gd.gd`)
- Latency / jitter / loss via `NetworkSim`
- Reconnect + disconnect/forfeit policy
- Spectator join
- Replay record + checksum verify
- Protocol v2 version compat + anti-tamper integrity
- Mode Select → **Private Netplay** UI (`OnlinePrivateScene`)
- **Scope:** loopback/private only — **no public deploy**

### 2. Full-length CPU eval on REAL BattleScene
- `battle_eval_mode` on `BattleScene` (skip countdown, both CPU, no results divert)
- Observation-only `CpuController` (no opponent private aura/move internals)
- Runner: `tests/battle_scene_cpu_eval_runner.gd` — full **7×7 × tiers 1–5** (245 matches)
- Evidence JSON with deadlock/diversity + `token_earned`

### 3. Local multi / settings / a11y / progression / save
- Ruleset: stocks, timer, CPU 1–5, P2 human/CPU, local 2P, damage ratio, team attack, presets save/load
- Settings: reduce motion, larger UI, device role, high contrast, colorblind markers, master volume, career W-L-M
- Persist: `user://aa_save.cfg`, `user://aa_rulesets.cfg`

### 4. Content / art
- Fighter + stage presentation remain proxy/greybox: **`REQUIRES_ART_PRODUCTION`**
- Systems continued without blocking on human art

## How to verify

```bash
GODOT="/Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"

# Quit-safe load
"$GODOT" --headless --path game-godot --quit-after 2

# Full smoke (includes anime_alpha_exit → netplay digital pass)
"$GODOT" --headless --path game-godot -s res://tests/smoke_runner.gd

# Real BattleScene CPU matrix (long; writes evidence JSON)
AA_CPU_EVAL_TIME_SCALE=28 AA_CPU_EVAL_TIERS=1,2,3,4,5 \
  "$GODOT" --headless --path game-godot -s res://tests/battle_scene_cpu_eval_runner.gd

npm test
```

## Remaining gaps (honest)

1. Final fighter art / animation — `REQUIRES_ART_PRODUCTION`
2. Stage art beyond greybox layouts — `REQUIRES_ART_PRODUCTION`
3. Public online / ranked matchmaking deploy (intentionally out of Alpha private scope)
4. Human playtest signoff for local multi feel
5. Beta/RC polish (audio bus depth, trailer, store pages) — **not claimed**

## IP

No copyrighted franchise assets. Original fighter/stage names only.
