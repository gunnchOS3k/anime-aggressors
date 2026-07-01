# Engine Strategy

## Decision

| Layer | Role |
|-------|------|
| **TypeScript** | Launcher, GitHub Pages shell, career/meta UI, docs, playtest routing — **not** the main fighting runtime |
| **Godot 4** | **Public web-playable runtime** — browser export, GitHub Pages, playtest validation |
| **Blender** | **Source-of-truth** for models, rigs, animation clips, export files |
| **Unreal Engine** | **R&D track** — high-fidelity anime combat, Niagara VFX, Control Rig, cinematic camera — **not** GitHub Pages runtime yet |

Do not delete Godot or the web app. Do not jump fully to Unreal without proving the workflow on one fighter.

## Decision matrix

| Requirement | TypeScript/Three | Godot | Unreal |
|-------------|------------------|-------|--------|
| GitHub Pages browser play | Strong shell, weak combat | **Best immediate option** | Not immediate |
| Fighting animation | Weak if hand-built | Medium — **needs authored assets** | Strong |
| Anime VFX | Medium | Medium | **Strong** |
| Cinematic camera | Medium | Medium | **Strong** |
| Rapid web deployment | **Strong** | Good | Weak |
| Native / Steam-quality future | Medium | Good | **Strong** |
| Team learning cost | Low/medium | Medium | High |

## Godot role

- Ship playable builds to `https://gunnchos3k.github.io/anime-aggressors/#/godot`
- Import `.glb` fighters with `AnimationLibrary` + socket maps
- Validate choreography, hitboxes, and product gates in CI

## Unreal role

- Look-dev for aura, hit impact, Sequencer moments
- Produce **reference** that Art/Animation/VFX directors bring back into Godot
- Optional future premium PC runtime after M8+ evaluation

## Blender role

- Every fighter: `.blend` → export `.glb` (Godot) / `.fbx` (Unreal)
- Named bones/sockets match `FighterSocketMap.gd`
- No ripped or copyrighted assets
