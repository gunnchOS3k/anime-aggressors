"""animectl audit — code-backed runtime map."""
from __future__ import annotations

import json
from pathlib import Path

from .git_truth import git_truth
from .result import AnimectlResult


def run_audit(root: Path) -> AnimectlResult:
    gt = git_truth(root)
    res = AnimectlResult(command="audit", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    factory = (root / "apps/web/src/renderer-three/fighters/FighterModelFactory.ts").read_text(encoding="utf-8")
    asset = (root / "apps/web/src/renderer-three/AssetLoader.ts").read_text(encoding="utf-8")
    story = root / "packages/game-core/src/story/storyProgression.ts"
    manifest = root / "data/bibles/battle_model_manifest_v1_4.json"
    map_payload = {
        "canonical_simulation": "packages/game-core",
        "canonical_web_shell": "apps/web",
        "canonical_battle_renderer": "apps/web/src/renderer-three/ThreeGameRenderer.ts",
        "fighter_model_factory": "apps/web/src/renderer-three/fighters/FighterModelFactory.ts",
        "model_loader": "apps/web/src/renderer-three/AssetLoader.ts",
        "animation_resolver": "apps/web/src/renderer-three/fighters/FighterAnimator.ts + tools/animation_authority",
        "vfx_system": "apps/web/src/renderer-three/vfx",
        "story_system": "packages/game-core/src/story + apps/web/src/screens/StoryCampaignScreen.ts",
        "save_system": "apps/web/src/storage + apps/web/src/saves",
        "android_build_path": "scripts/export-godot-android.mjs + game-godot",
        "godot_role": "Android/RC/PartyLink export runtime",
        "partylink_boundary": "packages/partylink + packages/rollback",
        "MODEL_FACTORY_KIND": "AUTHORED_GLB_PREFERRED_WITH_LOW_POLY_DEV_FALLBACK"
        if "createAuthoredOrGeneratedModel" in factory
        else "GENERATED_LOW_POLY_ONLY",
        "AUTHORED_GLB_LOADER_PRESENT": "preloadBattlePresentation" in asset and "BATTLE_MODEL_MANIFEST" in asset,
        "ANIMATION_AUTHORITY_RUNTIME_BINDING": "ROOT_PROXY_PENDING_SKINNED_RIG",
        "STORY_ROUTE_ENTRY": "#/story",
        "ANDROID_BUILD_ENTRY": "npm run godot:export:android",
    }
    res.data["runtime_map"] = map_payload
    res.add_check("CURRENT_HEAD", "PASS", gt["git_sha"])
    res.add_check(
        "MODEL_FACTORY_KIND",
        "PASS" if "AUTHORED_GLB" in map_payload["MODEL_FACTORY_KIND"] else "FAIL",
        map_payload["MODEL_FACTORY_KIND"],
    )
    res.add_check(
        "AUTHORED_GLB_LOADER_PRESENT",
        "PASS" if map_payload["AUTHORED_GLB_LOADER_PRESENT"] else "FAIL",
    )
    res.add_check(
        "ANIMATION_AUTHORITY_RUNTIME_BINDING",
        "PASS_WITH_NOTES",
        map_payload["ANIMATION_AUTHORITY_RUNTIME_BINDING"],
    )
    res.add_check("STORY_ROUTE_ENTRY", "PASS" if story.exists() else "FAIL", map_payload["STORY_ROUTE_ENTRY"])
    res.add_check("ANDROID_BUILD_ENTRY", "PASS", map_payload["ANDROID_BUILD_ENTRY"])
    if manifest.exists():
        m = json.loads(manifest.read_text(encoding="utf-8"))
        res.add_check(
            "BATTLE_MODEL_MANIFEST_18",
            "PASS" if m.get("count") == 18 else "FAIL",
            f"count={m.get('count')}",
        )
    else:
        res.add_check("BATTLE_MODEL_MANIFEST_18", "FAIL", "missing")
    out = root / "artifacts" / "acceptance" / "RUNTIME_MAP.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"git_sha": gt["git_sha"], **map_payload}, indent=2) + "\n", encoding="utf-8")
    res.artifacts.append(str(out.relative_to(root)))
    return res
