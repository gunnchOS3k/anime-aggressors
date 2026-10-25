"""Story checkpoint cursor. A saved prefix restores the next node, not an edited cursor.

This does not launch Godot and it does not write a player save.
"""

from __future__ import annotations


SCHEMA = "anime_v1.checkpoint.v1"


def accepted_prefix(node_ids: list[str], completed: list[str]) -> list[str]:
    accepted: list[str] = []
    for index, node_id in enumerate(node_ids):
        if index >= len(completed) or str(completed[index]) != node_id:
            break
        accepted.append(node_id)
    return accepted


def checkpoint_cursor(node_ids: list[str], completed: list[str]) -> str:
    accepted = accepted_prefix(node_ids, completed)
    if len(accepted) >= len(node_ids):
        return ""
    return node_ids[len(accepted)]


def combat_result(stocks: object, damage_percent: object) -> dict | None:
    if isinstance(stocks, bool) or isinstance(damage_percent, bool):
        return None
    if isinstance(stocks, float) and not stocks.is_integer():
        return None
    if not isinstance(stocks, (int, float)) or not isinstance(damage_percent, (int, float)):
        return None
    if stocks < 0 or damage_percent < 0:
        return None
    return {"stocks": int(stocks), "damage_percent": float(damage_percent)}


def story_checkpoint(
    route_id: str,
    node_ids: list[str],
    completed: list[str],
    stocks: object = None,
    damage_percent: object = None,
) -> dict:
    accepted = accepted_prefix(node_ids, completed)
    document = {
        "schema": SCHEMA,
        "route_id": route_id,
        "completed": list(accepted),
        "cursor": checkpoint_cursor(node_ids, accepted),
    }
    submitted = [str(node_id) for node_id in completed]
    combat = combat_result(stocks, damage_percent)
    if combat is not None and submitted == accepted:
        document["combat"] = combat
    return document


def restore_story_checkpoint(saved: dict, node_ids: list[str]) -> dict:
    completed = saved.get("completed")
    if not isinstance(completed, list):
        completed = []
    completed_ids = [str(node_id) for node_id in completed]
    combat = saved.get("combat") if isinstance(saved.get("combat"), dict) else {}
    return story_checkpoint(
        str(saved.get("route_id", "")),
        node_ids,
        completed_ids,
        combat.get("stocks"),
        combat.get("damage_percent"),
    )


def story_checkpoint_token(cursor: str, stocks: int, damage_percent: float) -> str:
    return "%s|%d|%.3f" % (cursor, stocks, damage_percent)


def story_fields_from_checkpoint(checkpoint: dict) -> dict | None:
    combat = checkpoint.get("combat") if isinstance(checkpoint.get("combat"), dict) else {}
    stocks = combat.get("stocks", checkpoint.get("stocks"))
    damage = combat.get("damage_percent", checkpoint.get("damage_percent"))
    parsed = combat_result(stocks, damage)
    if parsed is None:
        return None
    return {
        "cursor": str(checkpoint.get("cursor", "")),
        "stocks": parsed["stocks"],
        "damage_percent": parsed["damage_percent"],
    }


def attach_replay_story(record: dict, checkpoint: dict) -> dict:
    stored = dict(record)
    fields = story_fields_from_checkpoint(checkpoint)
    if fields is None:
        return stored
    stored["story_checkpoint"] = fields
    stored["story_integrity"] = story_checkpoint_token(fields["cursor"], fields["stocks"], fields["damage_percent"])
    return stored


def read_replay_story(record: dict) -> dict:
    if "story_checkpoint" not in record and "story_integrity" not in record:
        return {"ok": True, "present": False}
    fields = record.get("story_checkpoint")
    if not isinstance(fields, dict):
        return {"ok": False, "present": True, "error": "story_integrity_fail"}
    parsed = story_fields_from_checkpoint(fields)
    if parsed is None:
        return {"ok": False, "present": True, "error": "story_integrity_fail"}
    token = story_checkpoint_token(parsed["cursor"], parsed["stocks"], parsed["damage_percent"])
    if record.get("story_integrity") != token:
        return {"ok": False, "present": True, "error": "story_integrity_fail"}
    return {"ok": True, "present": True, **parsed}
