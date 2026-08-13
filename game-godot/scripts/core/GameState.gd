extends Node

## Session state for menu → battle flow (autoload).

var p1_fighter_id: String = "ember-vale"
var p2_fighter_id: String = "rook-ironside"
var p1_is_cpu: bool = false
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
var mode: String = "versus"  # versus | training | arcade | tutorial | hazards | team | challenges | online_unranked | online_ranked | tournament
var arcade_active: bool = false
var arcade_index: int = 0
var arcade_seed: int = 7
var arcade_player_id: String = "ember-vale"
var arcade_wins: int = 0
var arcade_complete: bool = false
var arcade_failed: bool = false

## Team / challenges (Beta modes).
var team_mode: bool = false
var team_size: int = 2
var challenge_id: String = ""
var challenge_objective: String = ""
var challenge_time_limit: int = 90
var challenge_target_damage: float = 100.0
var challenge_session_wins: int = 0
var completed_challenges: Dictionary = {}

## Online architecture selection (private/dev).
var online_queue: String = "private"  # private | unranked | ranked | tournament
var save_version: int = 2
const SAVE_VERSION_CURRENT: int = 2

## Tutorial / first-run interactive path.
var first_run_pending: bool = true
var tutorial_completed: bool = false
var tutorial_skipped: bool = false
var tutorial_step: int = 0
var tutorial_steps_done: Dictionary = {}
var _first_run_loaded: bool = false


## Headless / digital CPU eval on real BattleScene (no hidden-state cheat).
var battle_eval_mode: bool = false
var battle_eval_finished: bool = false
var battle_eval_frames: int = 0
var battle_eval_max_frames: int = 2400
var battle_eval_result: Dictionary = {}

## Local multiplayer / ruleset polish.
var damage_ratio: float = 1.0
var team_attack: bool = false
var ruleset_preset_name: String = "default"

## Progression / save (Alpha exit completeness).
var career_wins: int = 0
var career_losses: int = 0
var career_matches: int = 0
var unlocked_fighters: Array = []
var unlocked_stages: Array = []
var high_contrast: bool = false
var colorblind_markers: bool = false
var master_volume: float = 1.0
var _save_loaded: bool = false

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
	_ach_set_flag("tutorial_completed", true)


func skip_tutorial() -> void:
	tutorial_skipped = true
	first_run_pending = false
	_persist_first_run()
	mode = "versus"


func begin_hazards_mode() -> void:
	mode = "hazards"
	arcade_active = false
	team_mode = false
	hazards_enabled = true
	items_enabled = true
	stocks = 3
	match_timer_seconds = 150
	match_type = "stock"
	ruleset_id = "chaos-hazards"
	stage_id = "cascade-foundry" if stage_id == "training-grid" else stage_id
	p2_is_cpu = true
	reset_match()


func begin_team_mode() -> void:
	mode = "team"
	arcade_active = false
	team_mode = true
	team_size = 2
	team_attack = false
	hazards_enabled = false
	items_enabled = false
	stocks = 3
	match_timer_seconds = 180
	match_type = "stock"
	ruleset_id = "team-2v2"
	p1_is_cpu = false
	p2_is_cpu = true
	cpu_level = clampi(cpu_level, 1, 5)
	reset_match()


const CHALLENGES := [
	{"id": "damage_100", "name": "Break 100%", "objective": "damage", "target": 100.0, "time": 90, "stage": "training-grid"},
	{"id": "ko_90s", "name": "KO in 90s", "objective": "ko", "target": 1.0, "time": 90, "stage": "skyline-arena"},
	{"id": "survive_stocks", "name": "Hold 1 Stock", "objective": "survive", "target": 1.0, "time": 60, "stage": "void-pier"},
	{"id": "arcade_sprint", "name": "Two-Bout Sprint", "objective": "wins", "target": 2.0, "time": 240, "stage": "neon-rooftops"},
]


func begin_challenge(challenge_index: int = 0) -> void:
	var idx := clampi(challenge_index, 0, CHALLENGES.size() - 1)
	var c: Dictionary = CHALLENGES[idx]
	mode = "challenges"
	arcade_active = false
	team_mode = false
	challenge_id = str(c.id)
	challenge_objective = str(c.objective)
	challenge_time_limit = int(c.time)
	challenge_target_damage = float(c.target)
	challenge_session_wins = 0
	hazards_enabled = false
	items_enabled = false
	stage_id = str(c.stage)
	match_timer_seconds = challenge_time_limit
	stocks = 1 if challenge_objective == "ko" or challenge_objective == "survive" else 3
	match_type = "stock"
	ruleset_id = "challenge-%s" % challenge_id
	p1_is_cpu = false
	p2_is_cpu = true
	cpu_level = 3
	reset_match()


func begin_online_queue(queue: String) -> void:
	online_queue = queue
	mode = "online_%s" % queue if queue != "private" and queue != "tournament" else ("online_private" if queue == "private" else "tournament")
	arcade_active = false
	team_mode = false
	hazards_enabled = false
	items_enabled = false
	p2_is_cpu = false
	reset_match()


func migrate_save_if_needed(cfg: ConfigFile) -> Dictionary:
	## Digital RC save migration: v1 → v2 adds mode prefs + online queue.
	var from_ver := int(cfg.get_value("meta", "save_version", 1))
	var migrated := false
	if from_ver < 2:
		if not cfg.has_section_key("modes", "last_mode"):
			cfg.set_value("modes", "last_mode", mode)
		if not cfg.has_section_key("online", "queue"):
			cfg.set_value("online", "queue", "private")
		cfg.set_value("meta", "save_version", SAVE_VERSION_CURRENT)
		migrated = true
		from_ver = SAVE_VERSION_CURRENT
	save_version = from_ver
	return {"ok": true, "from": 1 if migrated else from_ver, "to": save_version, "migrated": migrated}


func recover_corrupted_profile(cfg: ConfigFile = null) -> Dictionary:
	## Reset unlocks/career to safe defaults when save values are nonsensical.
	var source := cfg
	if source == null:
		source = ConfigFile.new()
		source.load("user://aa_save.cfg")
	var corrupt := false
	var wins := int(source.get_value("career", "wins", 0))
	var losses := int(source.get_value("career", "losses", 0))
	var matches := int(source.get_value("career", "matches", 0))
	if wins < 0 or losses < 0 or matches < 0 or matches < wins + losses:
		corrupt = true
	var fighters = source.get_value("progress", "fighters", [])
	if typeof(fighters) != TYPE_ARRAY:
		corrupt = true
	if corrupt:
		career_wins = 0
		career_losses = 0
		career_matches = 0
		unlocked_fighters = roster_ids()
		unlocked_stages = production_stage_ids()
		save_version = SAVE_VERSION_CURRENT
		_persist_save()
		return {"ok": true, "recovered": true, "reason": "corrupted_profile"}
	return {"ok": true, "recovered": false}

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
			_ach_set_flag("arcade_complete", true)
			_ach_set_stat("arcade_wins", float(arcade_wins))
			_ach_event("arcade_clear")
			return "arcade_clear"
		_apply_arcade_bout()
		return "battle"
	arcade_failed = true
	arcade_active = false
	return "arcade_fail"


func arcade_opponent_name() -> String:
	var id: String = ARCADE_LADDER[mini(arcade_index, ARCADE_LADDER.size() - 1)]
	return str(load_fighter(id).get("displayName", id))



func begin_local_versus(p2_cpu: bool = true) -> void:
	mode = "versus"
	arcade_active = false
	hazards_enabled = false
	items_enabled = false
	battle_eval_mode = false
	p1_is_cpu = false
	p2_is_cpu = p2_cpu
	reset_match()


func begin_local_multiplayer() -> void:
	## Two human players on one device.
	begin_local_versus(false)
	p1_is_cpu = false
	p2_is_cpu = false
	ruleset_id = "local-multi-%d" % stocks


func record_career_result(winner_slot: int) -> void:
	career_matches += 1
	if winner_slot == 1:
		career_wins += 1
	elif winner_slot == 2:
		career_losses += 1
	_persist_save()
	_ach_event("match_complete")
	if winner_slot == 1:
		_ach_event("match_won")
		_ach_set_stat("career_wins", float(career_wins))


func ensure_save_loaded() -> void:
	if _save_loaded:
		return
	_save_loaded = true
	var cfg := ConfigFile.new()
	var err := cfg.load("user://aa_save.cfg")
	if err != OK:
		unlocked_fighters = roster_ids()
		unlocked_stages = production_stage_ids()
		save_version = SAVE_VERSION_CURRENT
		return
	migrate_save_if_needed(cfg)
	var recovery: Dictionary = recover_corrupted_profile(cfg)
	if bool(recovery.get("recovered", false)):
		return
	career_wins = int(cfg.get_value("career", "wins", 0))
	career_losses = int(cfg.get_value("career", "losses", 0))
	career_matches = int(cfg.get_value("career", "matches", 0))
	completed_challenges = cfg.get_value("progress", "challenges", {})
	unlocked_fighters = cfg.get_value("progress", "fighters", roster_ids())
	unlocked_stages = cfg.get_value("progress", "stages", production_stage_ids())
	high_contrast = bool(cfg.get_value("a11y", "high_contrast", false))
	colorblind_markers = bool(cfg.get_value("a11y", "colorblind_markers", false))
	master_volume = float(cfg.get_value("audio", "master_volume", 1.0))
	damage_ratio = float(cfg.get_value("rules", "damage_ratio", 1.0))
	team_attack = bool(cfg.get_value("rules", "team_attack", false))
	ruleset_preset_name = str(cfg.get_value("rules", "preset", "default"))
	online_queue = str(cfg.get_value("online", "queue", "private"))
	mode = str(cfg.get_value("modes", "last_mode", mode))


func _persist_save() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://aa_save.cfg")
	cfg.set_value("meta", "save_version", SAVE_VERSION_CURRENT)
	cfg.set_value("career", "wins", career_wins)
	cfg.set_value("career", "losses", career_losses)
	cfg.set_value("career", "matches", career_matches)
	cfg.set_value("progress", "challenges", completed_challenges)
	cfg.set_value("progress", "fighters", unlocked_fighters if unlocked_fighters.size() > 0 else roster_ids())
	cfg.set_value("progress", "stages", unlocked_stages if unlocked_stages.size() > 0 else production_stage_ids())
	cfg.set_value("a11y", "high_contrast", high_contrast)
	cfg.set_value("a11y", "colorblind_markers", colorblind_markers)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("rules", "damage_ratio", damage_ratio)
	cfg.set_value("rules", "team_attack", team_attack)
	cfg.set_value("rules", "preset", ruleset_preset_name)
	cfg.set_value("rules", "stocks", stocks)
	cfg.set_value("rules", "cpu_level", cpu_level)
	cfg.set_value("rules", "timer", match_timer_seconds)
	cfg.set_value("modes", "last_mode", mode)
	cfg.set_value("online", "queue", online_queue)
	cfg.save("user://aa_save.cfg")

func save_ruleset_preset(name: String) -> void:
	ruleset_preset_name = name
	_persist_save()
	var cfg := ConfigFile.new()
	cfg.load("user://aa_rulesets.cfg")
	cfg.set_value(name, "stocks", stocks)
	cfg.set_value(name, "cpu_level", cpu_level)
	cfg.set_value(name, "timer", match_timer_seconds)
	cfg.set_value(name, "damage_ratio", damage_ratio)
	cfg.set_value(name, "team_attack", team_attack)
	cfg.set_value(name, "match_type", match_type)
	cfg.save("user://aa_rulesets.cfg")


func load_ruleset_preset(name: String) -> bool:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://aa_rulesets.cfg")
	if err != OK or not cfg.has_section(name):
		return false
	stocks = int(cfg.get_value(name, "stocks", stocks))
	cpu_level = int(cfg.get_value(name, "cpu_level", cpu_level))
	match_timer_seconds = int(cfg.get_value(name, "timer", match_timer_seconds))
	damage_ratio = float(cfg.get_value(name, "damage_ratio", 1.0))
	team_attack = bool(cfg.get_value(name, "team_attack", false))
	match_type = str(cfg.get_value(name, "match_type", match_type))
	ruleset_preset_name = name
	ruleset_id = "preset-%s" % name
	return true


func list_ruleset_presets() -> Array:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://aa_rulesets.cfg")
	if err != OK:
		return []
	return Array(cfg.get_sections())


func reset_battle_eval() -> void:
	battle_eval_mode = true
	battle_eval_finished = false
	battle_eval_frames = 0
	battle_eval_result = {}
	last_winner_slot = -1
	p1_is_cpu = true
	p2_is_cpu = true
	arcade_active = false
	hazards_enabled = false
	items_enabled = false
	mode = "cpu_eval"


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


func resolve_challenge(winner: int, p1_stocks: int, p2_damage: float) -> Dictionary:
	if mode != "challenges" or challenge_id == "":
		return {"ok": false, "complete": false, "id": ""}
	var complete := false
	match challenge_objective:
		"damage":
			complete = p2_damage >= challenge_target_damage
		"ko":
			complete = winner == 1
		"survive":
			complete = p1_stocks >= int(challenge_target_damage) and winner != 2
		"wins":
			if winner == 1:
				challenge_session_wins += 1
			complete = challenge_session_wins >= int(challenge_target_damage)
		_:
			complete = winner == 1
	if complete:
		completed_challenges[challenge_id] = Time.get_datetime_string_from_system(true)
		_ach_set_flag("challenge:%s" % challenge_id, true)
		_ach_event("challenge_complete")
		_persist_save()
	return {"ok": true, "complete": complete, "id": challenge_id, "wins": challenge_session_wins}


func _achievements() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AchievementRuntime")


func _ach_event(event_id: String, amount: int = 1) -> void:
	var ach := _achievements()
	if ach != null and ach.has_method("report_event"):
		ach.report_event(event_id, amount)


func _ach_set_flag(flag: String, value: bool = true) -> void:
	var ach := _achievements()
	if ach != null and ach.has_method("set_flag"):
		ach.set_flag(flag, value)


func _ach_set_stat(stat: String, value: float) -> void:
	var ach := _achievements()
	if ach != null and ach.has_method("set_stat"):
		ach.set_stat(stat, value)


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
