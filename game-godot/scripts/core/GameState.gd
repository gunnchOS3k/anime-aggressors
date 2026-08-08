extends Node

## Session state for menu → battle flow (autoload).

var p1_fighter_id: String = "ember-vale"
var p2_fighter_id: String = "rook-ironside"
var p2_is_cpu: bool = true
var cpu_level: int = 2
var stage_id: String = "skyline-arena"
var ruleset_id: String = "stock-3"
var stocks: int = 3
var match_timer_seconds: int = 180
var match_type: String = "stock"
var match_seed: int = 0

var p1_ready: bool = false
var p2_ready: bool = false

var training_dummy_mode: String = "cpu"
var last_winner_slot: int = -1

## Arcade ladder (Alpha minimum mode beyond Versus + Training).
var mode: String = "versus"  # versus | training | arcade
var arcade_active: bool = false
var arcade_index: int = 0
var arcade_seed: int = 7
var arcade_player_id: String = "ember-vale"
var arcade_wins: int = 0
var arcade_complete: bool = false
var arcade_failed: bool = false

## Canonical Alpha ladder: all 7 roster fighters as sequential CPU opponents.
const ARCADE_LADDER: Array[String] = [
	"juno-spark",
	"kaia-windrow",
	"nix-calder",
	"orion-vell",
	"vesper-nyx",
	"rook-ironside",
	"ember-vale",
]

const ARCADE_STAGES: Array[String] = [
	"skyline-arena",
	"neon-rooftops",
	"cascade-foundry",
	"void-pier",
	"ember-courtyard",
	"skyline-arena",
	"neon-rooftops",
]


func reset_match() -> void:
	p1_ready = false
	p2_ready = false
	last_winner_slot = -1


func begin_arcade(player_id: String = "") -> void:
	mode = "arcade"
	arcade_active = true
	arcade_complete = false
	arcade_failed = false
	arcade_index = 0
	arcade_wins = 0
	arcade_player_id = player_id if player_id != "" else p1_fighter_id
	arcade_seed = 7 + int(Time.get_unix_time_from_system()) % 100000
	_apply_arcade_bout()


func _apply_arcade_bout() -> void:
	p1_fighter_id = arcade_player_id
	p2_fighter_id = ARCADE_LADDER[arcade_index]
	p2_is_cpu = true
	cpu_level = mini(5, 2 + arcade_index / 2)
	stage_id = ARCADE_STAGES[arcade_index % ARCADE_STAGES.size()]
	stocks = 2
	match_timer_seconds = 120
	match_type = "stock"
	match_seed = arcade_seed + arcade_index * 17
	ruleset_id = "arcade-ladder"
	reset_match()


func advance_arcade_after_result() -> String:
	## Returns next scene key hint: battle | arcade_results | mode_select
	if not arcade_active:
		return "results"
	if last_winner_slot == 1:
		arcade_wins += 1
		arcade_index += 1
		if arcade_index >= ARCADE_LADDER.size():
			arcade_complete = true
			arcade_active = false
			return "arcade_clear"
		_apply_arcade_bout()
		return "battle"
	arcade_failed = true
	arcade_active = false
	return "arcade_fail"


func arcade_opponent_name() -> String:
	var id: String = ARCADE_LADDER[mini(arcade_index, ARCADE_LADDER.size() - 1)]
	return str(load_fighter(id).get("displayName", id))


func load_fighter(id: String) -> Dictionary:
	var path := "res://data/fighters/%s.json" % id
	if not FileAccess.file_exists(path):
		push_warning("Missing fighter data: %s" % id)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func load_stage(id: String) -> Dictionary:
	var path := "res://data/stages/%s.json" % id
	if not FileAccess.file_exists(path):
		push_warning("Missing stage data: %s" % id)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func roster_ids() -> Array:
	var path := "res://data/fighters/roster.json"
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	return data.get("fighters", [])


func production_stage_ids() -> Array:
	var path := "res://data/stages/production_stages.json"
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	return data.get("stages", [])


func competitive_stage_ids() -> Array:
	var out: Array = []
	for id in production_stage_ids():
		if str(id) == "training-grid":
			continue
		out.append(id)
	return out
