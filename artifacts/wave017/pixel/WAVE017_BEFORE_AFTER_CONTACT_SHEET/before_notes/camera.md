# Wave017 Before / After — Camera

## Before

- Static `Camera2D`; stage `cameraProfile` unused for follow/zoom.

## After

- `battle_camera_controller.gd`: separation zoom, blast-zone bounds, deadzone lerp, optional impact zoom from combat feedback.
- Wired from `battle_scene.gd` for Ember Courtyard Golden Slice.
