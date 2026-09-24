# Authored Animation Production Program — combined status

Draft PR #106. Do not merge. Not final authored animation. Cursor stop: tooling / artist files / briefs / review paths / spectacle code.

## Sequencing

1. Orchestrator (Prompt 4) — sequencing authority, one draft PR
2. Lane 1 — Production infrastructure (Prompt 1)
3. Lane 2 — Spectacle systems in parallel (Prompt 3; no authored motion)
4. Lane 3 — Golden Slice prep after Rook/Nix masters existed (Prompt 2)
5. STOP — no roster authoring, no HUMAN_* true

## Lane 1 A–Z

| | |
|---|---|
| A current head | see git after this commit; start was `56711f2438fb18fa5018611d35c429d8816ff785` |
| B LFS | git-lfs 3.7.1 installed; `*.blend` in `.gitattributes`; remote `AccessUpload=none`; `BLENDER_SOURCE_STORAGE_SETUP_REQUIRED=true`; masters generated locally, gitignored |
| C Blender | `ANIMATION_PRODUCTION_BLENDER_VERSION=3.3.1`; 4.5 LTS not installed; `docs/animation/BLENDER_VERSION_QUALIFICATION.md` |
| D master sources | seven `{id}_animation_master.blend` local (proxy mesh, control rig, empty WIP actions + markers) |
| E mesh matrix | `docs/animation/REAL_MESH_BINDING_MATRIX.md` — procedural runtime meshes; proxy cylinder in masters |
| F deformation | `docs/animation/DEFORMATION_AUDIT_ROSTER.md` — shoulder/hip `HUMAN_WEIGHT_PAINT_REQUIRED` |
| G control rig | `aa_control_rig.py` operators listed in `RIG_CONTROL_MAP.md` |
| H export | `python3 tools/authored_animation/export_action.py --fighter rook-ironside --action heavy` (empty slot → status MISSING, Godot import true) |
| I preview | `npm run anim:preview -- --fighter rook-ironside --action heavy` → `AuthoredAnimPreview.tscn` |
| J provenance | required sidecar schema; automation cannot write `AUTHORED_APPROVED` |
| K 98 board | `WAVE_A_PRODUCTION_98.json` + `docs/animation/WAVE_A_PRODUCTION_BOARD.md` — 0 complete |
| L review UI | `tools/animation_review/index.html` |
| M viewport renders | `npm run anim:render-review` placeholders labeled NOT TARGET QUALITY |
| N–T fighter readiness | all seven READY_TO_ANIMATE_PROXY; not real-mesh bound |
| U start guide | `docs/animation/ANIMATOR_START_HERE.md` |
| V audition | `docs/animation/ANIMATOR_AUDITION.md` — five shots only |
| W CI | `.github/workflows/authored-animation-production.yml` |
| X remaining human | LFS auth; weight paint; pose-bible stills; Golden Slice acting; Pixel review |
| Y gates | all HUMAN_* / MERGE / FINAL false |
| Z next | human animator opens Rook master and authors Golden Slice |

## Lane 2 A–Z

| | |
|---|---|
| B state machine | NONE→…→RECOVER, deadlock test PASS |
| C schema | `game-godot/data/combat/clash_eligibility.json` |
| D eligibility | lights/ordinary melee cannot clash |
| E resolution tests | deterministic, no mash, Godot asserts PASS |
| F–J presets | rook_orion, juno_kaia, ember_nix, vesper_ember, nix_rook |
| K camera | `clash_camera.gd` + per-class cinematic shots |
| L environment | bounded pulses, no collision mutate |
| M audio | `clash_audio_mixer.gd` original placeholders |
| N acting hooks | clash_start/lock/push/losing/winning/break — WIP fallback |
| O Clash Lab | Training Impact Lab → Open Aura Clash Lab |
| P/Q handoffs | `docs/vfx/AURA_CLASH_VFX_HANDOFF.md`, `docs/audio/COMBAT_CLASH_AUDIO_HANDOFF.md` |
| R Pixel perf | schema only; `PIXEL_*_PASS=false` |
| S a11y | `spectacle_a11y.gd` — gameplay identical |
| T tests | VXP3 Godot asserts PASS |
| U evidence | labeled SYSTEM/VFX PLACEHOLDER — AUTHORED ACTING PENDING |
| V AURA_CLASH_SYSTEM_PASS | true (architecture) |
| W HUMAN_AURA_CLASH_PASS | false |
| X HUMAN_COMBAT_FEEL_PASS | false |
| Y MERGE_AUTHORIZED | false |
| Z next artist | author clash pair acting after Golden Slice |

## Lane 3 A–O

| | |
|---|---|
| A pose-bible paths | `art_source/animation/fighters/<id>/pose_bible/<id>_PRODUCTION_SHEET.md` |
| B Rook heavy brief | `docs/animation/briefs/ROOK_HEAVY_AUTHORED_BRIEF.md` (startup 8 / active 4 / recovery 18 / contact 10) |
| C Nix hurt brief | `docs/animation/briefs/NIX_HURT_HEAVY_AUTHORED_BRIEF.md` |
| D charge briefs | Rook + Nix charged idle |
| E working sources | Rook/Nix masters with empty slots + real markers |
| F markers | from `game-godot/data/moves/rook-ironside.json` `heavy_attack` |
| G combined preview | AuthoredAnimPreview + Training Golden Slice sync |
| H review toggles | KB / hitstop / VFX / cam / audio / speeds / silhouette / skeleton / collision |
| I submit-check | `npm run anim:submit-check` |
| J review-render packet | placeholders, not quality |
| K roster templates | Ember/Juno/Kaia/Orion/Vesper sheets |
| L direction board | `docs/animation/ROSTER_ANIMATION_DIRECTION.md` |
| M human work | author the five audition / Golden Slice clips |
| N human gates | false |
| O merge authorized | false |
