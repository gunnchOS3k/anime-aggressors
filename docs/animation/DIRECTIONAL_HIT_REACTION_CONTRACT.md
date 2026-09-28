# Directional Hit Reaction Contract

Families:
- `LIGHT_HIT`
- `HEAVY_HIT`
- `LAUNCH_HIT`
- `ELEMENTAL_SPECIAL_HIT`
- `SUPER_HIT`
- `CLASH_LOSE`

Given incoming force:
- head reacts along force
- chest/spine breaks on medium+
- pelvis counter-rotates on heavy/launch/super
- guard opens
- legs lose balance on launch/special/super
- launch clip starts only after a readable hurt pose (presentation). CombatMath knockback is unchanged.

Must work LEFT→RIGHT and RIGHT→LEFT.

Runtime: `game-godot/scripts/combat/directional_hit_reaction.gd`
Facing: `game-godot/scripts/combat/fighter_facing_contract.gd`

```
logical_facing = LEFT | RIGHT
presentation_forward = derived from logical_facing
attack_direction = locked at attack start unless the move explicitly turns
mesh_forward_axis = +Z
animation_root_yaw = presentation-only and bounded (±18°)
```
