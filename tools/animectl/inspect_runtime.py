"""animectl inspect runtime — model provenance from manifest + code contracts."""
from __future__ import annotations

import json
import struct
from pathlib import Path

from .git_truth import git_truth
from .result import AnimectlResult


def _glb_skin_info(path: Path) -> dict:
    data = path.read_bytes()
    length, _ctype = struct.unpack_from("<I4s", data, 12)
    meta = json.loads(data[20 : 20 + length].decode())
    skins = meta.get("skins", [])
    nodes = meta.get("nodes", [])
    names = {n.get("name") for n in nodes if n.get("name")}
    required = {
        "Root",
        "Hips",
        "Spine",
        "Chest",
        "Neck",
        "Head",
        "Shoulder_L",
        "UpperArm_L",
        "LowerArm_L",
        "Hand_L",
        "Shoulder_R",
        "UpperArm_R",
        "LowerArm_R",
        "Hand_R",
        "UpperLeg_L",
        "LowerLeg_L",
        "Foot_L",
        "Toes_L",
        "UpperLeg_R",
        "LowerLeg_R",
        "Foot_R",
        "Toes_R",
    }
    missing = sorted(required - names)
    return {
        "skin_count": len(skins),
        "canonical_bone_count": len(required) - len(missing),
        "missing_canonical_bones": missing,
        "skeleton_name": "AA_Deform" if "Hips" in names else None,
    }


def run_inspect(
    root: Path,
    *,
    fighter: str,
    body: str,
    story_form: str = "NORMAL",
    essence: int = 0,
) -> AnimectlResult:
    gt = git_truth(root)
    res = AnimectlResult(command="inspect runtime", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    manifest_path = root / "data/bibles/battle_model_manifest_v1_4.json"
    if not manifest_path.exists():
        res.add_check("MANIFEST", "FAIL", "missing battle_model_manifest_v1_4.json")
        return res
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    key = f"{fighter}:{body}"
    entry = manifest.get("presentations", {}).get(key)
    if not entry:
        res.add_check("PRESENTATION", "FAIL", f"missing {key}")
        res.data["model_kind"] = "MISSING"
        return res
    src = root / entry["source_path"]
    skin = _glb_skin_info(src) if src.exists() else {"skin_count": 0, "canonical_bone_count": 0, "missing_canonical_bones": ["*"], "skeleton_name": None}
    model_kind = "AUTHORED_GLB" if src.exists() else "MISSING"
    factory = (root / "apps/web/src/renderer-three/fighters/FighterModelFactory.ts").read_text(encoding="utf-8")
    wired = "createAuthoredOrGeneratedModel" in factory and "wrapAuthoredGlbAsParts" in factory
    binding = entry.get("animation_binding") or ("PRODUCTION_RIG" if skin["skin_count"] else "ROOT_PROXY_PENDING_SKINNED_RIG")
    payload = {
        "fighter_id": fighter,
        "body_variant": body,
        "story_form": story_form,
        "essence_count": essence,
        "prismatic_gray": essence == 6,
        "gray": essence == 6,
        "model_kind": model_kind if wired else "GENERATED_LOW_POLY",
        "model_path": entry.get("runtime_url") if src.exists() else "",
        "model_sha256": entry.get("sha256", ""),
        "model_exists": src.exists(),
        "model_loaded": False,
        "fallback_used": not (src.exists() and wired and skin["skin_count"] > 0),
        "skin_count": skin["skin_count"],
        "skeleton_name": skin["skeleton_name"],
        "canonical_bone_count": skin["canonical_bone_count"],
        "missing_canonical_bones": skin["missing_canonical_bones"],
        "animation_binding": binding,
        "active_clip": "idle_primary",
        "animation_profile": f"authority:{fighter}",
        "current_slot": "idle_primary",
        "move_id": None,
        "animation_asset": f"content/fighters/{fighter}/animations/procedural/idle_primary.anim.json",
        "animation_fallback": False,
        "material_profile": entry.get("production_status"),
        "vfx_profile": fighter,
        "runtime_wiring": "PRODUCTION_RIG" if binding == "PRODUCTION_RIG" else "AUTHORED_GLB_PREFERRED",
    }
    res.data = payload
    res.add_check("MODEL_EXISTS", "PASS" if src.exists() else "FAIL", entry["source_path"])
    res.add_check("MODEL_KIND", "PASS" if payload["model_kind"] == "AUTHORED_GLB" else "FAIL", payload["model_kind"])
    res.add_check("SKIN_PRESENT", "PASS" if skin["skin_count"] > 0 else "FAIL", str(skin["skin_count"]))
    res.add_check("CANONICAL_BONES", "PASS" if not skin["missing_canonical_bones"] else "FAIL", str(skin["missing_canonical_bones"][:5]))
    res.add_check("ANIMATION_BINDING", "PASS" if binding == "PRODUCTION_RIG" else "FAIL", binding)
    res.add_check("FALLBACK_USED", "PASS" if payload["fallback_used"] is False else "FAIL", str(payload["fallback_used"]))
    return res
