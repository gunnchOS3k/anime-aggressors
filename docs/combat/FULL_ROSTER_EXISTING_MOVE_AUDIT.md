# Full Roster Existing Move Audit

Rule: **existing documented intent wins.** Presentation labels do not rename gameplay IDs or change CombatMath.

Parent candidate models: KayKit CC0 `HUMAN_CANDIDATE` 7/7 from PR #109 (`3447c91d`). Not `HUMAN_APPROVED`.

Facing root cause before this pass:
- 2D `scale.x` flip plus camera-lean yaw (`rotation_degrees.y = -8 + lean*40`) could leave the mesh attacking away from the opponent
- Throw/victory tweens could exceed a presentation yaw bound
- Projectiles used live `facing` instead of attack-start lock

## Shared kit (all 7)

| Documented move | Runtime ID | Gameplay | Animation | VFX | Hit reaction | Facing | MVP gap |
|---|---|---|---|---|---|---|---|
| Jab 1/2/finisher | `jab_1` `jab_2` `jab_finisher` | Grounded string | Candidate clip or procedural | Element spark | Light | Follows stick unless locked | Shared spark language |
| Tilts / dash / airs | `forward_tilt` … `down_air` | Standard directional melee | Same | Element spark | Light/medium | Air facing stays | Shared boxes |
| Heavy | `heavy_attack` | High damage/KB; design-only bind | Heavy clip | `*_heavy` | Heavy | Must face target | Pose must read VFX-off |
| Neutral special | `neutral_special_projectile` | Projectile / confirm | Cast clip | `*_proj` | Medium | Socket toward attack lock | Was costume-shot, not signature |
| Side special | `side_special` | Forward field + self-move | Special clip | Spark | Light | Lock at start | Needs unique drive pose |
| Down special | `down_special` | Trap / slam / mix | Special clip | Spark | Light | Lock at start | Needs unique identity |
| Up special | `up_special_recovery` | Recovery | Movement clip | Spark | Light | Mostly up | Not in this specials review |
| Grab / throws | `grab` `throw_*` | Grab game | Throw tweens | `*_throw` | Medium | Throw dir | Yaw now bounded |
| Charge | `aura_charge` | Meter | Charge clip | Aura overlay | n/a | Idle facing | Was aura-only |
| Super | `aura_burst` | Meter dump | Burst clip | Super flash | Super | Lock at start | Shared arms-up risk |

## Per-fighter signature mapping

| Fighter | Special A label | ID | Special B label | ID | Super label | ID | Element |
|---|---|---|---|---|---|---|---|
| Ember | Ignition Rush | `side_special` (Cinder Rush Side, dx 180) | Cinder Burst | `neutral_special_projectile` (Flame Shot) | Cinder Rush | `aura_burst` | flame / burn |
| Rook | Guard Breaker | `side_special` (Faultline Breaker Side, armor 8) | Impact Slam | `down_special` (quake pulses) | Faultline Breaker | `aura_burst` | impact / quake |
| Juno | Volt Dash Chain | `side_special` (Flash Circuit Side, dx 260) | Arc Confirm | `neutral_special_projectile` (Volt Shot, chain stun) | Flash Circuit | `aura_burst` | volt / chain_stun |
| Kaia | Wind Ribbon Launcher | `neutral_special_projectile` (Gale Shot, curving blade) | Crosswind Cut | `side_special` (Spiral Current Side) | Spiral Current | `aura_burst` | gale / wind_drift |
| Nix | Freeze Lock | `side_special` (Glacier Lock Side) | Crystal Lance | `neutral_special_projectile` (Frost Shot, chill) | Glacier Lock | `aura_burst` | frost / chill_freeze |
| Orion | Orbit Pull | `side_special` (Orbit Collapse Side, pull field) | Gravity Crush | `down_special` (pull pulses) | Orbit Collapse | `aura_burst` | gravity / gravity_pull |
| Vesper | Phase Strike | `side_special` (Null Step Side, phase cancel) | Shadow Feint | `down_special` (void mark trap) | Null Step | `aura_burst` | void / void_mark |

No CombatMath / stock / knockback formula edits in this pass.
