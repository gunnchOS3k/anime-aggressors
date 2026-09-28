# Rook Heavy — Authored Brief

Acting objective: **Rook commits his whole body to one crushing blow.**

## Required phases
settle → anticipation → weight transfer → acceleration → contact → hitstop hold → overshoot → follow-through → recovery

## Visual requirements
- pelvis drives motion
- planted rear foot
- shoulder/chest mass visible
- fist/forearm readable
- contact silhouette works in still
- visual body motion can exaggerate the collision rig
- no generic boxing punch
- original choreography only — no stolen/copied motion from another game

## Gameplay constraints (from `game-godot/data/moves/rook-ironside.json` → `heavy_attack`)
- startup_frames: **8**
- active_frames: **4**
- recovery_frames: **18**
- contact_frame: **10**
- contact_socket: **hand_r**
- hitstop_frames (feedback): **8**
- no gameplay root motion
- if acting is late, **do not** move the hitbox; flag `animation_late_vs_frame_data`

Frame range for the working file: 1–30.
Active window: 9–12.
