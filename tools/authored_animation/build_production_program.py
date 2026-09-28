#!/usr/bin/env python3
"""Generate production board, review UI, pose-bible sheets, and animator docs.

Does not fabricate animation. All human/final gates stay false.
"""
from __future__ import annotations

import html
import json
from pathlib import Path

from aa_common import (
    ANIM,
    FIGHTERS,
    GODOT_AUTHORED,
    PRODUCTION_ACTIONS,
    ROOT,
    empty_provenance,
    fighter_dir,
    frame_window,
    load_json,
    write_json,
)

DOCS = ROOT / "docs" / "animation"
REVIEW = ROOT / "tools" / "animation_review"
BRIEFS = DOCS / "briefs"

POSE_FIELDS = (
    "line of action",
    "COM",
    "silhouette",
    "foot plant",
    "torso direction",
    "head direction",
    "primary limb",
    "secondary motion",
    "camera read",
    "exaggeration notes",
    "gameplay frame constraints",
)

ROOK_SLOTS = (
    "neutral idle",
    "personality idle",
    "walk passing",
    "run contact",
    "charge 0",
    "charge 50",
    "charge 100",
    "heavy anticipation",
    "heavy contact",
    "heavy follow-through",
    "heavy recovery",
    "aura anticipation",
    "aura contact",
    "super hero",
    "KO",
)

NIX_SLOTS = (
    "neutral idle",
    "walk passing",
    "run contact",
    "charge 0",
    "charge 50",
    "charge 100",
    "light hurt",
    "medium hurt",
    "heavy hurt peak",
    "frost stiffness",
    "launch",
    "tumble",
    "aura anticipation",
    "aura contact",
    "super hero",
    "KO",
)

ROSTER_SLOTS = (
    "neutral idle",
    "personality idle",
    "walk passing",
    "run contact",
    "charge 0 / 50 / 100",
    "heavy anticipation / contact / follow",
    "hurt heavy",
    "launch / tumble",
    "aura / super / KO",
)

DIRECTION = (
    ("rook-ironside", "weight", "low/forward", "wide", "slow", "long", "massive", "long", "compressed power"),
    ("nix-calder", "precision", "centered", "narrow", "held", "short-sharp", "crystalline", "controlled", "quiet tension"),
    ("ember-vale", "aggression", "forward", "medium-wide", "fast", "whip", "rush-through", "snappy", "heat swell"),
    ("juno-spark", "snap speed", "high/light", "narrow", "staccato", "pop", "reset", "fast", "volt coil"),
    ("kaia-windrow", "flow/air", "high/float", "long-line", "continuous", "carry", "arc", "loft", "spiral lift"),
    ("orion-vell", "orbit/control", "low/sink", "measured", "delayed", "set-then-pull", "gravity", "sink", "orbital compression"),
    ("vesper-nyx", "deception/phase", "offset", "asymmetric", "broken", "feint", "dissolve-snap", "phase", "void fold"),
)


def _sheet(fid: str, name: str, identity: str, slots: tuple[str, ...]) -> str:
    rows = []
    for slot in slots:
        rows.append(f"### {slot}\n")
        for field in POSE_FIELDS:
            rows.append(f"- **{field}:** _human animator fills_")
        rows.append("")
    return f"""# Pose Bible Production Sheet — {name}

**Status:** TEMPLATE / PREP ONLY. Not human-authored. `AUTHORED_POSE_BIBLE_PASS=false`.

- Fighter: `{fid}`
- Identity: {identity}
- Rest: A-pose, canonical deform skeleton
- Original choreography only. No franchise reproduction.

Current viewport / procedural stills, if generated, are labeled
`CURRENT_PROCEDURAL_REFERENCE — NOT TARGET QUALITY`.

{chr(10).join(rows)}

## Owner approval (checklist text only)

- [ ] Pose bible stills exist for every slot
- [ ] Silhouettes read at 128px
- [ ] Charge 0 / 50 / 100 change volume
- [ ] Human director signed — then and only then may `pose_bible_approved` become true
"""


def write_pose_bibles() -> list[str]:
    paths = []
    mapping = {
        "rook-ironside": ROOK_SLOTS,
        "nix-calder": NIX_SLOTS,
    }
    for fid, name, lane, ident in FIGHTERS:
        slots = mapping.get(fid, ROSTER_SLOTS)
        dest = fighter_dir(fid) / "pose_bible" / f"{fid}_PRODUCTION_SHEET.md"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(_sheet(fid, name, f"{lane} / {ident}", slots))
        paths.append(str(dest.relative_to(ROOT)))
    return paths


def write_board() -> None:
    rows = []
    for fid, name, _lane, ident in FIGHTERS:
        for action, runtime, brief in PRODUCTION_ACTIONS:
            win = frame_window(fid, action)
            glb = GODOT_AUTHORED / fid / f"{action}.glb"
            status = "AUTHORED_WIP" if glb.is_file() else "PROCEDURAL_FALLBACK"
            if not (GODOT_AUTHORED / fid / "pipeline_proof.glb").is_file() and not glb.is_file():
                status = "MISSING"
            row = {
                "fighter": fid,
                "display_name": name,
                "action": action,
                "runtime_clip": runtime,
                "assigned_owner": "unassigned",
                "pose_bible": False,
                "blockout": False,
                "first_pass": False,
                "polish": False,
                "export": glb.is_file(),
                "godot_import": False,
                "contact_sync": bool(win.get("contact_frame")),
                "pixel_tested": False,
                "human_approved": False,
                "status": status if glb.is_file() else "PROCEDURAL_FALLBACK",
                "notes": brief,
                "identity": ident,
                "frame_window": win,
                "authored_complete": False,
                "not_final_art": True,
            }
            rows.append(row)
            act_dir = fighter_dir(fid) / "actions" / action
            act_dir.mkdir(parents=True, exist_ok=True)
            if not (act_dir / "ACTION.json").is_file() or action not in {
                "idle",
                "walk",
                "run",
                "dash",
                "jump",
                "light",
                "medium",
                "heavy",
                "aura",
                "super",
                "hurt_heavy",
                "launch",
                "charge",
                "ko",
            }:
                write_json(
                    act_dir / "ACTION.json",
                    {
                        "fighter_id": fid,
                        "action_id": action,
                        "runtime_clip": runtime,
                        "status": "PROCEDURAL_FALLBACK",
                        "authored_source": None,
                        "export_glb": None,
                        "not_final_art": True,
                        "human_approved": False,
                        "brief": brief,
                        "contact_frame": win.get("contact_frame", 0),
                        "active_start": win.get("active_start", 0),
                        "active_end": win.get("active_end", 0),
                    },
                )
    manifest = {
        "schema": "aa_wave_a_production_98_v1",
        "wave": "A",
        "title": "Authored Wave A production board — defined, not complete",
        "fighter_count": 7,
        "actions_per_fighter": 14,
        "hero_action_count": 98,
        "authored_complete_count": 0,
        "not_final_art": True,
        "human_approved": False,
        "note": "Do not treat PROCEDURAL_FALLBACK as authored animation. Do not auto-fill 98 motions.",
        "hero_action_ids": [a[0] for a in PRODUCTION_ACTIONS],
        "actions": rows,
    }
    write_json(ANIM / "manifests" / "WAVE_A_PRODUCTION_98.json", manifest)
    # Keep first-pass 98 file truthful: still 0 complete.
    md = [
        "# Wave A Production Board",
        "",
        "98 actions. None human-approved. Do not treat this board as finished animation.",
        "",
        "| Fighter | Action | Owner | Pose bible | Blockout | First pass | Polish | Export | Godot | Contact sync | Pixel | Human | Status | Notes |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
    ]
    for row in rows:
        md.append(
            "| {fighter} | {action} | {assigned_owner} | {pose_bible} | {blockout} | {first_pass} | {polish} | {export} | {godot_import} | {contact_sync} | {pixel_tested} | {human_approved} | {status} | {notes} |".format(
                **row
            )
        )
    md.append("")
    md.append("`HUMAN_ANIMATION_QUALITY_PASS=false`. `MERGE_AUTHORIZED=false`.")
    DOCS.mkdir(parents=True, exist_ok=True)
    (DOCS / "WAVE_A_PRODUCTION_BOARD.md").write_text("\n".join(md) + "\n")


def write_review_ui() -> None:
    REVIEW.mkdir(parents=True, exist_ok=True)
    board = load_json(ANIM / "manifests" / "WAVE_A_PRODUCTION_98.json")
    tabs = []
    panels = []
    for fid, name, _lane, ident in FIGHTERS:
        rows = [a for a in board.get("actions", []) if a["fighter"] == fid]
        body = []
        for row in rows:
            body.append(
                f"<tr><td>{html.escape(row['action'])}</td><td>{html.escape(row['status'])}</td>"
                f"<td>{row['export']}</td><td>{row['human_approved']}</td>"
                f"<td>{html.escape(row['notes'])}</td></tr>"
            )
        tabs.append(f'<button class="tab" data-tab="{fid}">{html.escape(name)}</button>')
        panels.append(
            f'<section id="{fid}" class="panel">'
            f"<h2>{html.escape(name)}</h2><p>{html.escape(ident)}</p>"
            f"<p>Approved / reference pose slots live in <code>pose_bible/</code>. "
            "Current viewport renders, if present, are labeled "
            "<strong>CURRENT_PROCEDURAL_REFERENCE — NOT TARGET QUALITY</strong>.</p>"
            "<h3>Before / after</h3><p>Drop human stills next to procedural references. No database.</p>"
            "<table><thead><tr><th>Action</th><th>Status</th><th>Export</th><th>Human</th><th>Notes</th></tr></thead>"
            f"<tbody>{''.join(body)}</tbody></table>"
            "<h3>Owner approval (generated checklist text only)</h3>"
            "<ul><li>[ ] Pose bible</li><li>[ ] First pass</li><li>[ ] Pixel</li>"
            "<li>[ ] Human approved — owner initials, date</li></ul>"
            "</section>"
        )
    page = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>AA Pose-Bible Review</title>
<style>
body {{ font-family: ui-sans-serif, system-ui; background:#111; color:#eee; margin:24px; }}
.tab {{ margin-right:6px; padding:8px 12px; }}
.panel {{ display:none; }}
.panel.active {{ display:block; }}
table {{ border-collapse:collapse; width:100%; }}
td,th {{ border:1px solid #444; padding:6px; }}
</style></head><body>
<h1>Anime Aggressors — pose-bible review</h1>
<p>Repo-local. Consumes production-board JSON. Owner controls are checklist text only. No auth/db.</p>
<p><strong>HUMAN gates stay false until a human signs.</strong></p>
<nav>{''.join(tabs)}</nav>
{''.join(panels)}
<script>
const tabs=[...document.querySelectorAll('.tab')];
const panels=[...document.querySelectorAll('.panel')];
function show(id){{panels.forEach(p=>p.classList.toggle('active',p.id===id));}}
tabs.forEach(t=>t.onclick=()=>show(t.dataset.tab));
if(tabs[0]) show(tabs[0].dataset.tab);
</script>
</body></html>
"""
    (REVIEW / "index.html").write_text(page)
    (REVIEW / "README.md").write_text(
        "# Animation review UI\n\nOpen `index.html` locally. Regenerated by "
        "`python3 tools/authored_animation/build_production_program.py`.\n"
    )


def write_docs() -> None:
    BRIEFS.mkdir(parents=True, exist_ok=True)
    rook_heavy = frame_window("rook-ironside", "heavy")
    (BRIEFS / "ROOK_HEAVY_AUTHORED_BRIEF.md").write_text(
        f"""# Rook Heavy — Authored Brief

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
- startup_frames: **{rook_heavy.get('startup_frames')}**
- active_frames: **{rook_heavy.get('active_frames')}**
- recovery_frames: **{rook_heavy.get('recovery_frames')}**
- contact_frame: **{rook_heavy.get('contact_frame')}**
- contact_socket: **{rook_heavy.get('contact_socket')}**
- hitstop_frames (feedback): **{rook_heavy.get('hitstop_frames')}**
- no gameplay root motion
- if acting is late, **do not** move the hitbox; flag `animation_late_vs_frame_data`

Frame range for the working file: {rook_heavy.get('frame_start')}–{rook_heavy.get('frame_end')}.
Active window: {rook_heavy.get('active_start')}–{rook_heavy.get('active_end')}.
"""
    )
    (BRIEFS / "NIX_HURT_HEAVY_AUTHORED_BRIEF.md").write_text(
        """# Nix Hurt-Heavy — Authored Brief

Acting objective: **Impact visibly hurts before knockback moves him.**

## Required
- contact-side compression
- head/shoulder recoil
- chest/torso bend
- hip counterreaction
- guard break
- brief frost stiffness
- launch pose transition

The peak hurt pose must be readable with knockback temporarily disabled in preview.

Gameplay knockback / launch stay CombatMath. This clip is victim acting, not a new hitbox.

Rook `heavy_attack` victim family is `body_snap`; Nix identity still requires frost stiffness before launch.
Do not invent new frame data. Hitstop on Rook heavy feedback is 8 frames — use that hold for the pain beat.
"""
    )
    (BRIEFS / "ROOK_CHARGED_IDLE_BRIEF.md").write_text(
        """# Rook Charged Idle

Heavier. Wider. Planted. Compressed power. Ground-pressure secondary effects.
Charge 100 cannot be base idle + particles.
`aura_charge` in Rook moves has no attack windows (startup/active/recovery = 0). Presence loop is presentation-only.
"""
    )
    (BRIEFS / "NIX_CHARGED_IDLE_BRIEF.md").write_text(
        """# Nix Charged Idle

Colder. Quieter. Precise. Crystalline control. Subtle tension.
Charge 100 cannot be base idle + particles.
`aura_charge` windows are 0; do not invent combat frames.
"""
    )
    (DOCS / "ROSTER_ANIMATION_DIRECTION.md").write_text(
        """# Roster animation direction

| Fighter | Axis | COM | Pose width | Timing | Anticipation | Follow-through | Recovery | Charged |
|---|---|---|---|---|---|---|---|---|
"""
        + "\n".join(
            f"| {fid} | {axis} | {com} | {width} | {timing} | {anti} | {ft} | {rec} | {ch} |"
            for fid, axis, com, width, timing, anti, ft, rec, ch in DIRECTION
        )
        + "\n\nDo not recolor one animation across the roster.\n"
    )
    (DOCS / "GOLDEN_SLICE_ACCEPTANCE.md").write_text(
        """# Golden Slice acceptance rubric

Machine cannot approve. Human only.

## Rook heavy
readable anticipation · weight · clean contact · momentum · follow-through · personality · no mannequin feel

## Nix hurt
pain before launch · clear compression/snap · frost identity · readable silhouette · no generic recoil

## Pair
contact feels connected · VFX at contact · hitstop helps · sound sells mass · knockback follows body · camera amplifies, does not rescue

## Clip test
Would the owner post this clip publicly?

`HUMAN_ANIMATION_QUALITY_PASS=false` until a human answers yes.
`HUMAN_CLIP_WORTHY_PASS=false` until that same human says the clip is store-page worthy.
"""
    )
    (DOCS / "ANIMATOR_START_HERE.md").write_text(
        """# Animator start here

1. Clone `gunnchOS3k/anime-aggressors`, branch `vxp/vxp-3-combat-impact-nix-rook` (draft PR #106).
2. Install Git LFS. Ask the owner to enable GitHub LFS write (see `BLENDER_SOURCE_STORAGE.md`). Until then `BLENDER_SOURCE_STORAGE_SETUP_REQUIRED=true`.
3. Install **Blender 3.3.1** (`ANIMATION_PRODUCTION_BLENDER_VERSION=3.3.1`). See `BLENDER_VERSION_QUALIFICATION.md`.
4. Open `art_source/animation/fighters/rook-ironside/source/rook-ironside_animation_master.blend` (generate locally if LFS is blocked: `python3 tools/authored_animation/build_animation_masters.py`).
5. Select `AA_Deform`. Pose FK controls. Reset / mirror / markers live in `aa_control_rig.py`.
6. Animate **empty WIP slots** — do not treat pipeline_proof as acting.
7. Export: `python3 tools/authored_animation/export_action.py --fighter rook-ironside --action heavy`
8. Preview: `npm run anim:preview -- --fighter rook-ironside --action heavy`
9. Submit: `npm run anim:submit-check -- --fighter rook-ironside --action heavy`
10. Evidence stays `AUTHORED_WIP` until a human director approves.

RC1 `v1.0.0-rc.1` is immutable. Do not retag it.
"""
    )
    (DOCS / "RIG_CONTROL_MAP.md").write_text(
        """# Rig control map

Deform bones: Root, Hips, Spine, Chest, Neck, Head, Shoulder/UpperArm/LowerArm/Hand L+R, UpperLeg/LowerLeg/Foot/Toes L+R.

Controls (non-export): `CTRL_FK_*`, `CTRL_IK_Hand/Foot_*`, `CTRL_PV_Elbow_*`.

| Operator | Function |
|---|---|
| select_rig | isolate AA_Deform |
| reset_pose | clear transforms |
| mirror_pose | L↔R |
| copy_pose / paste_pose | selected bones |
| set_ik_fk | 0 = FK, 1 = IK |
| snap_fk_to_ik / snap_ik_to_fk | space matching |
| foot_roll | IK foot X rotation |
| scale_cheat | hand/foot scale |
| torso_squash | Spine/Chest scale |
| shoulder_overshoot | extra Z |
| create_named_action | new action + range |
| add_contact_marker | `AA_CONTACT` |
| add_gameplay_markers | active window + contact |
| set_stepped_preview | constant interpolation |
| export_pose_thumbnail | OpenGL still |

No proprietary add-on dependency.
"""
    )
    (DOCS / "EXPORT_CHECKLIST.md").write_text(
        """# Export checklist

1. Action name matches Wave A id (`heavy`, not `Heavy.001`).
2. Canonical deform bones present. Control bones `use_deform=false`.
3. Frame range matches gameplay metadata when the action is a move.
4. Markers: `AA_CONTACT`, `AA_ACTIVE_START`, `AA_ACTIVE_END`.
5. No authoritative root motion.
6. `python3 tools/authored_animation/export_action.py --fighter <id> --action <id>`
7. Sidecar written next to GLB. Status `AUTHORED_WIP`.
8. Godot import if `GODOT_BIN` is set.
9. Do not tick human approved.
"""
    )
    (DOCS / "CONTACT_FRAME_GUIDE.md").write_text(
        """# Contact frame guide

Contact is a **visual** frame that must sit inside or adjacent to the existing active window.

Rook heavy (`heavy_attack`): startup 8, active 4, recovery 18, `choreography.contact_frame=10`, socket `hand_r`.
Active window frames 9–12. Contact target: **10**.

If the punch *looks* late, keep frame 10 as contact and fix the acting. Do not slide CombatMath.

Nix hurt-heavy: peak compression on the shared hitstop (Rook heavy feedback hitstop = 8). Pain before launch.
"""
    )
    (DOCS / "ANIMATOR_AUDITION.md").write_text(
        """# Animator audition

Test **only** these five. Do not ask for the roster.

1. Rook idle
2. Rook walk
3. Rook heavy
4. Nix hurt-heavy reaction
5. Rook charged idle

## Rubric (human)
silhouette · weight · anticipation · contact · follow-through · pain/readability · personality · anime exaggeration · gameplay-frame synchronization · export hygiene

Submit via export + `npm run anim:submit-check`. Status stays `AUTHORED_WIP`.
"""
    )
    (DOCS / "BLENDER_SOURCE_STORAGE.md").write_text(
        """# Blender source storage — owner instructions

Local `git-lfs` 3.7.1 is installed. `.gitattributes` tracks `*.blend`.

This environment reports `AccessUpload=none` against `github.com/gunnchOS3k/anime-aggressors`.
**`BLENDER_SOURCE_STORAGE_SETUP_REQUIRED=true`.** Do not fake readiness.

## Owner steps
1. GitHub repo → Settings → Billing / Git LFS: enable the free LFS quota (do not buy paid storage unless you choose to).
2. `git lfs install` on the machine that will push.
3. Authenticate `gh auth login` / HTTPS or SSH with LFS transfer allowed.
4. Generate masters: `python3 tools/authored_animation/build_animation_masters.py`
5. Confirm pointer: `git lfs pointer --file art_source/animation/fighters/rook-ironside/source/rook-ironside_animation_master.blend`
6. Push a tiny sentinel only after auth works. Never commit a >100MB ordinary blob.
7. Until that push verifies, keep `.blend` gitignored (`art_source/animation/**/*.blend`).

Exported `pipeline_proof.glb` files stay in normal git (~89KB, original).
"""
    )
    (DOCS / "PIXEL_REVIEW_BUILD.md").write_text(
        """# Pixel review build

Do **not** build a review APK until genuine human-authored Golden Slice clips exist.

When they do:
- build a clearly labeled non-release APK
- `adb install -r`
- preserve RC1 `v1.0.0-rc.1`
- Training exposes clip provenance
- owner replays Golden Slice
"""
    )


def write_direction_and_mesh_docs() -> None:
    (DOCS / "REAL_MESH_BINDING_MATRIX.md").write_text(
        """# Real mesh binding matrix

Current fighter visuals are **procedural / proxy**, not final character art.

| Fighter | Runtime mesh | Topology | Materials | Skeleton binding | Blend shapes | Secondary | Authored source |
|---|---|---|---|---|---|---|---|
| ember-vale | `procedural_final/ember-vale.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| rook-ironside | `procedural_final/rook-ironside.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| juno-spark | `procedural_final/juno-spark.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| kaia-windrow | `procedural_final/kaia-windrow.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| nix-calder | `procedural_final/nix-calder.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| orion-vell | `procedural_final/orion-vell.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| vesper-nyx | `procedural_final/vesper-nyx.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |

Automatic binding of the procedural GLB onto the canonical deform skeleton is **not safe**
(different topology, auto-weights will break shoulders/hips).

`MESH_BINDING_NEEDS_HUMAN_WEIGHT_PAINT=true`

Authored proof GLBs use a skinned cylinder for import-path proof only.
"""
    )
    (DOCS / "DEFORMATION_AUDIT_ROSTER.md").write_text(
        """# Deformation audit — roster

Proxy cylinder + height-band weights. **Not production mesh.**

Tests requested: shoulders overhead, elbow 120°, wrist rotation, torso twist ±45°,
crouch, extreme lunge, hip flex, knee flex, airborne curl, heavy hurt bend, charged stance.

| Region | Ember | Rook | Juno | Kaia | Nix | Orion | Vesper |
|---|---|---|---|---|---|---|---|
| Shoulder | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED |
| Elbow | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX |
| Wrist | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX |
| Torso twist | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED |
| Hip / crouch / lunge | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED |
| Knee | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX | MINOR_WEIGHT_FIX |
| Airborne curl | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED |
| Heavy hurt bend | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED | HUMAN_WEIGHT_PAINT_REQUIRED |
| Charged stance | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED | CORRECTIVE_REQUIRED |

No final animation approval while shoulder/hip deformation is visibly broken.
Front/side/3Q stills are generated as review placeholders, not quality evidence.
"""
    )


def main() -> None:
    write_board()
    sheets = write_pose_bibles()
    write_review_ui()
    write_docs()
    write_direction_and_mesh_docs()
    print(json.dumps({"ok": True, "pose_sheets": sheets, "board": "98"}, indent=2))


if __name__ == "__main__":
    main()
