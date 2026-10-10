extends Node

## Shipping Story session. Open canon and unimplemented nodes cannot advance.
## Chapter completion comes from BattleScene's outcome, never the menu's Advance button.

const DATA_PATH := "res://data/story/v1_campaign.json"
const SAVE_PATH := "user://anime_v1_campaign.json"
const SCHEMA := "anime_v1.progress.v2"

const APPROVED_FIRST_LOSS := {"kaia-windrow":"rook-ironside", "ember-vale":"nix-calder", "rook-ironside":"juno-spark", "juno-spark":"orion-vell", "nix-calder":"vesper-nyx", "orion-vell":"kaia-windrow", "vesper-nyx":"ember-vale"}

var campaign: Dictionary = {}
var progress: Dictionary = {}
var active_encounter: Dictionary = {}
var last_result: Dictionary = {}
var last_error: String = ""
var _attempt_serial: int = 0
var _battle_producer: Node = null
var _save_key := PackedByteArray()
var save_path: String = SAVE_PATH
var watch_route_id := "kaia-windrow"
var watch_presentation := "female"


func _ready() -> void:
	campaign = _read_json(DATA_PATH)
	if not validate_canon():
		last_error = "Campaign First Loss authority mismatch."
		campaign.clear()
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
		routes[str(route["id"])] = {"cursor": str(route["nodes"][0]["id"]), "completed": [], "receipts": {}, "recruited": [], "essence": 0, "essence_fighters": [], "released": [], "form": "BASE", "complete": false, "earned": false}
	return {"schema": SCHEMA, "canon_decision": campaign.get("canon_decision", ""), "selected_route": "kaia-windrow", "presentation": "female",
		"routes": routes, "gray_routes": [], "review_gray_routes": [], "yin_unlocked": false, "yang_unlocked": false}


func _key() -> PackedByteArray:
	# A separate local key prevents edited flags/prefixes/receipts from minting unlocks.
	# This protects save integrity, not against a user replacing executable code or stealing the key.
	if not _save_key.is_empty():
		return _save_key
	var key_path := save_path + ".key"
	if FileAccess.file_exists(key_path):
		_save_key = FileAccess.get_file_as_bytes(key_path)
	else:
		_save_key = Crypto.new().generate_random_bytes(32)
		var file := FileAccess.open(key_path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(_save_key)
			file.close()
	return _save_key if _save_key.size() == 32 else PackedByteArray()


func load_progress() -> void:
	var envelope := _read_json(save_path)
	progress = new_progress()
	_save_key = PackedByteArray()
	var payload: Variant = envelope.get("payload", "")
	var saved := {}
	if payload is String and not payload.is_empty() and not _key().is_empty():
		var signature := Crypto.new().hmac_digest(HashingContext.HASH_SHA256, _key(), payload.to_utf8_buffer()).hex_encode()
		if signature == envelope.get("hmac_sha256", ""):
			var parsed: Variant = JSON.parse_string(payload)
			if parsed is Dictionary:
				saved = parsed
	if saved.get("schema") == SCHEMA and saved.get("canon_decision") == campaign.get("canon_decision"):
		progress["presentation"] = "male" if saved.get("presentation") == "male" else "female"
		var tokens := []
		# Root first, then variations, then Convergence; recompute every derived unlock.
		var ids: Array = ["kaia-windrow"]
		for id in campaign.get("spectral_order", []):
			if id != "kaia-windrow": ids.append(id)
		ids.append("sevenfold-convergence")
		for id in ids:
			var entry: Variant = saved.get("routes", {}).get(id, {}) if saved.get("routes") is Dictionary else {}
			if not entry is Dictionary or not entry.get("completed", []) is Array or not entry.get("receipts", {}) is Dictionary:
				continue
			if id == "sevenfold-convergence" and progress["gray_routes"].size() != 7 and not (route_review_enabled() and progress["review_gray_routes"].size() == 7):
				continue
			var index := 0
			for node in route_data(id).get("nodes", []):
				var node_id: String = node["id"]
				if not node.get("implemented", false) or index >= entry["completed"].size() or entry["completed"][index] != node_id:
					break
				if node.get("kind") == "STORY_BATTLE":
					var receipt: Variant = entry["receipts"].get(node_id, {})
					if not receipt is Dictionary or receipt.get("node_id") != node_id or receipt.get("winner") != 1 or not receipt.get("token", "") is String or str(receipt.get("token", "")).is_empty() or receipt["token"] in tokens or not validate_objective(node, receipt.get("objective_evidence", {})):
						break
					tokens.append(receipt["token"])
					progress["routes"][id]["receipts"][node_id] = receipt
				progress["routes"][id]["completed"].append(node_id)
				index += 1
			_rebuild_cursor(id)
		var selected := str(saved.get("selected_route", "kaia-windrow"))
		if route_available(selected): progress["selected_route"] = selected
	elif not envelope.is_empty():
		last_error = "Unverified or legacy save retained. Authenticated Story encounters must be replayed."
	active_encounter.clear()
	_battle_producer = null
	last_result.clear()


func save_progress() -> bool:
	var key := _key()
	if key.is_empty():
		last_error = "Could not verify Story save key."
		return false
	# Preserve the original unsigned checkpoint before the first migration write.
	if FileAccess.file_exists(save_path) and not FileAccess.file_exists(save_path + ".legacy"):
		var old := _read_json(save_path)
		if old.get("schema") == "anime_v1.progress.v1":
			if DirAccess.copy_absolute(save_path, save_path + ".legacy") != OK:
				last_error = "Could not preserve legacy Story checkpoint."
				return false
	var payload := JSON.stringify(progress)
	var envelope := {"payload": payload, "hmac_sha256": Crypto.new().hmac_digest(HashingContext.HASH_SHA256, key, payload.to_utf8_buffer()).hex_encode()}
	var temp := save_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_error = "Could not write Story progress."
		return false
	file.store_string(JSON.stringify(envelope, "\t"))
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
		return progress.get("gray_routes", []).size() == 7 or (route_review_enabled() and progress.get("review_gray_routes", []).size() == 7)
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
	entry["cursor"] = ""
	entry["recruited"] = []
	entry["essence_fighters"] = []
	entry["released"] = []
	entry["form"] = "BASE"
	var earned := true
	for node in route_data(id).get("nodes", []):
		if str(node["id"]) not in entry["completed"]:
			entry["cursor"] = str(node["id"])
			break
		if node.has("recruit"): entry["recruited"].append(node["recruit"])
		if node.has("first_loss"): entry["essence_fighters"].append(node["first_loss"])
		var receipt: Dictionary = entry["receipts"].get(str(node["id"]), {})
		if node.get("kind") == "STORY_BATTLE": earned = earned and bool(receipt.get("qualifying", false))
		for fid in receipt.get("objective_evidence", {}).get("released", []):
			if fid not in entry["released"]: entry["released"].append(fid)
			if fid not in entry["essence_fighters"]: entry["essence_fighters"].append(fid)
		entry["form"] = node.get("form_after", entry["form"])
	entry["essence"] = entry["essence_fighters"].size()
	entry["complete"] = entry["cursor"].is_empty()
	entry["earned"] = entry["complete"] and earned
	_rebuild_unlocks()


func _rebuild_unlocks() -> void:
	progress["gray_routes"] = []
	progress["review_gray_routes"] = []
	for id in campaign.get("spectral_order", []):
		var entry: Dictionary = progress["routes"][id]
		if entry["complete"] and entry["essence"] == 6 and entry["form"] == "PRISMATIC_GRAY":
			progress["review_gray_routes"].append(id)
			if entry["earned"]: progress["gray_routes"].append(id)
	var convergence: Dictionary = progress["routes"].get("sevenfold-convergence", {})
	var cosmic: bool = progress["gray_routes"].size() == 7 and convergence.get("earned", false)
	progress["yin_unlocked"] = cosmic
	progress["yang_unlocked"] = cosmic


func acknowledge_scene() -> bool:
	var node := current_node()
	if not active_encounter.is_empty() or node.get("kind") != "INTERACTIVE_DIALOGUE" or not bool(node.get("implemented", false)):
		return false
	return _complete_node(str(node["id"]))


func _complete_node(node_id: String, receipt: Dictionary = {}) -> bool:
	if current_node().get("id") != node_id:
		return false
	var previous := progress.duplicate(true)
	var id := str(progress["selected_route"])
	var entry: Dictionary = progress["routes"][id]
	entry["completed"].append(node_id)
	# The transient Results receipt is cleared when the next encounter begins.
	# Persist an independent value so clearing that UI state cannot erase proof.
	if not receipt.is_empty(): entry["receipts"][node_id] = receipt.duplicate(true)
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
		"additional_opponent":node.get("additional_opponent", ""), "node":node.duplicate(true),
		"route_state":progress["routes"][route_id].duplicate(true),
		"qualifying":not GameState.battle_eval_mode and not route_review_enabled()}
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
	GameState.cpu_level = 3
	GameState.stocks = 2
	var objective: String = node.get("objective_contract", "STOCK_WIN")
	# A survival duration is a minimum for movement/guard objectives, not a
	# simultaneous deadline that defeats the player before their final step.
	GameState.match_timer_seconds = int(node["survive_seconds"]) if objective == "COSMIC_SURVIVAL" else 180 if objective == "STOCK_WIN" else 0
	GameState.match_type = "stock"
	GameState.ruleset_id = "stock-3"
	GameState.stage_id = str(node["stage"])
	GameState.reset_match()
	return true


func bind_battle_scene(scene: Node, token: String) -> bool:
	if active_encounter.is_empty() or active_encounter["token"] != token or not scene.is_inside_tree() or scene.scene_file_path != "res://scenes/battle/BattleScene.tscn":
		return false
	if _battle_producer != null and is_instance_valid(_battle_producer): return false
	_battle_producer = scene
	return true


func record_battle_result(winner: int, token: String, objective_evidence: Dictionary = {}, producer: Node = null) -> bool:
	if active_encounter.is_empty() or str(active_encounter["token"]) != token or winner not in [1, 2]: return false
	if producer == null or producer != _battle_producer or not producer.is_inside_tree() or producer.get("_active") != false: return false
	if winner == 1 and not validate_objective(active_encounter["node"], objective_evidence): return false
	var receipt := active_encounter.duplicate(true)
	receipt.erase("route_state")
	receipt.erase("node")
	receipt["objective_evidence"] = objective_evidence.duplicate(true)
	receipt["winner"] = winner
	receipt["advanced"] = false
	if winner == 1 and not bool(receipt["replay"]):
		if not _complete_node(str(receipt["node_id"]), receipt): return false
		receipt["advanced"] = true
	last_result = receipt.duplicate(true)
	active_encounter.clear()
	_battle_producer = null
	return true


func validate_objective(node: Dictionary, evidence: Variant) -> bool:
	if not evidence is Dictionary: return false
	var kind: String = node.get("objective_contract", "STOCK_WIN")
	if kind == "STOCK_WIN": return evidence.get("stock_win", false)
	if kind == "COSMIC_SURVIVAL": return evidence.get("survived", false) and float(evidence.get("elapsed", 0)) + 0.001 >= float(node["survive_seconds"])
	if not evidence.get("objective_complete", false): return false
	match kind:
		"FIRST_LOSS": return evidence.get("interaction") == node["consequence"]["interaction"] and int(evidence.get("steps", 0)) >= 2 and (node["consequence"]["interaction"] != "LAST_VECTOR_ESCORT" or (evidence.get("decision") == "ESCORT_TEAM" and evidence.get("escorted_fighters", []) is Array and evidence.get("escorted_fighters", []).size() == 5))
		"PUPPET_IMBALANCE": return int(evidence.get("yin_count", 0)) == 3 and int(evidence.get("yang_count", 0)) == 2 and int(evidence.get("player_hits", 0)) > 0
		"PUPPET_EQUILIBRIUM": return int(evidence.get("yin_count", 0)) == 2 and int(evidence.get("yang_count", 0)) == 2 and float(evidence.get("guard_seconds", 0)) >= 8
		"FIRST_RELEASE", "PAIRED_RELEASE":
			if not evidence.get("player_damage", {}) is Dictionary: return false
			var released: Variant = evidence.get("released", [])
			if not released is Array or released.size() != (1 if kind == "FIRST_RELEASE" else 2): return false
			var sides := []
			for fid in released:
				if fid in node["puppets"]["yin"]: sides.append("yin")
				elif fid in node["puppets"]["yang"]: sides.append("yang")
				else: return false
				if float(evidence.get("player_damage", {}).get(fid, 0)) < 40: return false
			return sides == ["yin"] if kind == "FIRST_RELEASE" else released[0] != released[1] and "yin" in sides and "yang" in sides
		"PRISMATIC_TRANSFORMATION": return int(evidence.get("perspectives", 0)) == 6 and evidence.get("form") == "PRISMATIC_GRAY" and int(evidence.get("steps", 0)) == 6
		"GRAY_DEMONSTRATION": return evidence.get("form") == "PRISMATIC_GRAY" and float(evidence.get("elapsed", 0)) >= 18 and evidence.get("attack", false) and evidence.get("guard", false) and evidence.get("traversal", false)
		"SEVENFOLD_REUNION": return int(evidence.get("steps", 0)) == 6
		"SEVENFOLD_TRIAL": return int(evidence.get("identities_exercised", 0)) == 7
		"SEVENFOLD_EQUILIBRIUM": return int(evidence.get("alternations", 0)) >= 6 and float(evidence.get("elapsed", 0)) >= 21
	return false


func abandon_encounter() -> void:
	_battle_producer = null
	active_encounter.clear()
	last_result.clear()
	GameState.mode = "versus"


func validate_canon() -> bool:
	if campaign.get("first_loss_selected", {}) != APPROVED_FIRST_LOSS:
		return false
	var seen := []
	for id in APPROVED_FIRST_LOSS:
		var route := route_data(id)
		var loss: String = APPROVED_FIRST_LOSS[id]
		if route.get("first_loss", {}).get("fighter") != loss or loss in seen:
			return false
		seen.append(loss)
		var count := 0
		for node in route.get("nodes", []):
			if node.has("first_loss"):
				count += 1
				if node["first_loss"] != loss:
					return false
		if count != 1:
			return false
	return seen.size() == 7
