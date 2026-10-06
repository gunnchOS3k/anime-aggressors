extends Node

## Shipping Story session. Open canon and unimplemented nodes cannot advance.
## Chapter completion comes from BattleScene's outcome, never the menu's Advance button.

const DATA_PATH := "res://data/story/v1_campaign.json"
const SAVE_PATH := "user://anime_v1_campaign.json"
const SCHEMA := "anime_v1.progress.v1"

var campaign: Dictionary = {}
var progress: Dictionary = {}
var active_encounter: Dictionary = {}
var last_result: Dictionary = {}
var last_error: String = ""
var _attempt_serial: int = 0
var save_path: String = SAVE_PATH
var watch_route_id := "kaia-windrow"
var watch_presentation := "female"


func _ready() -> void:
	campaign = _read_json(DATA_PATH)
	load_progress()


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func new_progress() -> Dictionary:
	var routes := {}
	for route in campaign.get("routes", []):
		routes[str(route["id"])] = {"cursor": str(route["nodes"][0]["id"]), "completed": [], "recruited": [], "essence": 0, "complete": false}
	return {"schema": SCHEMA, "selected_route": "kaia-windrow", "presentation": "female",
		"routes": routes, "gray_routes": [], "yin_unlocked": false, "yang_unlocked": false}


func load_progress() -> void:
	var saved := _read_json(save_path)
	progress = new_progress()
	# Reject malformed/newer saves instead of trusting arbitrary completion flags.
	if str(saved.get("schema", "")) == SCHEMA:
		progress["presentation"] = "male" if saved.get("presentation") == "male" else "female"
		for id in progress["routes"]:
			var entry: Variant = saved.get("routes", {}).get(id, {}) if saved.get("routes") is Dictionary else {}
			if not entry is Dictionary:
				continue
			var allowed := []
			for node in route_data(id).get("nodes", []):
				if not bool(node.get("implemented", false)):
					break
				allowed.append(str(node["id"]))
			var completed := []
			var stored: Variant = entry.get("completed", [])
			if not stored is Array:
				stored = []
			# Only a contiguous implemented prefix is a valid save at this checkpoint.
			for node_id in allowed:
				if node_id not in stored:
					break
				completed.append(node_id)
			progress["routes"][id]["completed"] = completed
			_rebuild_cursor(id)
		var selected := str(saved.get("selected_route", "kaia-windrow"))
		if route_available(selected):
			progress["selected_route"] = selected
	active_encounter.clear()
	last_result.clear()


func save_progress() -> bool:
	var temp := save_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_error = "Could not write Story progress."
		return false
	file.store_string(JSON.stringify(progress, "\t"))
	file.flush()
	file.close()
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(save_path))
	if error != OK:
		last_error = "Could not save Story progress (%d)." % error
		return false
	last_error = ""
	return true


func reset_campaign() -> bool:
	var previous := progress.duplicate(true)
	progress = new_progress()
	if not save_progress():
		progress = previous
		return false
	active_encounter.clear()
	last_result.clear()
	return true


func route_data(id: String) -> Dictionary:
	for route in campaign.get("routes", []):
		if str(route["id"]) == id:
			return route
	return {}


func route_review_enabled() -> bool:
	return OS.is_debug_build() and OS.get_environment("AA_V1_ROUTE_REVIEW") == "1"


func route_available(id: String) -> bool:
	if route_data(id).is_empty():
		return false
	if id == "kaia-windrow":
		return true
	if id == "sevenfold-convergence":
		return progress.get("gray_routes", []).size() == 7
	return "kaia-windrow" in progress.get("gray_routes", []) or route_review_enabled()


func select_route(id: String) -> bool:
	if not route_available(id) or not active_encounter.is_empty():
		return false
	var previous: String = progress["selected_route"]
	progress["selected_route"] = id
	if not save_progress():
		progress["selected_route"] = previous
		return false
	last_result.clear()
	return true


func current_node() -> Dictionary:
	var id := str(progress.get("selected_route", "kaia-windrow"))
	var cursor := str(progress.get("routes", {}).get(id, {}).get("cursor", ""))
	for node in route_data(id).get("nodes", []):
		if str(node["id"]) == cursor:
			return node
	return {}


func _rebuild_cursor(id: String) -> void:
	var entry: Dictionary = progress["routes"][id]
	var recruits := []
	var essence := 0
	for node in route_data(id).get("nodes", []):
		if str(node["id"]) not in entry["completed"]:
			entry["cursor"] = str(node["id"])
			break
		essence = int(node.get("essence_after", essence))
		if node.has("recruit"):
			recruits.append(node["recruit"])
	entry["recruited"] = recruits
	# Completion/unlocks remain false until later implemented route encounters pass.
	entry["complete"] = false
	entry["essence"] = essence


func acknowledge_scene() -> bool:
	var node := current_node()
	if not active_encounter.is_empty() or node.get("kind") != "INTERACTIVE_DIALOGUE" or not bool(node.get("implemented", false)):
		return false
	return _complete_node(str(node["id"]))


func _complete_node(node_id: String) -> bool:
	var previous := progress.duplicate(true)
	var id := str(progress["selected_route"])
	var completed: Array = progress["routes"][id]["completed"]
	if node_id not in completed:
		completed.append(node_id)
	_rebuild_cursor(id)
	if not save_progress():
		progress = previous
		return false
	return true


func begin_encounter(replay_id: String = "") -> bool:
	if not active_encounter.is_empty():
		return false
	var node := current_node()
	var replay := not replay_id.is_empty()
	var route_id := str(progress["selected_route"])
	if replay:
		if replay_id not in progress["routes"][route_id]["completed"]:
			return false
		for candidate in route_data(route_id)["nodes"]:
			if str(candidate["id"]) == replay_id:
				node = candidate
	if not bool(node.get("implemented", false)) or node.get("kind") != "STORY_BATTLE":
		return false
	if not save_progress():
		return false
	_attempt_serial += 1
	active_encounter = {"route_id": route_id, "node_id": str(node["id"]), "replay": replay,
		"token": "%s:%d:%d" % [node["id"], Time.get_ticks_usec(), _attempt_serial],
		"objective_contract":node.get("objective_contract", "STOCK_WIN"), "survive_seconds":node.get("survive_seconds", 0),
		"additional_opponent":node.get("additional_opponent", "")}
	last_result.clear()
	GameState.mode = "story"
	GameState.arcade_active = false
	GameState.team_mode = false
	GameState.hazards_enabled = false
	GameState.items_enabled = false
	GameState.damage_ratio = 1.0
	GameState.p1_fighter_id = route_data(route_id)["anchor"]
	GameState.p2_fighter_id = str(node["opponent"])
	GameState.p1_body_variant = str(progress["presentation"])
	GameState.p2_body_variant = "male" if progress["presentation"] == "female" else "female"
	GameState.p1_is_cpu = false
	GameState.p2_is_cpu = true
	GameState.cpu_level = 2
	GameState.stocks = 2
	GameState.match_timer_seconds = int(node.get("survive_seconds", 180))
	GameState.match_type = "stock"
	GameState.ruleset_id = "stock-3"
	GameState.stage_id = str(node["stage"])
	GameState.reset_match()
	return true


func record_battle_result(winner: int, token: String, objective_evidence: Dictionary = {}) -> bool:
	if active_encounter.is_empty() or str(active_encounter["token"]) != token:
		return false
	if winner == 1 and active_encounter.get("objective_contract") == "COSMIC_SURVIVAL":
		if not bool(objective_evidence.get("survived", false)) or float(objective_evidence.get("elapsed", 0)) + 0.001 < float(active_encounter["survive_seconds"]):
			return false
	var receipt := active_encounter.duplicate(true)
	receipt["objective_evidence"] = objective_evidence.duplicate(true)
	receipt["winner"] = winner
	receipt["advanced"] = false
	if winner == 1 and not bool(receipt["replay"]):
		if not _complete_node(str(receipt["node_id"])):
			return false
		receipt["advanced"] = true
	last_result = receipt
	active_encounter.clear()
	return true


func abandon_encounter() -> void:
	active_encounter.clear()
	last_result.clear()
	GameState.mode = "versus"
