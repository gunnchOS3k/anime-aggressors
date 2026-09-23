"""Export deform-only GLB. Control / IK / MCH bones stay out of the runtime file."""
from __future__ import annotations

from pathlib import Path
from typing import Any


def hide_non_deform(armature_obj: Any) -> list[str]:
    hidden = []
    for bone in armature_obj.data.bones:
        if not bone.use_deform or bone.name.startswith(("CTRL_", "IK_", "MCH_")):
            bone.hide = True
            hidden.append(bone.name)
    return hidden


def export_glb(bpy: Any, filepath: Path, action_name: str | None = None) -> None:
    filepath.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        obj.select_set(obj.type in {"ARMATURE", "MESH", "EMPTY"})
    kwargs = dict(
        filepath=str(filepath),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_nla_strips=True,
        export_skins=True,
        export_morph=False,
        export_apply=True,
        export_yup=True,
        export_extras=False,
        export_cameras=False,
        export_lights=False,
        export_def_bones=True,
        export_anim_single_armature=True,
    )
    if action_name:
        # Prefer the named action as the only export clip.
        kwargs["export_current_frame"] = False
    bpy.ops.export_scene.gltf(**kwargs)
