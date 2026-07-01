# Full-Scope Implementation Audit (PR #46 baseline)

**Branch:** `product/full-scope-godot-implementation-pass`  
**Baseline:** PR #45 merged to `main`  
**Date:** 2026-07-01

Status vocabulary: **Implemented** | **Functional proxy** | **Needs implementation in this pass** | **Final-art blocked only** | **Future feature, not core gate**

---

## Menu and match flow

| System | Status | Notes |
|--------|--------|-------|
| Boot/menu flow | Implemented | `BootScene` → `MainMenuScene` |
| Mode select | Implemented | Versus / Training / Settings routes |
| Ruleset select | Implemented | Stocks, timer, CPU flag |
| Fighter select | Implemented | Full 7-fighter roster |
| Stage select | Implemented | Production stage list |
| Versus screen | Implemented | Ready gate before battle |
| Countdown | Implemented | Inputs locked until FIGHT |
| Battle loop | Implemented | Blast zones, stocks, results routing |
| Pause | Implemented | In-battle freeze overlay (Esc/B) |
| Results/rematch | Implemented | Winner display, rematch / select / menu |

## Combat and fighter systems

| System | Status | Notes |
|--------|--------|-------|
| Fighter movement | Implemented | Walk/run/dash/jump/double-jump/fall |
| Fighter states | Implemented | Full state set with enter/update/exit in `fighter_state_machine.gd` |
| Move runner (60 Hz) | Implemented | `BattleSim` + `tick_sim_frame` phases |
| Hit resolver | Implemented | Damage %, KB scaling, hitstun, launch, hitstop |
| Shield | Implemented | Hold, stun, drain, break |
| Dodge | Implemented | Startup/active/recovery + i-frames |
| Grab/throw | Implemented | Grab box, hold, throw damage/KB, whiff |
| Aura charge/burst | Implemented | Charge meter, ready, burst move + VFX hook |
| KO/stocks/respawn | Implemented | Blast KO, stock loss, respawn i-frames |
| Edge/ledge | Implemented | `edge_warning` near platform edge (teeter baseline) |

## Training, debug, AI, art

| System | Status | Notes |
|--------|--------|-------|
| Training mode | Implemented | Menu → configure → battle; F-key + on-screen help |
| Debug HUD | Implemented | State, move frame, phase, hitbox flag, hit log |
| Hitbox/hurtbox overlay | Implemented | F2/F6 toggles |
| CPU tiers | Implemented | Levels 1–4+ in `cpu_controller.gd` with archetype tags |
| Proxy animations | Functional proxy | `AnimationPlayer` clips labeled PROXY — NOT FINAL ART |
| Data loading | Implemented | `DataLoader` + JSON manifests |
| Full roster data | Implemented | 7 fighters normalized |
| Move manifests | Implemented | Frame fields + hitboxes per move |
| Validation scripts | Implemented | Hard gates in `validate-full-scope-production.mjs` |
| Final authored `.glb` | Final-art blocked only | Runtime uses ColorRect + proxy clips |

## Future feature (not core gate)

| System | Status | Notes |
|--------|--------|-------|
| Online rollback/netplay | Future feature | TS oracle only |
| Tournament-grade CPU tuning | Future feature | Tiers exist; balance pass later |
| Full ledge grab/hang/climb | Future feature | Edge teeter implemented instead |
| Signed external playtest | Future feature | Manual editor path documented |

---

## What was missing after PR #45 (addressed in PR #46)

- State machine was label-only for many states → enter/update/exit behavior added
- Move runner used loose physics tick → 60 Hz `BattleSim` accumulator
- Grab/throw moves existed in JSON but no gameplay path → `execute_throw`, `grab_hold`
- Aura burst was incomplete → full charge/ready/burst/recovery loop
- CPU was single minimal tick → `CpuController` L1–L4
- Training lacked stage/CPU config and full tool surface → menu + F1–F10
- No proxy `AnimationPlayer` hooks → `fighter_animator.gd`
- Validation allowed scaffolded core status → hard gates added
