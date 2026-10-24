# Cursor combat handoff — 2026-10-24

Official V1 and RC2 stay false. Human art, gameplay feel, and console acceptance stay false. Procedural clips are not original production art. This note does not fix the arm fold visual.

Author credit for the integrated gameplay commits remains Edmund Gunn, Jr. <egunnjr@gunnchos.com>. Cherry-picks kept that authorship. Two PartyLink conflicts kept the newer posted-frame behavior, then kept grab as the posted semantic bit (`a0e6b660`) instead of the earlier forced `grab: false`.

## Shield and parry event contract

State ids: `shield_start`, `shield_hold`, `shield_hit`, `shield_stun`, `shield_break`, `parry`.

Events: `shield_start`, `shield_hold`, `shield_hit`, `shield_stun`, `shield_break`, `parry`, `parry_fail`, `hit_damage_applied`, `hit_damage_zero`.

Transitions owned by Cursor rules:

- guard press on the ground enters `shield_start`, then `shield_hold`
- contact inside the existing 4-frame window emits `parry` and returns to `shield_hold`
- contact outside that window emits `parry_fail`, then `shield_hit`, then `shield_stun` while shield health remains
- health at or below 0 emits `shield_break`
- an unblocked confirmed hit emits `hit_damage_applied` and adds the move damage to `damage_percent`
- stocks do not change on hit; the existing blast/KO path still owns stock loss

Parry stun uses the existing constants: defender 2 frames, attacker 6 frames, rearm 24 frames. Keyboard and device joypad both use `p1_shield` / `p2_shield`. Shield stun uses the move `shield_stun_frames` when the move already has it (jab is 6). Otherwise the existing 0.25s fallback remains.

Aura tags, not art files:

| fighter | aura tag | bible |
| --- | --- | --- |
| ember-vale | burn_rushdown | docs/bibles/fighters/ember-vale.md |
| juno-spark | speed_chain | docs/bibles/fighters/juno-spark.md |
| kaia-windrow | wind_drift | docs/bibles/fighters/kaia-windrow.md |
| rook-ironside | armor_quake | docs/bibles/fighters/rook-ironside.md |
| nix-calder | freeze_control | docs/bibles/fighters/nix-calder.md |
| orion-vell | gravity_pull | docs/bibles/fighters/orion-vell.md |
| vesper-nyx | phase_mark | docs/bibles/fighters/vesper-nyx.md |
| yin | cosmic_reduction | docs/bibles/fighters/yin.md |
| yang | cosmic_definition | docs/bibles/fighters/yang.md |

Codex owns VFX and the shield/parry clips for those event names. Cursor does not edit that tree.

## Grab, throw, and arm fold

Gameplay owners:

- `grab_event` results: `attempt`, `success`, `whiff`, `throw`, `mash_escape`, `released`
- `HitResolver.resolve` owns throw-release contact and damage
- `elemental_grab_throw_presentation.gd` only observes `grab_event`; it does not resolve combat
- BattleScene playback follows the fighter state. It does not own the arm rig

The arm fold-in defect stays with Codex. This branch does not claim that visual defect is fixed.
