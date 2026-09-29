"""animectl inspect runtime — model provenance from manifest + code contracts."""
from __future__ import annotations

import json
from pathlib import Path

from .git_truth import git_truth
from .result import AnimectlResult


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
    model_kind = "AUTHORED_GLB" if src.exists() else "MISSING"
    factory = (root / "apps/web/src/renderer-three/fighters/FighterModelFactory.ts").read_text(encoding="utf-8")
    wired = "createAuthoredOrGeneratedModel" in factory and "wrapAuthoredGlbAsParts" in factory
    payload = {
        "fighter_id": fighter,
        "body_variant": body,
        "story_form": story_form,
        "essence_count": essence,
        "prismatic_gray": essence == 6,
        "model_kind": model_kind if wired else "GENERATED_LOW_POLY",
        "model_path": entry.get("runtime_url") if src.exists() else "",
        "model_sha256": entry.get("sha256", ""),
        "model_exists": src.exists(),
        "model_loaded": False,  # static inspection — browser loads at runtime
        "fallback_used": not (src.exists() and wired),
        "animation_profile": f"authority:{fighter}",
        "current_slot": "idle_primary",
        "move_id": None,
        "animation_asset": f"content/fighters/{fighter}/animations/procedural/idle_primary.anim.json",
        "animation_fallback": False,
        "animation_binding": "ROOT_PROXY_PENDING_SKINNED_RIG",
        "material_profile": entry.get("production_status"),
        "vfx_profile": fighter,
        "runtime_wiring": "AUTHORED_GLB_PREFERRED" if wired else "LOW_POLY_ONLY",
    }
    res.data = payload
    res.add_check("MODEL_EXISTS", "PASS" if src.exists() else "FAIL", entry["source_path"])
    res.add_check("MODEL_KIND", "PASS" if payload["model_kind"] == "AUTHORED_GLB" else "FAIL", payload["model_kind"])
    res.add_check("FALLBACK_USED", "PASS" if payload["fallback_used"] is False else "FAIL", str(payload["fallback_used"]))
    res.add_check("RUNTIME_WIRING", "PASS" if wired else "FAIL", payload["runtime_wiring"])
    return res
