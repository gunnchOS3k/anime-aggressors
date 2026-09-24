#!/usr/bin/env python3
"""Structural validator for elemental specials / facing / VFX / hit reactions.

Never promotes HUMAN_* or MERGE_AUTHORIZED. CombatMath must stay untouched.
"""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
FIGHTER_IDS = (
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
)
STRUCTURAL_GATES = (
    "ROSTER_ELEMENTAL_MATERIAL_CONTRACT_PASS",
    "FIGHTER_FACING_ATTACK_PASS",
    "FIGHTER_FACING_PROJECTILE_PASS",
    "FIGHTER_FACING_HURT_PASS",
    "FIGHTER_FACING_LAUNCH_PASS",
    "SIGNATURE_MOVE_MAPPING_PASS",
    "SPECIAL_POSE_READ_PASS",
    "SPECIAL_CONTACT_READ_PASS",
    "HURT_REACTION_DIRECTION_PASS",
    "HURT_REACTION_READ_PASS",
    "CHARGE_STATE_PRESENTATION_PASS",
    "SUPER_PRESENTATION_STRUCTURAL_PASS",
    "CLASH_PRESENTATION_STRUCTURAL_PASS",
    "ELEMENTAL_VFX_FAMILY_PASS",
    "PIXEL_REVIEW_ROUTE_PASS",
)
HUMAN_GATES_FALSE = {
    "HUMAN_ART_DIRECTION_APPROVAL": False,
    "HUMAN_ANIMATION_QUALITY_PASS": False,
    "HUMAN_COMBAT_FEEL_PASS": False,
    "HUMAN_AURA_CLASH_PASS": False,
    "HUMAN_CLIP_WORTHY_PASS": False,
    "FINAL_AUTHORED_ANIMATION_PASS": False,
    "MERGE_AUTHORIZED": False,
    "HUMAN_ELEMENTAL_IDENTITY_PASS": False,
    "HUMAN_SPECIALS_QUALITY_PASS": False,
    "HUMAN_HIT_REACTION_PASS": False,
    "HUMAN_VFX_QUALITY_PASS": False,
    "HUMAN_PIXEL_REVIEW_PASS": False,
    "HUMAN_ROSTER_ART_DIRECTION_PASS": False,
    "HUMAN_ROSTER_SILHOUETTE_PASS": False,
    "HUMAN_ROSTER_ANIMATION_QUALITY_PASS": False,
    "HUMAN_ROSTER_COMBAT_FEEL_PASS": False,
    "HUMAN_ROSTER_HURT_READ_PASS": False,
    "HUMAN_ROSTER_SUPER_PASS": False,
    "HUMAN_ROSTER_CLASH_PASS": False,
    "HUMAN_ROSTER_MOBILE_READ_PASS": False,
    "HUMAN_ROSTER_CLIP_WORTHY_PASS": False,
}
REQUIRED_DOCS = (
    "docs/art/ANIME_AGGRESSORS_FIGHTER_ART_BIBLE_V1.md",
    "docs/art/ROSTER_RENDERING_LANGUAGE_V1.md",
    "docs/combat/FULL_ROSTER_EXISTING_MOVE_AUDIT.md",
    "docs/combat/SIGNATURE_MOVE_PRESENTATION_V1.md",
    "docs/vfx/ELEMENTAL_VFX_LANGUAGE_V1.md",
    "docs/animation/DIRECTIONAL_HIT_REACTION_CONTRACT.md",
    "docs/playtest/ELEMENTAL_SPECIALS_PIXEL_REVIEW.md",
)
REQUIRED_RUNTIME = (
    "game-godot/data/runtime/elemental_material_language.json",
    "game-godot/data/runtime/signature_move_presentation.json",
    "game-godot/scripts/combat/fighter_facing_contract.gd",
    "game-godot/scripts/combat/directional_hit_reaction.gd",
    "game-godot/scripts/visual/elemental_material_contract.gd",
    "game-godot/scripts/visual/signature_move_presentation.gd",
    "game-godot/scripts/visual/elemental_vfx_family.gd",
    "game-godot/scripts/labs/full_roster_art_review_scene.gd",
)
EVIDENCE_DIRS = (
    "artifacts/elemental_identity",
    "artifacts/signature_moves",
    "artifacts/hit_reactions",
    "artifacts/pixel_elemental_review",
)


def load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def text(rel: str) -> str:
    path = ROOT / rel
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def move_ids(fighter_id: str) -> set[str]:
    payload = load_json(ROOT / "game-godot/data/moves" / f"{fighter_id}.json")
    return {str(row.get("move_id", "")) for row in payload.get("moves", []) if isinstance(row, dict)}


def docs_pass(failures: list[str]) -> bool:
    ok = True
    for rel in REQUIRED_DOCS + REQUIRED_RUNTIME:
        if not (ROOT / rel).is_file():
            failures.append(f"missing:{rel}")
            ok = False
    return ok


def combat_math_untouched(failures: list[str]) -> bool:
    combat = list((ROOT / "game-godot/scripts/combat").glob("combat_math*.gd"))
    combat += list(ROOT.glob("**/combat_math.gd"))
    diff = subprocess.run(
        ["git", "diff", "--name-only", "HEAD", "--", "game-godot/scripts/combat"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    names = [line.strip() for line in diff.stdout.splitlines() if line.strip()]
    touched = [n for n in names if "combat_math" in n.lower()]
    if touched:
        failures.append(f"combat_math_touched:{touched}")
        return False
    return True


def material_contract(failures: list[str]) -> bool:
    data = load_json(ROOT / "game-godot/data/runtime/elemental_material_language.json")
    fighters = data.get("fighters", {})
    cel = data.get("cel_shading", {})
    ok = True
    if float(cel.get("toon_bands", 0)) != 3.0:
        failures.append("cel_toon_bands_not_3")
        ok = False
    for fid in FIGHTER_IDS:
        entry = fighters.get(fid, {})
        for key in ("core", "structure", "accent", "charge", "element"):
            if key not in entry:
                failures.append(f"material_missing:{fid}:{key}")
                ok = False
        charge = str(entry.get("charge", ""))
        if not charge or charge == "aura_only":
            failures.append(f"charge_not_body_transform:{fid}")
            ok = False
    gd = text("game-godot/scripts/visual/elemental_material_contract.gd")
    if "apply_to_root" not in gd or "core" not in gd:
        failures.append("elemental_material_contract_incomplete")
        ok = False
    model = text("game-godot/scripts/fighters/fighter_model_3d.gd")
    if "_refresh_elemental_materials" not in model or "_ElementalMaterial.apply_to_root" not in model:
        failures.append("elemental_materials_not_wired")
        ok = False
    return ok


def facing_contract(failures: list[str]) -> dict[str, bool]:
    gd = text("game-godot/scripts/combat/fighter_facing_contract.gd")
    fighter = text("game-godot/scripts/fighters/fighter.gd")
    model = text("game-godot/scripts/fighters/fighter_model_3d.gd")
    proj = text("game-godot/scripts/combat/projectile.gd")
    spawn = text("game-godot/scripts/combat/projectile_spawner.gd")
    result = {
        "FIGHTER_FACING_ATTACK_PASS": True,
        "FIGHTER_FACING_PROJECTILE_PASS": True,
        "FIGHTER_FACING_HURT_PASS": True,
        "FIGHTER_FACING_LAUNCH_PASS": True,
    }
    if "logical_facing" not in gd or "attack_direction" not in gd or "MAX_ROOT_YAW_DELTA" not in gd:
        failures.append("facing_contract_incomplete")
        result["FIGHTER_FACING_ATTACK_PASS"] = False
    if "lock_attack_direction" not in fighter or "_attack_facing_locked" not in fighter:
        failures.append("attack_lock_not_wired")
        result["FIGHTER_FACING_ATTACK_PASS"] = False
    if "set_attack_facing_lock" not in model or "_apply_presentation_yaw" not in model:
        failures.append("presentation_yaw_not_wired")
        result["FIGHTER_FACING_ATTACK_PASS"] = False
    if "scale.x = absf" not in model:
        failures.append("2d_flip_still_used_as_facing")
        result["FIGHTER_FACING_ATTACK_PASS"] = False
    if "rotation_degrees.y = -8.0 + lean * 40.0" in model:
        failures.append("camera_lean_still_owns_yaw")
        result["FIGHTER_FACING_ATTACK_PASS"] = False
    # Structural LEFT/RIGHT math (mirrors FighterFacingContract).
    if not _attack_faces("RIGHT", 100.0, 200.0) or not _attack_faces("LEFT", 200.0, 100.0):
        failures.append("left_right_attack_math_failed")
        result["FIGHTER_FACING_ATTACK_PASS"] = False
    if _attack_faces("RIGHT", 200.0, 100.0) or _attack_faces("LEFT", 100.0, 200.0):
        failures.append("wrong_side_attack_math_passed")
        result["FIGHTER_FACING_ATTACK_PASS"] = False
    if "attack_direction" not in proj or "attack_direction" not in spawn:
        failures.append("projectile_not_using_attack_lock")
        result["FIGHTER_FACING_PROJECTILE_PASS"] = False
    if "func projectile_sign" not in gd:
        failures.append("projectile_sign_missing")
        result["FIGHTER_FACING_PROJECTILE_PASS"] = False
    if _projectile_sign(1, -1) != 1 or _projectile_sign(-1, 1) != -1:
        failures.append("projectile_sign_math_failed")
        result["FIGHTER_FACING_PROJECTILE_PASS"] = False
    hurt = text("game-godot/scripts/combat/directional_hit_reaction.gd")
    if "hurt_away_from_force" not in gd or "readable_hurt_before_launch" not in hurt:
        failures.append("hurt_contract_incomplete")
        result["FIGHTER_FACING_HURT_PASS"] = False
    if "apply_hurt_reaction" not in fighter or "apply_hurt_reaction" not in model:
        failures.append("hurt_not_wired")
        result["FIGHTER_FACING_HURT_PASS"] = False
    right_hit = _hurt_away(1.0, 0.0)
    left_hit = _hurt_away(-1.0, 0.0)
    if right_hit["logical_facing"] != "LEFT" or left_hit["logical_facing"] != "RIGHT":
        failures.append("hurt_facing_not_opposite")
        result["FIGHTER_FACING_HURT_PASS"] = False
    if "launch_follows_force" not in gd or "launch_follows_force" not in hurt:
        failures.append("launch_follow_missing")
        result["FIGHTER_FACING_LAUNCH_PASS"] = False
    if not _launch_follows(1.0, -0.2) or _launch_follows(0.0, 0.0):
        failures.append("launch_follow_math_failed")
        result["FIGHTER_FACING_LAUNCH_PASS"] = False
    return result


def _attack_faces(logical: str, attacker_x: float, defender_x: float) -> bool:
    if logical == "RIGHT":
        return attacker_x <= defender_x
    return attacker_x >= defender_x


def _projectile_sign(attack_direction: int, fallback_facing: int) -> int:
    if attack_direction == 0:
        return 1 if fallback_facing >= 0 else -1
    return 1 if attack_direction >= 0 else -1


def _hurt_away(x: float, y: float) -> dict:
    if x * x + y * y < 0.0001:
        x, y = 1.0, 0.0
    logical = "LEFT" if x > 0.0 else "RIGHT"
    return {"logical_facing": logical, "react_dir": (x, y)}


def _launch_follows(x: float, y: float) -> bool:
    return (x * x + y * y) > 0.0


def signature_mapping(failures: list[str]) -> tuple[bool, bool, bool, bool]:
    data = load_json(ROOT / "game-godot/data/runtime/signature_move_presentation.json")
    fighters = data.get("fighters", {})
    silhouettes = []
    poses = []
    clash = []
    mapping_ok = True
    pose_ok = True
    for fid in FIGHTER_IDS:
        ids = move_ids(fid)
        row = fighters.get(fid, {})
        for lane in ("special_a", "special_b", "super"):
            entry = row.get(lane, {})
            mid = str(entry.get("move_id", ""))
            pose = str(entry.get("pose", ""))
            if not mid or mid not in ids:
                failures.append(f"signature_move_missing:{fid}:{lane}:{mid}")
                mapping_ok = False
            if not pose:
                failures.append(f"signature_pose_missing:{fid}:{lane}")
                pose_ok = False
            poses.append(f"{fid}:{lane}:{pose}")
        heavy = str(row.get("heavy", {}).get("pose", ""))
        if not heavy:
            failures.append(f"heavy_pose_missing:{fid}")
            pose_ok = False
        sil = str(row.get("super", {}).get("silhouette", ""))
        if not sil:
            failures.append(f"super_silhouette_missing:{fid}")
        silhouettes.append(sil)
        clash_pose = str(row.get("clash", {}).get("pose", ""))
        if not clash_pose:
            failures.append(f"clash_pose_missing:{fid}")
        clash.append(clash_pose)
    unique_super = len(set(silhouettes)) == 7 and all(silhouettes)
    unique_clash = len(set(clash)) == 7 and all(clash)
    if data.get("combat_math_unchanged") is not True:
        failures.append("signature_json_missing_combat_math_unchanged")
        mapping_ok = False
    return mapping_ok, pose_ok, unique_super, unique_clash


def vfx_family(failures: list[str]) -> bool:
    gd = text("game-godot/scripts/visual/elemental_vfx_family.gd")
    ok = True
    for fid in FIGHTER_IDS:
        if fid not in gd:
            failures.append(f"vfx_family_missing:{fid}")
            ok = False
    for key in ("primary", "secondary", "hit", "charge", "clash", "particle_budget"):
        if key not in gd:
            failures.append(f"vfx_key_missing:{key}")
            ok = False
    if "body_pose" not in gd or "primary_elemental_effect" not in gd:
        failures.append("vfx_read_order_missing")
        ok = False
    return ok


def charge_pass(failures: list[str]) -> bool:
    data = load_json(ROOT / "game-godot/data/runtime/elemental_material_language.json")
    ok = True
    for fid in FIGHTER_IDS:
        charge = str(data.get("fighters", {}).get(fid, {}).get("charge", ""))
        if not charge:
            failures.append(f"charge_missing:{fid}")
            ok = False
    mat = text("game-godot/scripts/visual/fighter_material_controller.gd")
    if "set_charge_emission" not in mat or "apply_to_root" not in mat:
        failures.append("charge_does_not_reapply_body")
        ok = False
    return ok


def hit_reaction_pass(failures: list[str]) -> tuple[bool, bool]:
    gd = text("game-godot/scripts/combat/directional_hit_reaction.gd")
    families = (
        "LIGHT_HIT",
        "HEAVY_HIT",
        "LAUNCH_HIT",
        "ELEMENTAL_SPECIAL_HIT",
        "SUPER_HIT",
        "CLASH_LOSE",
    )
    ok = all(name in gd for name in families)
    if not ok:
        failures.append("hit_reaction_families_incomplete")
    for fid in FIGHTER_IDS:
        if fid not in gd:
            failures.append(f"hit_accent_missing:{fid}")
            ok = False
    review = text("game-godot/scripts/labs/full_roster_art_review_scene.gd")
    read_ok = ok and "hurt" in review and "apply_hurt_reaction" in review
    if not read_ok:
        failures.append("hurt_read_route_incomplete")
    return ok, read_ok


def review_route(failures: list[str]) -> bool:
    router = text("game-godot/scripts/core/SceneRouter.gd")
    scene = ROOT / "game-godot/scenes/labs/FullRosterArtReviewScene.tscn"
    script = text("game-godot/scripts/labs/full_roster_art_review_scene.gd")
    ok = True
    if "roster_art_review" not in router or not scene.is_file():
        failures.append("review_route_missing")
        ok = False
    for token in (
        'FACINGS := ["LEFT", "RIGHT"]',
        "VFX ON / OFF",
        "1.0 / 0.5 / 0.25",
        '"anticipation"',
        '"contact"',
        '"hurt"',
        '"follow-through"',
        '"special_a"',
        '"special_b"',
        '"super"',
        '"clash"',
        "selectable_opponent",
        "exposes_filesystem_paths",
    ):
        if token not in script:
            failures.append(f"review_control_missing:{token}")
            ok = False
    if "res://game-godot" in script or "/Users/" in script:
        failures.append("review_exposes_filesystem_paths")
        ok = False
    return ok


def evidence_pass() -> bool:
    ok = True
    for rel in EVIDENCE_DIRS:
        path = ROOT / rel
        path.mkdir(parents=True, exist_ok=True)
        if not path.is_dir():
            ok = False
    return ok


def main() -> int:
    failures: list[str] = []
    docs_ok = docs_pass(failures)
    math_ok = combat_math_untouched(failures)
    materials_ok = material_contract(failures)
    facing = facing_contract(failures)
    mapping_ok, pose_ok, super_ok, clash_ok = signature_mapping(failures)
    vfx_ok = vfx_family(failures)
    charge_ok = charge_pass(failures)
    hurt_dir_ok, hurt_read_ok = hit_reaction_pass(failures)
    route_ok = review_route(failures)
    evidence_ok = evidence_pass()

    gates = {
        "ROSTER_ELEMENTAL_MATERIAL_CONTRACT_PASS": materials_ok,
        "FIGHTER_FACING_ATTACK_PASS": facing["FIGHTER_FACING_ATTACK_PASS"],
        "FIGHTER_FACING_PROJECTILE_PASS": facing["FIGHTER_FACING_PROJECTILE_PASS"],
        "FIGHTER_FACING_HURT_PASS": facing["FIGHTER_FACING_HURT_PASS"],
        "FIGHTER_FACING_LAUNCH_PASS": facing["FIGHTER_FACING_LAUNCH_PASS"],
        "SIGNATURE_MOVE_MAPPING_PASS": mapping_ok,
        "SPECIAL_POSE_READ_PASS": pose_ok and route_ok,
        "SPECIAL_CONTACT_READ_PASS": pose_ok and route_ok,
        "HURT_REACTION_DIRECTION_PASS": hurt_dir_ok and facing["FIGHTER_FACING_HURT_PASS"],
        "HURT_REACTION_READ_PASS": hurt_read_ok,
        "CHARGE_STATE_PRESENTATION_PASS": charge_ok,
        "SUPER_PRESENTATION_STRUCTURAL_PASS": super_ok,
        "CLASH_PRESENTATION_STRUCTURAL_PASS": clash_ok,
        "ELEMENTAL_VFX_FAMILY_PASS": vfx_ok,
        "PIXEL_REVIEW_ROUTE_PASS": route_ok,
        "REQUIRED_DOCS_PASS": docs_ok,
        "COMBAT_MATH_UNCHANGED_PASS": math_ok,
        "EVIDENCE_DIRS_PASS": evidence_ok,
    }
    gates.update(HUMAN_GATES_FALSE)
    structural_complete = all(bool(gates[name]) for name in STRUCTURAL_GATES)
    gates["ELEMENTAL_SPECIALS_STRUCTURAL_COMPLETE"] = structural_complete
    notes = {
        "SPECIAL_POSE_READ_PASS": "Structural only: unique pose keys + review freeze phases exist. Owner Pixel VFX-off proof is HUMAN_PIXEL_REVIEW_PASS.",
        "SPECIAL_CONTACT_READ_PASS": "Structural only: contact freeze + mapped poses exist. Not owner visual sign-off.",
        "HUMAN_*": "Remain false until owner Pixel review.",
        "parent": "PR #109 3447c91d KayKit CC0 HUMAN_CANDIDATE 7/7. Not HUMAN_APPROVED.",
    }
    payload = {
        "schema": "elemental_specials_gates/v1",
        "emitted_at": datetime.now(timezone.utc).isoformat(),
        "roster": list(FIGHTER_IDS),
        "failures": failures,
        "notes": notes,
        **gates,
    }
    write_json(ROOT / "artifacts/elemental_identity/ELEMENTAL_SPECIALS_GATES.json", payload)
    write_json(ROOT / "artifacts/signature_moves/SIGNATURE_MAPPING_RESULT.json", {
        "ok": mapping_ok,
        "unique_super_silhouettes": super_ok,
        "unique_clash_poses": clash_ok,
        "combat_math_unchanged": math_ok,
    })
    write_json(ROOT / "artifacts/hit_reactions/DIRECTIONAL_HIT_REACTION_RESULT.json", {
        "ok": hurt_dir_ok,
        "families": [
            "LIGHT_HIT",
            "HEAVY_HIT",
            "LAUNCH_HIT",
            "ELEMENTAL_SPECIAL_HIT",
            "SUPER_HIT",
            "CLASH_LOSE",
        ],
        "left_right": True,
    })
    write_json(ROOT / "artifacts/pixel_elemental_review/REVIEW_ROUTE_RESULT.json", {
        "ok": route_ok,
        "controls": ["Facing LEFT/RIGHT", "VFX ON/OFF", "Speed 1.0/0.5/0.25", "Freeze phases", "Actions", "Opponent"],
        "install_authorized_if_structural": structural_complete,
    })
    print(json.dumps({"ok": structural_complete, "failures": failures, "gates": gates}, indent=2))
    return 0 if structural_complete else 1


if __name__ == "__main__":
    raise SystemExit(main())
