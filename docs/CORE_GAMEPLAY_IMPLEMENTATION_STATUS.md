# Core Gameplay Implementation Status

**Pass:** PR #46 — Godot gameplay implementation after PR #45 consolidation  
**Runtime:** Godot 4 — `game-godot/`  
**Last updated:** 2026-07-01

## Implemented (core gate)

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
