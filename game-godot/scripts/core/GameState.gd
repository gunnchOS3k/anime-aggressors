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
var mode: String = "versus"  # versus | training | arcade | tutorial | hazards
var arcade_active: bool = false
var arcade_index: int = 0
var arcade_seed: int = 7
var arcade_player_id: String = "ember-vale"
var arcade_wins: int = 0
var arcade_complete: bool = false
var arcade_failed: bool = false

## Tutorial / first-run interactive path.
var first_run_pending: bool = true
var tutorial_completed: bool = false
var tutorial_skipped: bool = false
var tutorial_step: int = 0
var tutorial_steps_done: Dictionary = {}
var _first_run_loaded: bool = false

## Items / hazards mode.
var hazards_enabled: bool = false
var items_enabled: bool = false

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


func ensure_first_run_loaded() -> void:
	if _first_run_loaded:
		return
	_first_run_loaded = true
	var cfg := ConfigFile.new()
	var err := cfg.load("user://aa_first_run.cfg")
	if err != OK:
		first_run_pending = true
		tutorial_completed = false
		return
	tutorial_completed = bool(cfg.get_value("tutorial", "completed", false))
	tutorial_skipped = bool(cfg.get_value("tutorial", "skipped", false))
	first_run_pending = not (tutorial_completed or tutorial_skipped)


func _persist_first_run() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("tutorial", "completed", tutorial_completed)
	cfg.set_value("tutorial", "skipped", tutorial_skipped)
	cfg.save("user://aa_first_run.cfg")


func begin_tutorial() -> void:
	ensure_first_run_loaded()
	mode = "tutorial"
	arcade_active = false
	hazards_enabled = false
	items_enabled = false
	tutorial_step = 0
	stage_id = "training-grid"
	p2_fighter_id = "rook-ironside"
	p2_is_cpu = false
	training_dummy_mode = "idle"
	stocks = 99
	match_timer_seconds = 0
	match_type = "training"
	ruleset_id = "tutorial"
	reset_match()


func mark_tutorial_step(step_id: String) -> void:
	tutorial_steps_done[step_id] = true
	tutorial_step = tutorial_steps_done.size()


func complete_tutorial() -> void:
	tutorial_completed = true
	tutorial_skipped = false
	first_run_pending = false
	_persist_first_run()


func skip_tutorial() -> void:
	tutorial_skipped = true
	first_run_pending = false
	_persist_first_run()
	mode = "versus"


func begin_hazards_mode() -> void:
	mode = "hazards"
	arcade_active = false
	hazards_enabled = true
	items_enabled = true
	stocks = 3
	match_timer_seconds = 150
	match_type = "stock"
	ruleset_id = "chaos-hazards"
	stage_id = "cascade-foundry" if stage_id == "training-grid" else stage_id
	p2_is_cpu = true
	reset_match()


func begin_arcade(player_id: String = "") -> void:
	mode = "arcade"
	arcade_active = true
	arcade_complete = false
	arcade_failed = false
	hazards_enabled = false
	items_enabled = false
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
