extends SceneTree

## Isolated round-trip for user://aa_save.cfg rules.stocks, rules.cpu_level, and rules.timer.
## Refuses the owner "Anime Aggressors" user directory. Run only via
## tools/save_rules/run_isolated_probe.sh so Godot never imports the game project.

const EXPECT_STOCKS := 7
const EXPECT_CPU := 4
const EXPECT_TIMER := 60
const DEFAULT_STOCKS := 3
const DEFAULT_CPU := 2
const DEFAULT_TIMER := 180


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var user_dir := OS.get_user_data_dir()
	print("USER_DIR %s" % user_dir)
	if "Anime Aggressors" in user_dir:
		print("FAIL refused owner save directory")
		quit(2)
		return
	var Gs = load("res://scripts/core/GameState.gd")
	var writer = Gs.new()
	writer.stocks = EXPECT_STOCKS
	writer.cpu_level = EXPECT_CPU
	writer.match_timer_seconds = EXPECT_TIMER
	writer.unlocked_fighters = ["ember-vale"]
	writer.unlocked_stages = ["training-grid"]
	writer._persist_save()

	var cfg := ConfigFile.new()
	var err := cfg.load("user://aa_save.cfg")
	var disk_stocks := int(cfg.get_value("rules", "stocks", -1))
	var disk_cpu := int(cfg.get_value("rules", "cpu_level", -1))
	var disk_timer := int(cfg.get_value("rules", "timer", -1))
	print("DISK load_err=%d rules.stocks=%d rules.cpu_level=%d rules.timer=%d" % [err, disk_stocks, disk_cpu, disk_timer])

	var fresh = Gs.new()
	print("FRESH_DEFAULTS stocks=%d cpu_level=%d match_timer_seconds=%d" % [fresh.stocks, fresh.cpu_level, fresh.match_timer_seconds])
	fresh.ensure_save_loaded()
	print("RELOADED stocks=%d cpu_level=%d match_timer_seconds=%d" % [fresh.stocks, fresh.cpu_level, fresh.match_timer_seconds])
	var roundtrip: bool = fresh.stocks == EXPECT_STOCKS and fresh.cpu_level == EXPECT_CPU and fresh.match_timer_seconds == EXPECT_TIMER
	print("ROUNDTRIP %s" % str(roundtrip))
	if not roundtrip:
		print("FAIL reloaded stocks=%d cpu_level=%d match_timer_seconds=%d !== expected stocks=%d cpu_level=%d match_timer_seconds=%d" % [fresh.stocks, fresh.cpu_level, fresh.match_timer_seconds, EXPECT_STOCKS, EXPECT_CPU, EXPECT_TIMER])
		print("FAIL %s !== true" % str(roundtrip))
		writer.free()
		fresh.free()
		quit(1)
		return
	writer.free()
	fresh.free()

	var bare := ConfigFile.new()
	bare.set_value("meta", "save_version", 2)
	bare.set_value("career", "wins", 0)
	bare.set_value("career", "losses", 0)
	bare.set_value("career", "matches", 0)
	bare.set_value("progress", "fighters", ["ember-vale"])
	bare.set_value("progress", "stages", ["training-grid"])
	bare.set_value("rules", "damage_ratio", 1.0)
	bare.set_value("rules", "team_attack", false)
	bare.set_value("rules", "preset", "default")
	bare.save("user://aa_save.cfg")
	var missing = Gs.new()
	missing.stocks = 9
	missing.cpu_level = 5
	missing.match_timer_seconds = 0
	missing.ensure_save_loaded()
	print("ABSENT_KEYS stocks=%d cpu_level=%d match_timer_seconds=%d" % [missing.stocks, missing.cpu_level, missing.match_timer_seconds])
	var defaults_ok: bool = missing.stocks == DEFAULT_STOCKS and missing.cpu_level == DEFAULT_CPU and missing.match_timer_seconds == DEFAULT_TIMER
	if not defaults_ok:
		print("FAIL absent keys stocks=%d cpu_level=%d match_timer_seconds=%d !== defaults stocks=%d cpu_level=%d match_timer_seconds=%d" % [missing.stocks, missing.cpu_level, missing.match_timer_seconds, DEFAULT_STOCKS, DEFAULT_CPU, DEFAULT_TIMER])
		print("FAIL %s !== true" % str(defaults_ok))
		missing.free()
		quit(1)
		return
	missing.free()
	print("PASS save rules roundtrip")
	quit(0)
