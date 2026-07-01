# Anime Aggressors — Source Assets

## Layout

```
assets/
  blender/     # editable .blend sources
  exports/     # engine-ready exports
  refs/        # moodboards, animation notes
```

## Rules

- **Blender `.blend` files are the editable source of truth.**
- **Godot** imports `.glb` / `.gltf` from `exports/godot/`.
- **Unreal** imports `.fbx` or `.glb` from `exports/unreal/`.
- Every fighter needs: model, rig, animations, material palette, sockets, VFX anchors.
- **No copyrighted characters, moves, sounds, or ripped assets.** Original or properly licensed only.

See `blender/README.md` and `exports/README.md`.
