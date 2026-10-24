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


def story_checkpoint(route_id: str, node_ids: list[str], completed: list[str]) -> dict:
    accepted = accepted_prefix(node_ids, completed)
    return {
        "schema": SCHEMA,
        "route_id": route_id,
        "completed": list(accepted),
        "cursor": checkpoint_cursor(node_ids, accepted),
    }


def restore_story_checkpoint(saved: dict, node_ids: list[str]) -> dict:
    completed = saved.get("completed")
    if not isinstance(completed, list):
        completed = []
    return story_checkpoint(str(saved.get("route_id", "")), node_ids, [str(node_id) for node_id in completed])
