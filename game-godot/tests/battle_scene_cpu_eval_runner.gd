extends SceneTree

## Real BattleScene CPU matrix runner (7×7 × tiers).
## Usage:
##   Godot --headless --path game-godot -s res://tests/battle_scene_cpu_eval_runner.gd
## Env:
##   AA_CPU_EVAL_TIERS=1,2,3,4,5   (default 1,2,3,4,5)
##   AA_CPU_EVAL_TIME_SCALE=24
##   AA_CPU_EVAL_SEED=42

const _BattleSceneCpuEval = preload("res://scripts/battle/battle_scene_cpu_eval.gd")

const STAGES := ["skyline-arena", "neon-rooftops", "cascade-foundry", "void-pier", "ember-courtyard"]


func _init() -> void:
	call_deferred("_run")


func _parse_tiers() -> Array:
	var env := OS.get_environment("AA_CPU_EVAL_TIERS")
	if env.strip_edges() == "":
		return [1, 2, 3, 4, 5]
	var out: Array = []
	for part in env.split(","):
		var n := int(part.strip_edges())
		if n >= 1 and n <= 5:
			out.append(n)
	return out if out.size() > 0 else [1, 2, 3, 4, 5]


func _run() -> void:
	var gs = root.get_node_or_null("GameState")
	var sr = root.get_node_or_null("SceneRouter")
	if gs == null or sr == null:
		push_error("autoloads missing")
		quit(1)
		return
	var tiers: Array = _parse_tiers()
	var base_seed := int(OS.get_environment("AA_CPU_EVAL_SEED")) if OS.get_environment("AA_CPU_EVAL_SEED") != "" else 42
	var time_scale := float(OS.get_environment("AA_CPU_EVAL_TIME_SCALE")) if OS.get_environment("AA_CPU_EVAL_TIME_SCALE") != "" else 28.0
	Engine.time_scale = maxf(1.0, time_scale)
	print("[cpu_eval] REAL BattleScene matrix tiers=%s seed=%d time_scale=%.1f" % [str(tiers), base_seed, Engine.time_scale])
	var results: Array = []
	var match_i := 0
	var expected := ROSTER_SIZE() * ROSTER_SIZE() * tiers.size()
	for tier in tiers:
		for i in range(_BattleSceneCpuEval.ROSTER.size()):
			for j in range(_BattleSceneCpuEval.ROSTER.size()):
				match_i += 1
				var p1: String = _BattleSceneCpuEval.ROSTER[i]
				var p2: String = _BattleSceneCpuEval.ROSTER[j]
				var seed_i: int = base_seed + int(tier) * 10007 + i * 97 + j * 13
				var stage: String = STAGES[(i + j + int(tier)) % STAGES.size()]
				print("[cpu_eval] %d/%d %s vs %s tier=%d" % [match_i, expected, p1, p2, int(tier)])
				_BattleSceneCpuEval.configure_match(p1, p2, int(tier), seed_i, stage)
				change_scene_to_file(sr.SCENES["battle"])
				# Wait until eval finishes or safety wall-clock budget.
				var frames_waited := 0
				while not bool(gs.battle_eval_finished) and frames_waited < 9000:
					await process_frame
					frames_waited += 1
				var outcome: Dictionary = gs.battle_eval_result.duplicate(true)
				if outcome.is_empty():
					outcome = {
						"ok": false,
						"error": "eval_timeout_or_empty",
						"p1": p1,
						"p2": p2,
						"cpu_level": int(tier),
						"seed": seed_i,
						"frames_waited": frames_waited,
					}
				else:
					outcome["ok"] = true
					outcome["tier"] = int(tier)
					outcome["matchup"] = "%s_vs_%s" % [p1, p2]
					var wslot := int(outcome.get("winner_slot", 1))
					outcome["winner_id"] = p1 if wslot == 1 else p2
					outcome["hidden_state_cheat"] = false
					outcome["observation_cpu"] = true
					outcome["real_battle_scene"] = true
				results.append(outcome)
				# Unload battle before next
				gs.battle_eval_mode = false
				gs.battle_eval_finished = false
	Engine.time_scale = 1.0
	var report: Dictionary = _BattleSceneCpuEval.summarize_matrix(results, tiers, base_seed)
	# Strip bulky per-match dumps optionally? Keep them for evidence.
	var evidence_dir := ProjectSettings.globalize_path("res://").path_join("../playtest-evidence")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var abs_path := evidence_dir.path_join("cpu_battle_scene_eval.json")
	# Write compact summary + results
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(report, "\t"))
		f.close()
		print("[cpu_eval] evidence=%s" % abs_path)
	var user_path := "user://cpu_battle_scene_eval.json"
	_BattleSceneCpuEval.write_evidence(report, user_path)
	print("[cpu_eval] matches=%d decisive=%d timeouts=%d errors=%d diversity=%s" % [
		int(report.get("match_count", 0)),
		int(report.get("decisive_count", 0)),
		int(report.get("timeout_count", 0)),
		int(report.get("error_count", 0)),
		str(report.get("diversity", {})),
	])
	print("[cpu_eval] token_earned=%s token=%s" % [str(report.get("token_earned")), str(report.get("token"))])
	if int(report.get("error_count", 1)) > 0 or int(report.get("match_count", 0)) < expected:
		push_error("cpu eval incomplete")
		quit(1)
		return
	print("[cpu_eval] OK")
	quit(0)


func ROSTER_SIZE() -> int:
	return _BattleSceneCpuEval.ROSTER.size()
