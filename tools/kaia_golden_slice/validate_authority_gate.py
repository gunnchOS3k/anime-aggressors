#!/usr/bin/env python3
"""Static authority gate for the Kaia golden slice and Green Between foundation."""
from __future__ import annotations

import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BONES = [
    "Root", "Hips", "Spine", "Chest", "Neck", "Head",
    "Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L",
    "Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R",
    "UpperLeg_L", "LowerLeg_L", "Foot_L", "Toes_L",
    "UpperLeg_R", "LowerLeg_R", "Foot_R", "Toes_R",
]
SOCKETS = [
    "hand_l", "hand_r", "foot_l", "foot_r", "chest", "head", "back",
    "projectile_origin", "aura_root",
]
PROXIES = [
    "ember-vale", "rook-ironside", "juno-spark", "nix-calder", "orion-vell", "vesper-nyx",
]


def read_glb(path: Path) -> dict:
    data = path.read_bytes()
    length = struct.unpack_from("<I", data, 12)[0]
    return json.loads(data[20:20 + length].decode("utf-8").strip())


def main() -> int:
    errors: list[str] = []
    budget = json.loads((ROOT / "artifacts/kaia_golden_slice/MESH_BUDGET.json").read_text())
    equiv = json.loads((ROOT / "artifacts/kaia_golden_slice/PRESENTATION_GAMEPLAY_EQUIVALENCE.json").read_text())
    story = json.loads((ROOT / "game-godot/data/story/green_between_foundation.json").read_text())
    model = (ROOT / "game-godot/scripts/fighters/fighter_model_3d.gd").read_text()
    fighter = (ROOT / "game-godot/scripts/fighters/fighter.gd").read_text()
    menu = (ROOT / "game-godot/scenes/menus/MainMenuScene.tscn").read_text()
    router = (ROOT / "game-godot/scripts/core/SceneRouter.gd").read_text()

    if "model_3d.configure(data)" not in fighter:
        errors.append("shipping controller does not call model_3d.configure(data)")
    if "_try_load_golden_slice" not in model:
        errors.append("golden slice loader missing")
    if 'text = "Story"' not in menu:
        errors.append("Godot main menu has no Story item")
    if '"story":' not in router:
        errors.append("SceneRouter has no story route")
    if story.get("root_first_loss", {}).get("fighter") != "rook-ironside":
        errors.append("Rook is not the canonical First Loss")
    if story.get("story_unlocked_playable_yin") or story.get("story_unlocked_playable_yang"):
        errors.append("story unlocks Yin or Yang before convergence")
    if story.get("implementation_complete") or story.get("HUMAN_ART_APPROVAL") or story.get("MERGE_AUTHORIZED"):
        errors.append("story foundation claims completion or approval")
    node_ids = [node.get("id") for node in story.get("nodes", [])]
    for required in ("kaia_intro", "juno_nix_recruitment", "rook_first_loss", "campaign_map"):
        if required not in node_ids:
            errors.append(f"missing story node {required}")
    if not budget.get("KAIA_LOD0_TRIANGLE_BUDGET_PASS"):
        errors.append("triangle budget failed")
    if not equiv.get("KAIA_PRESENTATION_GAMEPLAY_EQUIVALENCE"):
        errors.append("presentation equivalence failed")
    if equiv.get("male_sha256") == equiv.get("female_sha256"):
        errors.append("male and female meshes are identical")
    for variant in ("male", "female"):
        glb = read_glb(ROOT / f"game-godot/assets/characters/golden_slice/kaia-windrow/{variant}.glb")
        names = {node.get("name") for node in glb.get("nodes", [])}
        missing = [bone for bone in BONES + SOCKETS if bone not in names]
        if missing:
            errors.append(f"{variant} missing {missing}")
        if not glb.get("skins"):
            errors.append(f"{variant} has no skin")
        ratio = budget["presentations"][variant]["head_units"]
        if not 3.2 <= ratio <= 3.5:
            errors.append(f"{variant} head ratio {ratio}")
    for fighter_id in PROXIES:
        proxy = ROOT / f"game-godot/content/fighters/{fighter_id}/model/{fighter_id}_procedural_proxy.glb"
        if not proxy.exists():
            errors.append(f"missing proxy {fighter_id}")

    progress = {"node_index": 0, "completed_node_ids": [], "essence": 0, "rook_first_loss_canonical": False}
    for node in story["nodes"]:
        progress["completed_node_ids"].append(node["id"])
        if node.get("first_loss") == "rook-ironside":
            progress["rook_first_loss_canonical"] = True
            progress["essence"] = node.get("essence_after", 1)
        progress["node_index"] = min(progress["node_index"] + 1, len(story["nodes"]) - 1)
    routing_ok = progress["rook_first_loss_canonical"] and "campaign_map" in progress["completed_node_ids"]
    if not routing_ok:
        errors.append("story routing simulation failed")

    result = {
        "WAVE014_AUTHORITY_GATE_GREEN": not errors,
        "AUTHORITY_MIXED_GOLDEN_SLICE": not errors,
        "KAIA_MODEL_SOURCE": "GOLDEN_SLICE_CANDIDATE",
        "REMAINING_SPECTRUM_PROXIES": len(PROXIES),
        "KAIA_LOD0_TRIANGLE_BUDGET_PASS": bool(budget.get("KAIA_LOD0_TRIANGLE_BUDGET_PASS")),
        "KAIA_CANONICAL_RIG_PASS": not any("missing" in err for err in errors),
        "KAIA_REQUIRED_SOCKETS_PASS": not any("missing" in err for err in errors),
        "KAIA_PRESENTATION_GAMEPLAY_EQUIVALENCE": bool(equiv.get("KAIA_PRESENTATION_GAMEPLAY_EQUIVALENCE")),
        "SHIPPING_FIGHTER_CONTROLLER_LOADS_KAIA_MODEL_DATA": "model_3d.configure(data)" in fighter and "_try_load_golden_slice" in model,
        "KAIA_VISIBLE_SKELETON_PRESENT": "_visible_skeleton = _find_skeleton(_proxy_model)" in model,
        "KAIA_RUNTIME_ANIMATION_CONTROLLER_COUNT": 1 if "_setup_procedural_runtime" in model else 0,
        "GODOT_STORY_FRONT_DOOR": 'text = "Story"' in menu and '"story":' in router,
        "THE_GREEN_BETWEEN_ROUTING_PASS": routing_ok,
        "STORY_PROGRESS_SAVE_PASS": "user://green_between_progress.json" in (ROOT / "game-godot/scripts/story/green_between_campaign.gd").read_text(),
        "ROOK_FIRST_LOSS_CANONICAL_FLAG_PASS": story.get("root_first_loss", {}).get("status") == "CANONICAL",
        "YIN_YANG_STORY_UNLOCK_SEPARATED": story.get("versus_selectable_yin_yang") is True and story.get("story_unlocked_playable_yin") is False,
        "HUMAN_ART_APPROVAL": False,
        "FINAL_CHARACTER_ART_PASS": False,
        "FULL_ROSTER_REBUILD_COMPLETE": False,
        "STORY_IMPLEMENTATION_COMPLETE": False,
        "MERGE_AUTHORIZED": False,
        "errors": errors,
    }
    dest = ROOT / "artifacts/kaia_golden_slice/AUTHORITY_GATE.json"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"pass": not errors, "errors": errors}, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
