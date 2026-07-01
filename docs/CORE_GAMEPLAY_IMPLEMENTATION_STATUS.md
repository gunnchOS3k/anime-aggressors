# Core Gameplay Implementation Status

**Pass:** PR #46 — Godot gameplay implementation after PR #45 consolidation  
**Runtime:** Godot 4 — `game-godot/`  
**Last updated:** 2026-07-01

## PR #47 runtime hardening

Fixed gameplay-breaking paths discovered after PR #46 merge:

- Hit damage applies (single `can_hit_target` in resolver)
- Aura charge works with special+shield held
- Hurt states recover to idle/fall/hitstun
- P2 human controls mapped in `project.godot`
- F2/F6 debug overlays toggle without method errors

## PR #48 verification loop

- `scripts/aa-verify-project.mjs` — recursive npm + Godot CLI verification
- `game-godot/tests/smoke_*.gd` — headless load/instantiate checks
- `docs/GODOT_VERIFICATION_PLAN.md` — tier definitions
- `docs/GODOT_EDITOR_PLAYTEST_SIGNOFF.md` — human checklist (P1 until signed)

### Verification tiers (honest labels)

| Tier | Status |
|------|--------|
| Automated npm | Run `node scripts/aa-verify-project.mjs` |
| Godot CLI | Verified only if Godot installed on runner |
| Godot editor playtest | **manual_signoff_required** |
| Proxy functional | ColorRect + proxy AnimationPlayer |
| Final art | Blocked |

## Implemented (core gate — code paths)

- Boot → main menu → mode/ruleset/fighter/stage/versus → countdown → battle → pause → results
- Fighter state machine (all required states with behavior + debug label)
- 60 Hz move runner reading `game-godot/data/moves/`
- Hit resolver (damage %, weight KB, angle, hitstop, hitstun, launch, KO, respawn)
- Shield (block, stun, drain, break)
- Dodge (i-frames + recovery)
- Grab/throw functional path
- Aura charge, aura ready, aura burst
- Training mode from normal menu flow
- Debug HUD (state, move, frame, phase, hit log)
- CPU tiers 1–4 with archetype tags
- Edge warning / teeter baseline
- Validation hard gates

## Functional proxy

- Fighter visuals: `ColorRect` body + `AnimationPlayer` proxy clips
- Aura VFX: colored overlay rect
- SFX: hook points only (no final mix)
- Debug labels: `PROXY — NOT FINAL ART`

## Final-art blocked only

- Authored `.glb` fighter meshes
- Final animation clips from Blender pipeline
- Final SFX/VFX polish passes

## Not implemented (honest)

- Full ledge grab / hang / climb (edge teeter only)
- Online netplay / rollback in Godot runtime
- Tournament balance tuning pass
- Platform export hardening beyond existing docs

Source of truth JSON: `game-godot/data/gameplay/core_implementation_status.json`
