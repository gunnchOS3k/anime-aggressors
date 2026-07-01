# Animation Choreography Pipeline

A move is **not** a hitbox alone. Each move is a authored package:

| Layer | Owner | File |
|-------|-------|------|
| Animation clip | Animation Director | Blender → GLB |
| Frame data | Combat Designer | `MoveChoreography` |
| Hitbox timeline | Engineer | `HitboxTimeline.gd` |
| VFX events | VFX Director | `VfxTimeline.gd` |
| Camera events | Game Designer | `CameraTimeline.gd` |
| Audio events | Audio (future) | `AudioTimeline.gd` |
| Orchestration | Engineer | `MoveTimeline.gd` |

## Move data contract

```gdscript
move_id, animation_name
startup_frames, active_frames, recovery_frames
hitbox_socket, vfx_socket
camera_event, audio_event
hitstop_frames, damage, base_knockback, knockback_growth, launch_angle_degrees
cancel_window, on_hit_follow_up
```

## Authoring flow

1. Animate clip in Blender (anticipation → contact → follow-through → recovery)
2. Export with move name matching `animation_name`
3. Register in `MoveChoreography.MOVES`
4. Wire timelines for hitbox active frames and VFX spawn frames
5. Playtest: limb motion, spark at socket, camera punch on heavy hits

## Forbidden

- Torso-only tilt with no limb motion
- Hitbox at body center while animation shows hand strike
- Silent fallback with no content gate failure
