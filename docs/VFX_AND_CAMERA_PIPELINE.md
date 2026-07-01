# VFX and Camera Pipeline

## VFX principles

- Spawn at **sockets** (hands, feet, weapon, aura_core) — never body center by default
- Element language per fighter spec (flame, volt, frost, etc.)
- Hit spark at `hit_spark_center` or contact socket
- Aura loop at `aura_core` during charge
- Attack trails follow active limb during move active frames

## Godot implementation

- `ElementalAuraSystem`, `HitSparkFactory`, `AttackTrailFactory`
- `VfxTimeline.gd` — frame-indexed spawn events per move

## Camera principles

- Frame both fighters with stage context
- Normal gameplay: moderate zoom, readable silhouettes
- Heavy hit: brief shake + zoom punch (`CameraImpactDirector`)
- Launch: directional impulse
- KO: stronger pause + zoom

## Unreal R&D reference

- Niagara aura and hit bursts
- Sequencer impact beats
- Lessons captured in `UNREAL_TO_GODOT_LESSONS.md`
