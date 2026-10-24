#!/usr/bin/env python3
"""Prove Story Next Route advances, and that the seven campaign graphs are data-complete.

This does not launch Godot, import assets, or touch owner saves.
It is not a human playthrough and it does not earn Gray, Yin, or Yang.

Baseline, before the runtime fix, with Kaia complete and Rook selected:

    LEGACY_NEXT ember-vale
    LEGACY_WALK ['ember-vale', 'ember-vale', 'ember-vale', ...]

The shipping loop returned the earliest incomplete route and then stayed there.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from story_checkpoint import restore_story_checkpoint, story_checkpoint  # noqa: E402


ROOT = Path(__file__).resolve().parents[2]
CAMPAIGN = ROOT / "game-godot/data/story/v1_campaign.json"
RUNTIME = ROOT / "game-godot/scripts/story/v1_campaign_runtime.gd"
SCENE = ROOT / "game-godot/scripts/menus/story_campaign_scene.gd"
WEB = ROOT / "apps/web/src/screens/StoryCampaignScreen.ts"
BATTLE = ROOT / "game-godot/scripts/battle/battle_scene.gd"

APPROVED_FIRST_LOSS = {
    "kaia-windrow": "rook-ironside",
    "ember-vale": "nix-calder",
    "rook-ironside": "juno-spark",
    "juno-spark": "orion-vell",
    "nix-calder": "vesper-nyx",
    "orion-vell": "kaia-windrow",
    "vesper-nyx": "ember-vale",
}
INTERACTIONS = {
    "DECISIVE_INTERVENTION",
    "RESTRAINED_PROTECTION",
    "SHARED_DEFENSE",
    "LAST_VECTOR_ESCORT",
    "OPEN_BOUNDARY",
    "PERSONAL_VECTOR",
    "HONEST_SIGNAL",
}


def legacy_next(routes: list[str], available: set[str], complete: set[str]) -> str:
    for route_id in routes:
        if route_id in available and route_id not in complete:
            return route_id
    return ""


def fixed_next(routes: list[str], available: set[str], complete: set[str], selected: str) -> str:
    ids = [route_id for route_id in routes if route_id in available and route_id not in complete]
    if not ids:
        return ""
    if selected not in ids:
        return ids[0]
    return ids[(ids.index(selected) + 1) % len(ids)]


def check(condition: bool, label: str, failures: list[str]) -> None:
    if not condition:
        failures.append(label)
        print("FAIL", label)
    else:
        print("PASS", label)


def essence_before_prismatic(route: dict) -> tuple[int, str]:
    essence: list[str] = []
    released: list[str] = []
    for node in route["nodes"]:
        contract = node.get("objective_contract")
        if contract == "PRISMATIC_TRANSFORMATION":
            return len(essence), ",".join(essence)
        if node.get("first_loss") and node["first_loss"] not in essence:
            essence.append(node["first_loss"])
        if contract == "FIRST_RELEASE":
            yin = [fid for fid in node["puppets"]["yin"] if fid not in released]
            if yin and yin[0] not in essence:
                essence.append(yin[0])
            if yin:
                released.append(yin[0])
        if contract == "PAIRED_RELEASE":
            yin = [fid for fid in node["puppets"]["yin"] if fid not in released]
            yang = [fid for fid in node["puppets"]["yang"] if fid not in released]
            if yin and yang:
                released.extend([yin[0], yang[0]])
                for fid in (yin[0], yang[0]):
                    if fid not in essence:
                        essence.append(fid)
    return len(essence), ",".join(essence)


def main() -> int:
    failures: list[str] = []
    campaign = json.loads(CAMPAIGN.read_text())
    routes = [route["id"] for route in campaign["routes"]]
    runtime = RUNTIME.read_text()
    scene = SCENE.read_text()

    available = {
        "ember-vale",
        "rook-ironside",
        "juno-spark",
        "kaia-windrow",
        "nix-calder",
        "orion-vell",
        "vesper-nyx",
    }
    complete = {"kaia-windrow"}
    print("BASELINE_SELECTED rook-ironside")
    print("LEGACY_NEXT", legacy_next(routes, available, complete))
    legacy_walk = []
    selected = "rook-ironside"
    for _ in range(6):
        selected = legacy_next(routes, available, complete)
        legacy_walk.append(selected)
    print("LEGACY_WALK", legacy_walk)
    check(legacy_walk == ["ember-vale"] * 6, "legacy_next_route_sticks_on_ember", failures)

    fixed_walk = []
    selected = "rook-ironside"
    for _ in range(6):
        selected = fixed_next(routes, available, complete, selected)
        fixed_walk.append(selected)
    print("FIXED_WALK", fixed_walk)
    check(
        fixed_walk == ["juno-spark", "nix-calder", "orion-vell", "vesper-nyx", "ember-vale", "rook-ironside"],
        "fixed_next_route_visits_every_open_variation",
        failures,
    )
    check(
        fixed_next(routes, {"kaia-windrow"}, set(), "kaia-windrow") == "kaia-windrow",
        "only_open_route_stays_selected",
        failures,
    )
    check(
        fixed_next(routes, available, complete, "vesper-nyx") == "ember-vale",
        "locked_convergence_wraps_to_ember",
        failures,
    )
    check(routes[-1] == "sevenfold-convergence", "convergence_is_last_route", failures)
    check(
        fixed_next(routes, available | {"sevenfold-convergence"}, complete, "vesper-nyx")
        == "sevenfold-convergence",
        "next_after_vesper_is_convergence_when_unlocked",
        failures,
    )

    check("func next_incomplete_route_id() -> String:" in runtime, "runtime_exports_next_incomplete_route_id", failures)
    check("return ids[(index + 1) % ids.size()]" in runtime, "runtime_walks_forward", failures)
    check("CampaignRuntime.next_incomplete_route_id()" in scene, "story_menu_calls_forward_walk", failures)
    check("for route in CampaignRuntime.campaign[\"routes\"]:" not in scene.split("func _on_next_route")[1].split("func ")[0], "story_menu_no_longer_scans_from_the_start", failures)

    check(len(campaign["routes"]) == 8, "eight_route_records", failures)
    node_total = 0
    for route in campaign["routes"]:
        node_total += len(route["nodes"])
        if route["id"] == "sevenfold-convergence":
            check(len(route["nodes"]) == 5, "convergence_has_five_nodes", failures)
            continue
        check(len(route["nodes"]) == 20, f"{route['id']}_has_20_nodes", failures)
        check(route.get("first_loss", {}).get("fighter") == APPROVED_FIRST_LOSS[route["id"]], f"{route['id']}_first_loss", failures)
        loss_nodes = [node["id"] for node in route["nodes"] if "first_loss" in node]
        check(loss_nodes == [f"{route['id']}:first_loss"], f"{route['id']}_one_loss_node", failures)
        interaction = next(node["consequence"]["interaction"] for node in route["nodes"] if node.get("objective_contract") == "FIRST_LOSS")
        check(interaction in INTERACTIONS, f"{route['id']}_interaction_known", failures)
        count, names = essence_before_prismatic(route)
        check(count == 6, f"{route['id']}_six_essences_before_prismatic:{names}", failures)
        battles = [node for node in route["nodes"] if node["kind"] == "STORY_BATTLE"]
        check(len(battles) == 16, f"{route['id']}_16_battles", failures)
        check(all(node.get("implemented") is True for node in route["nodes"]), f"{route['id']}_implemented", failures)
    check(node_total == 145, "145_nodes", failures)
    check(campaign.get("first_loss_selected") == APPROVED_FIRST_LOSS, "approved_first_loss_map", failures)

    web = WEB.read_text()
    public, qa = web.split("const qa", 1)
    check("story-sim-win" not in public and "story-sim-loss" not in public, "public_story_has_no_simulated_result", failures)
    check("story-sim-win" in qa and "story-sim-loss" in qa, "qa_drawer_keeps_simulated_result", failures)
    check("story-launch-encounter" in public, "public_story_launches_encounter_setup", failures)
    check("advanceAfterWin" not in public.split("story-launch-encounter")[1].split("const qa")[0], "public_encounter_does_not_call_advance", failures)
    battle = BATTLE.read_text()
    check("record_battle_result" in battle, "battle_scene_records_result", failures)
    check('SceneRouter.go("battle")' in scene or 'go("battle")' in scene, "story_menu_enters_battle", failures)
    check("begin_encounter" in runtime, "runtime_begins_encounter", failures)
    check("static func checkpoint_cursor" in runtime, "runtime_exports_checkpoint_cursor", failures)
    check("static func restore_story_checkpoint" in runtime, "runtime_exports_checkpoint_restore", failures)
    check('entry["cursor"] = checkpoint_cursor(node_ids, entry.get("completed", []))' in runtime, "cursor_follows_checkpoint_prefix", failures)
    check("_write_checkpoint(id)" in runtime.split("func _complete_node")[1].split("func ")[0], "completing_a_node_writes_checkpoint", failures)
    check("restore_story_checkpoint(document" in runtime, "load_restores_checkpoint_document", failures)

    kaia = next(route for route in campaign["routes"] if route["id"] == "kaia-windrow")
    node_ids = [node["id"] for node in kaia["nodes"]]
    check(len(node_ids) >= 3, "kaia_has_three_nodes_for_checkpoint", failures)
    first_save = story_checkpoint("kaia-windrow", node_ids, [node_ids[0]])
    first_restored = restore_story_checkpoint(json.loads(json.dumps(first_save)), node_ids)
    check(first_restored["cursor"] == node_ids[1] and first_restored["completed"] == [node_ids[0]], "checkpoint_after_first_node_restores_second", failures)
    second_save = story_checkpoint("kaia-windrow", node_ids, list(first_restored["completed"]) + [node_ids[1]])
    second_restored = restore_story_checkpoint(json.loads(json.dumps(second_save)), node_ids)
    check(
        second_restored["completed"] == [node_ids[0], node_ids[1]] and second_restored["cursor"] == node_ids[2],
        "checkpoint_after_two_nodes_restores_third",
        failures,
    )
    forged = dict(second_save)
    forged["cursor"] = node_ids[0]
    forged_restored = restore_story_checkpoint(forged, node_ids)
    check(forged_restored["cursor"] == node_ids[2], "forged_cursor_does_not_rewind", failures)
    skipped = restore_story_checkpoint({"route_id": "kaia-windrow", "completed": [node_ids[1]], "cursor": node_ids[2]}, node_ids)
    check(skipped["cursor"] == node_ids[0] and skipped["completed"] == [], "skipped_node_does_not_advance", failures)
    print("STORY_CHECKPOINT two_nodes route=kaia-windrow PLAY=not_run")
    print("WEB_MATCH_RESULT not_wired")
    print("GODOT_BATTLE source_only")
    for route in campaign["routes"]:
        if route["id"] == "sevenfold-convergence":
            print(f"ROUTE {route['id']} DATA=present PLAY=not_run")
            continue
        print(f"ROUTE {route['id']} DATA=present FIRST_LOSS={route.get('first_loss', {}).get('fighter', '')} PLAY=not_run")
    print("HUMAN_PLAYTHROUGH false")
    print("GODOT_IMPORT false")
    print("SEVEN_EARNED_ROUTES false")
    print("V1_READY false")
    print("RC2_READY false")
    if failures:
        print("STORY_ROUTE_ADVANCE FAIL", len(failures))
        for failure in failures:
            print(" ", failure)
        return 1
    print("STORY_ROUTE_ADVANCE PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
