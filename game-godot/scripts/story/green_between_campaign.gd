extends RefCounted
class_name GreenBetweenCampaign

const FOUNDATION_PATH := "res://data/story/green_between_foundation.json"
const SAVE_PATH := "user://green_between_progress.json"

static func load_foundation() -> Dictionary:
	var file := FileAccess.open(FOUNDATION_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func new_progress() -> Dictionary:
	var foundation := load_foundation()
	return {
		"schema": "green_between.progress.v1",
		"root_story": str(foundation.get("root_story", "THE_GREEN_BETWEEN")),
		"node_index": 0,
		"completed_node_ids": [],
		"essence": 0,
		"rook_first_loss_canonical": false,
		"story_unlocked_playable_yin": false,
		"story_unlocked_playable_yang": false,
		"copy_tag": "DRAFT_NARRATIVE_COPY",
	}


static func load_progress() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return new_progress()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return new_progress()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return new_progress()
	return parsed


static func save_progress(progress: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(progress, "\t"))
	file.close()
	return true


static func nodes() -> Array:
	return load_foundation().get("nodes", [])


static func advance(progress: Dictionary) -> Dictionary:
	var list := nodes()
	if list.is_empty():
		return progress
	var index := int(progress.get("node_index", 0))
	index = clampi(index, 0, list.size() - 1)
	var node: Dictionary = list[index]
	var completed: Array = progress.get("completed_node_ids", [])
	var node_id := str(node.get("id", ""))
	if node_id not in completed:
		completed.append(node_id)
	progress["completed_node_ids"] = completed
	if bool(node.get("canonical", false)) and str(node.get("first_loss", "")) == "rook-ironside":
		progress["rook_first_loss_canonical"] = true
		progress["essence"] = int(node.get("essence_after", 1))
	if index < list.size() - 1:
		progress["node_index"] = index + 1
	else:
		progress["node_index"] = index
	progress["story_unlocked_playable_yin"] = false
	progress["story_unlocked_playable_yang"] = false
	progress["copy_tag"] = "DRAFT_NARRATIVE_COPY"
	return progress


static func yin_yang_story_unlocked(progress: Dictionary) -> bool:
	return bool(progress.get("story_unlocked_playable_yin", false)) or bool(progress.get("story_unlocked_playable_yang", false))
