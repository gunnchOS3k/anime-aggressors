"""Runtime GLB export. Same skeleton/sockets/action IDs as v4."""
from __future__ import annotations

from pathlib import Path

from generated_art_v5 import GENERATOR, GENERATOR_REVISION, GENERATOR_VERSION


def export_glb(path: Path) -> None:
    import bpy
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        if obj.type in {"ARMATURE", "MESH", "EMPTY"} and not obj.name.startswith("AA_Ref"):
            obj.select_set(True)
            if obj.type == "ARMATURE":
                bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_nla_strips=True,
        export_skins=True,
        export_morph=True,
        export_apply=False,
        export_yup=True,
        export_cameras=False,
        export_lights=False,
        export_def_bones=True,
        export_anim_single_armature=True,
    )


def write_glb_import(path: Path, fid: str) -> None:
    if not path.is_file():
        return
    rel = f"res://content/fighters/{fid}/model/{path.name}"
    path.with_suffix(path.suffix + ".import").write_text(
        "\n".join(
            [
                "[remap]",
                "",
                'importer="scene"',
                "importer_version=1",
                'type="PackedScene"',
                "",
                "[deps]",
                "",
                f'source_file="{rel}"',
                "",
                "[params]",
                "",
                'nodes/root_type=""',
                "meshes/generate_lods=true",
                "skins/use_named_skins=true",
                "animation/import=true",
                "animation/fps=60",
                "gltf/naming_version=2",
                "",
            ]
        )
        + "\n",
        encoding="utf-8",
    )


def report_payload(fid: str, out_blend: Path, out_glb: Path, geom: dict) -> dict:
    return {
        "fighter": fid,
        "status": "GENERATED_PRODUCTION_ART",
        "generator": GENERATOR,
        "generator_version": GENERATOR_VERSION,
        "generator_revision": GENERATOR_REVISION,
        "blend": str(out_blend),
        "glb": str(out_glb),
        "human_authored": False,
        "future_human_replaceable": True,
        "construction": "profile_loft_no_voxel_remesh",
        "geometry": geom,
    }
