# Authored Animation Source

**Authority:** `artist-authored source → export → Godot import → runtime mapping`

This tree is the **only** path that may be labeled authored animation.

Procedural Godot `.anim.json` clips under `game-godot/content/fighters/*/animations/procedural/` remain **fallback / blockout / regression fixture / test content**. They are not final authored animation.

Cursor / automation never sets `FINAL_AUTHORED_ANIMATION_PASS=true` because a script produced keys.

## Layout

```
art_source/animation/
  README.md                          this file
  CONTRACT.md                        source / rig / export / import contracts
  shared/
    deform_skeleton/                 canonical deform skeleton
    control_rig/                     Blender FK/IK tooling spec
    export/                          glTF export preset
    secondary_motion/                hair / cloth / cape bone contract
  fighters/<fighter-id>/
    README.md
    source/                          .blend (Git LFS when configured)
    pose_bible/                      still templates, not finished acting
    actions/<action_id>/             one folder per Wave A / later action
    export/                          GLB + sidecar provenance
    provenance.json                  fighter-level provenance rollup
  manifests/
    WAVE_A_98_ACTIONS.json           14 hero × 7 — defined, not fake-complete
    provenance_roster.json           AUTHORED_APPROVED | AUTHORED_WIP | PROCEDURAL_FALLBACK | MISSING
```

## Provenance labels (honest)

| Label | Meaning |
|-------|---------|
| `AUTHORED_APPROVED` | Human animator signed off. Automation never writes this. |
| `AUTHORED_WIP` | Real Blender/export path exists. Pose-block or in-progress acting. Not final. |
| `PROCEDURAL_FALLBACK` | Scripted Godot JSON / procedural GLB. Useful, not authored. |
| `MISSING` | Defined on the manifest, no clip of any kind claimed. |

## Human gates

`HUMAN_ANIMATION_QUALITY_PASS`, `HUMAN_COMBAT_FEEL_PASS`, `HUMAN_AURA_CLASH_PASS`, `HUMAN_CLIP_WORTHY_PASS`, `MERGE_AUTHORIZED` stay **false** until a human sets them.
