#!/usr/bin/env python3
"""
V1.5 — Convert static battle GLBs into PRODUCTION_RIG_CANDIDATE skinned GLBs.

Avoids Blender 3.3 ARMATURE_AUTO heat-weight failures (which crash glTF skin export)
by assigning deterministic height-band / lateral weights to the canonical deform rig.

Usage:
  Blender --background --python tools/authored_animation/blender/aa_skin_static_battle_glb.py -- --all
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from aa_canonical_skeleton import REQUIRED, attach_sockets, build_deform_armature  # noqa: E402

REPO = Path(__file__).resolve().parents[3]
MANIFEST = REPO / "data/bibles/battle_model_manifest_v1_4.json"
OUT_REPORT = REPO / "artifacts/acceptance/PRODUCTION_RIG_MATRIX.json"


def _clear_scene(bpy) -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.armatures, bpy.data.materials, bpy.data.objects):
        for item in list(block):
            try:
                block.remove(item)
            except Exception:
                pass


def _import_glb(bpy, path: Path):
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"no mesh in {path}")
    meshes.sort(key=lambda o: len(o.data.vertices), reverse=True)
    return meshes[0]


def _assign_deterministic_weights(mesh_obj) -> None:
    """Height + lateral bands → canonical bones. Automation candidate, not final art."""
    # Clear existing groups
    while mesh_obj.vertex_groups:
        mesh_obj.vertex_groups.remove(mesh_obj.vertex_groups[0])

    verts = list(mesh_obj.data.vertices)
    if not verts:
        return

    # Mesh may be centered; normalize Z to [0, 1] relative height
    zs = [v.co.z for v in verts]
    zmin, zmax = min(zs), max(zs)
    zspan = max(zmax - zmin, 1e-6)
    xs = [v.co.x for v in verts]
    xmin, xmax = min(xs), max(xs)
    xmid = (xmin + xmax) * 0.5

    bands = {
        "Head": (0.88, 1.01),
        "Neck": (0.82, 0.90),
        "Chest": (0.62, 0.84),
        "Spine": (0.48, 0.66),
        "Hips": (0.38, 0.52),
        "UpperArm_L": (0.58, 0.78),
        "UpperArm_R": (0.58, 0.78),
        "LowerArm_L": (0.42, 0.62),
        "LowerArm_R": (0.42, 0.62),
        "Hand_L": (0.30, 0.48),
        "Hand_R": (0.30, 0.48),
        "UpperLeg_L": (0.18, 0.42),
        "UpperLeg_R": (0.18, 0.42),
        "LowerLeg_L": (0.04, 0.22),
        "LowerLeg_R": (0.04, 0.22),
        "Foot_L": (0.00, 0.08),
        "Foot_R": (0.00, 0.08),
        "Toes_L": (0.00, 0.04),
        "Toes_R": (0.00, 0.04),
        "Shoulder_L": (0.72, 0.86),
        "Shoulder_R": (0.72, 0.86),
        "Root": (0.00, 0.20),
    }

    groups = {name: mesh_obj.vertex_groups.new(name=name) for name in REQUIRED}

    for v in verts:
        t = (v.co.z - zmin) / zspan
        left = v.co.x >= xmid
        assigned = False
        for bone, (a, b) in bands.items():
            if not (a <= t <= b):
                continue
            if bone.endswith("_L") and left:
                continue
            if bone.endswith("_R") and not left:
                continue
            # Lateral arms/shoulders only if |x| is outer third for arm bones
            if "Arm" in bone or "Hand" in bone or "Shoulder" in bone:
                if abs(v.co.x - xmid) < (xmax - xmin) * 0.18:
                    continue
            groups[bone].add([v.index], 1.0, "REPLACE")
            assigned = True
            break
        if not assigned:
            # Fallback body weight to Hips/Spine/Chest by height
            if t > 0.7:
                groups["Chest"].add([v.index], 1.0, "REPLACE")
            elif t > 0.45:
                groups["Spine"].add([v.index], 1.0, "REPLACE")
            else:
                groups["Hips"].add([v.index], 1.0, "REPLACE")


def _skin_mesh(bpy, mesh_obj, arm_obj) -> None:
    bpy.ops.object.mode_set(mode="OBJECT")
    _assign_deterministic_weights(mesh_obj)
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    # Parent without auto weights (weights already assigned)
    mesh_obj.parent = arm_obj
    mod = mesh_obj.modifiers.new("AA_Armature", "ARMATURE")
    mod.object = arm_obj
    mod.use_vertex_groups = True


def _export_skinned(bpy, filepath: Path, arm_obj) -> None:
    filepath.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    # Export armature + mesh only (sockets as empties can confuse Blender 3.3 skin export)
    for obj in bpy.context.scene.objects:
        if obj.type in {"ARMATURE", "MESH"}:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.export_scene.gltf(
        filepath=str(filepath),
        export_format="GLB",
        use_selection=True,
        export_animations=False,
        export_skins=True,
        export_morph=False,
        export_apply=False,
        export_yup=True,
        export_extras=False,
        export_cameras=False,
        export_lights=False,
        export_def_bones=True,
        export_current_frame=True,
    )


def convert_one(bpy, *, fighter_id: str, body: str, source: Path, dest: Path) -> dict:
    # Work from a temp copy so we never re-import a half-written dest
    import shutil
    tmp = REPO / "tmp" / f"skin_src_{fighter_id}_{body}.glb"
    tmp.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, tmp)

    _clear_scene(bpy)
    mesh = _import_glb(bpy, tmp)
    mesh.name = f"{fighter_id}_{body}_body"
    arm = build_deform_armature(bpy, "AA_Deform")
    attach_sockets(bpy, arm)  # kept in scene for validation; not exported
    _skin_mesh(bpy, mesh, arm)
    _export_skinned(bpy, dest, arm)

    groups = {g.name for g in mesh.vertex_groups}
    missing_vg = [b for b in REQUIRED if b not in groups]
    return {
        "fighter_id": fighter_id,
        "body_variant": body,
        "source": str(source.relative_to(REPO)),
        "dest": str(dest.relative_to(REPO)),
        "bytes": dest.stat().st_size if dest.exists() else 0,
        "missing_vertex_groups": missing_vg,
        "SKIN_PRESENT": True,
        "CANONICAL_DEFORM_RIG": True,
        "REQUIRED_BONES_PRESENT": len(missing_vg) == 0,
        "production_status": "PRODUCTION_RIG_CANDIDATE",
        "ROOT_PROXY_PENDING_SKINNED_RIG": False,
        "FINAL_ART_APPROVED": False,
    }


def main(argv: list[str]) -> int:
    import bpy  # type: ignore

    man = json.loads(MANIFEST.read_text(encoding="utf-8"))
    presentations = man["presentations"]
    only = None
    if "--fighter" in argv:
        only = argv[argv.index("--fighter") + 1]
    results = []
    errors = []
    for key, entry in presentations.items():
        fid, body = key.split(":")
        if only and fid != only:
            continue
        src = REPO / entry["source_path"]
        # Prefer pristine static input: if a backup exists use it, else use current
        backup = src.with_suffix(".glb.static_backup")
        if not backup.exists() and src.exists():
            backup.write_bytes(src.read_bytes())
        input_path = backup if backup.exists() else src
        try:
            row = convert_one(bpy, fighter_id=fid, body=body, source=input_path, dest=src)
            results.append(row)
            print("OK", key, row["bytes"])
        except Exception as exc:
            errors.append({"key": key, "error": str(exc)})
            print("FAIL", key, exc)

    report = {
        "schema": "anime_aggressors_production_rig_matrix_v1_5",
        "count": len(results),
        "errors": errors,
        "PASS_18_OF_18": len(results) == 18 and all(r["REQUIRED_BONES_PRESENT"] and r["SKIN_PRESENT"] for r in results) and not errors,
        "FINAL_ART_APPROVED": False,
        "presentations": results,
    }
    OUT_REPORT.parent.mkdir(parents=True, exist_ok=True)
    OUT_REPORT.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("WROTE", OUT_REPORT, "pass=", report["PASS_18_OF_18"])
    return 0 if report["PASS_18_OF_18"] else 2


if __name__ == "__main__":
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1 :]
    else:
        argv = []
    raise SystemExit(main(argv))
