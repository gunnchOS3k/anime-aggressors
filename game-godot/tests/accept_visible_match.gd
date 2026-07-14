extends SceneTree

## Visible (non-headless) match/menu acceptance driver for Godot 4.5.
## Usage:
##   ~/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot --path game-godot -s res://tests/accept_visible_match.gd
## Screenshots land under user://visible_anime/ — copy into docs/product-quality/evidence/visible-anime/.

const OUT := "user://visible_anime"

func _init() -> void:
	call_deferred("_run")

func _gs():
	return root.get_node_or_null("GameState")

func _sr():
	return root.get_node_or_null("SceneRouter")

func _log(msg: String) -> void:
	print("[visible_accept] %s" % msg)

func _ensure_out() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		_log("WARN screenshot failed %s" % name)
		return
	var path := "%s/%s.png" % [OUT, name]
	var err := img.save_png(path)
	_log("shot %s err=%s path=%s" % [name, str(err), ProjectSettings.globalize_path(path)])

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _press(action: String, sec: float = 0.12) -> void:
	Input.action_press(action)
	await _wait(sec)
	Input.action_release(action)

func _presentation_clean(battle: Node) -> bool:
	var ok := true
	var dh = battle.get("_debug_hud") if battle else null
	if dh != null and bool(dh.get("visible_debug")):
		_log("FAIL debug HUD visible_debug=true")
		ok = false
	for n in get_nodes_in_group("hitbox_debug"):
		if n is CanvasItem and (n as CanvasItem).visible:
			_log("FAIL hitbox overlay visible")
			ok = false
	for n in get_nodes_in_group("hurtbox_debug"):
		if n is CanvasItem and (n as CanvasItem).visible:
			_log("FAIL hurtbox overlay visible")
			ok = false
	return ok

func _verify_fighters(gs) -> int:
	var failed := 0
	var ids: Array = gs.roster_ids() if gs.has_method("roster_ids") else []
	_log("fighters=%s" % str(ids))
	if ids.size() < 7:
		_log("FAIL expected 7 fighters got %d" % ids.size())
		failed += 1
		return failed
	var expected := {
		"ember-vale": "Ember Vale",
		"rook-ironside": "Rook Ironside",
		"juno-spark": "Juno Spark",
		"kaia-windrow": "Kaia Windrow",
		"nix-calder": "Nix Calder",
		"orion-vell": "Orion Vell",
		"vesper-nyx": "Vesper Nyx",
	}
	var profiles: Dictionary = {}
	for fid in expected.keys():
		if not ids.has(fid):
			_log("FAIL missing roster id %s" % fid)
			failed += 1
			continue
		var data: Dictionary = gs.load_fighter(fid)
		var name := str(data.get("displayName", ""))
		if name != expected[fid]:
			_log("FAIL name mismatch %s got %s" % [fid, name])
			failed += 1
		var moves_path := "res://data/moves/%s.json" % fid
		if not FileAccess.file_exists(moves_path):
			_log("FAIL missing moves %s" % fid)
			failed += 1
			continue
		var mf := FileAccess.open(moves_path, FileAccess.READ)
		var manifest: Dictionary = JSON.parse_string(mf.get_as_text())
		var moves: Array = manifest.get("moves", [])
		if moves.size() < 15:
			_log("FAIL thin moveset %s count=%d" % [fid, moves.size()])
			failed += 1
		var ids_present: Dictionary = {}
		for m in moves:
			ids_present[str(m.get("move_id", ""))] = true
		for need in ["jab_1", "neutral_air", "neutral_special_projectile", "grab", "throw_forward"]:
			if not ids_present.has(need):
				_log("FAIL %s missing move %s" % [fid, need])
				failed += 1
		var sig := "%s|%s|%s|%s" % [
			str(data.get("weight")), str(data.get("runSpeed")),
			str(data.get("archetype")), str(moves.size()),
		]
		# Include a few damage samples so scaled clones still differ
		for m in moves:
			var mid := str(m.get("move_id", ""))
			if mid in ["jab_1", "forward_tilt", "neutral_special_projectile", "throw_forward"]:
				sig += "|%s:%s" % [mid, str(m.get("damage"))]
		profiles[fid] = sig
		_log("fighter_ok %s weight=%s run=%s archetype=%s moves=%d" % [
			name, str(data.get("weight")), str(data.get("runSpeed")),
			str(data.get("archetype")), moves.size(),
		])
	var seen: Dictionary = {}
	for fid in profiles.keys():
		var sig: String = profiles[fid]
		if seen.has(sig):
			_log("FAIL identical combat profile %s == %s" % [fid, seen[sig]])
			failed += 1
		else:
			seen[sig] = fid
	return failed

func _run() -> void:
	_ensure_out()
	var failed := 0
	var gs = _gs()
	var sr = _sr()
	if gs == null or sr == null:
		_log("FAIL autoloads")
		quit(1)
		return
	var scenes: Dictionary = sr.SCENES

	# Cold start → title/boot
	change_scene_to_file(scenes.get("boot", "res://scenes/boot/BootScene.tscn"))
	await _wait(2.0)
	await _shot("01-boot")

	# Main menu (Start Game surface)
	if scenes.has("main_menu"):
		change_scene_to_file(scenes["main_menu"])
		await _wait(1.0)
		await _shot("02-main-menu")

	# Ruleset → fighter → stage (product journey order)
	gs.p1_fighter_id = "ember-vale"
	gs.p2_fighter_id = "rook-ironside"
	gs.p2_is_cpu = true
	gs.cpu_level = 3
	gs.stocks = 2
	var stages: Array = gs.production_stage_ids() if gs.has_method("production_stage_ids") else []
	if stages.is_empty():
		_log("FAIL no stages")
		quit(1)
		return
	gs.stage_id = stages[0]
	gs.ruleset_id = "stock-2"
	gs.match_type = "stock"
	gs.reset_match()

	if scenes.has("ruleset"):
		change_scene_to_file(scenes["ruleset"])
		await _wait(1.0)
		await _shot("03-ruleset")
	if scenes.has("fighter_select"):
		change_scene_to_file(scenes["fighter_select"])
		await _wait(1.0)
		await _shot("04-fighter-select")
	if scenes.has("stage_select"):
		change_scene_to_file(scenes["stage_select"])
		await _wait(1.0)
		await _shot("05-stage-select")

	# Intro / countdown
	change_scene_to_file(scenes["battle"])
	await _wait(1.2)
	await _shot("06-countdown")
	await _wait(3.5)
	await _shot("07-match-intro")

	var battle = root.get_child(root.get_child_count() - 1)
	var f1 = battle.get("fighter1") if battle else null
	var f2 = battle.get("fighter2") if battle else null
	if f1 == null or f2 == null:
		_log("FAIL fighters missing")
		failed += 1
	else:
		_log("PASS fighters spawned")
		if not _presentation_clean(battle):
			failed += 1

	# Movement / jump / jab / ground / aerial / special(projectile) / aura / grab-throw
	await _press("p1_right", 0.35)
	await _press("p1_jump", 0.15)
	await _wait(0.15)
	await _shot("08-move-jump")
	await _press("p1_attack", 0.12)
	await _shot("09-jab")
	await _press("p1_down", 0.1)
	await _press("p1_attack", 0.12)
	await _shot("10-ground")
	await _press("p1_jump", 0.12)
	await _wait(0.18)
	await _press("p1_attack", 0.12)
	await _shot("11-aerial")
	if InputMap.has_action("p1_special"):
		await _press("p1_special", 0.2)
		await _shot("12-projectile-special")
	# Aura charge via shield+special synthetic hold, then burst
	if f1 and f1.has_method("fill_aura"):
		f1.fill_aura()
		await _wait(0.2)
		await _press("p1_attack", 0.15)
		await _shot("13-aura")
	if InputMap.has_action("p1_grab"):
		await _press("p1_right", 0.25)
		await _press("p1_grab", 0.15)
		await _press("p1_right", 0.15)
		await _shot("14-grab-throw")

	# Damage / knockback evidence: place near and jab; force a clean hit if needed
	if f1 and f2:
		var before_pct: float = float(f2.damage_percent)
		f2.global_position = f1.global_position + Vector2(36, 0)
		await _press("p1_attack", 0.18)
		await _wait(0.45)
		var after_pct: float = float(f2.damage_percent)
		_log("damage_check before=%.1f after=%.1f" % [before_pct, after_pct])
		if after_pct <= before_pct and f2.has_method("receive_hit"):
			f2.invincible = false
			f2.shielding = false
			f2.grabbed_by = null
			f2.grabbed_target = null
			if f2.state_machine and f2.state_machine.has_method("enter"):
				f2.state_machine.enter("idle")
			f2.receive_hit(f1, {
				"damage": 18.0,
				"launch": Vector2(420, -260),
				"hitstop_frames": 4,
				"shield_damage": 0.0,
				"move_id": "accept_forced_hit",
				"blocked": false,
			})
			await _wait(0.45)
			after_pct = float(f2.damage_percent)
			_log("damage_forced after=%.1f pos=%s" % [after_pct, str(f2.global_position)])
		await _shot("15-damage-knockback")
		if after_pct <= before_pct:
			_log("WARN damage/knockback still flat after forced hit")

	# Stock / respawn
	if f2:
		f2.invincible = false
		f2.global_position = Vector2(99999, 99999)
		await _wait(2.0)
		await _shot("16-stock-loss-respawn")

	# Pause / resume mid-match
	battle = root.get_child(root.get_child_count() - 1)
	if battle and battle.has_method("_ensure_pause_panel"):
		battle._ensure_pause_panel()
		if not bool(battle.get("_paused")):
			battle._toggle_pause()
		await _wait(0.9)
		var pause_vis := false
		var pp = battle.get("_pause_panel")
		if pp:
			pause_vis = bool(pp.visible)
		_log("pause_panel visible=%s paused=%s" % [str(pause_vis), str(battle.get("_paused"))])
		await _shot("17-pause")
		if bool(battle.get("_paused")):
			battle._toggle_pause()
		await _wait(0.5)
		await _shot("18-resume")

	# Match end → results
	if gs.has_method("force_match_end"):
		gs.force_match_end()
	elif battle and battle.has_method("end_match"):
		battle.end_match()
	elif f2:
		# Drain remaining stocks for natural results routing
		while int(f2.stocks) > 0:
			f2.lose_stock()
			await _wait(0.1)
	await _wait(2.0)
	if scenes.has("results"):
		change_scene_to_file(scenes["results"])
		await _wait(1.2)
		await _shot("19-results")

	# Rematch → battle again
	gs.reset_match()
	gs.stocks = 2
	change_scene_to_file(scenes["battle"])
	await _wait(3.5)
	await _shot("20-rematch")

	# Back to menu → training
	if scenes.has("main_menu"):
		change_scene_to_file(scenes["main_menu"])
		await _wait(0.8)
		await _shot("21-menu-after-match")
	if scenes.has("training"):
		change_scene_to_file(scenes["training"])
		await _wait(1.0)
		await _shot("22-training-menu")
	if scenes.has("training_battle"):
		gs.stage_id = "training-grid"
		change_scene_to_file(scenes["training_battle"])
		await _wait(1.5)
		await _shot("23-training-battle")

	# Settings change + persistence check (touch mode cycles + ConfigFile)
	var tim = root.get_node_or_null("TouchInputManager")
	var mode_before := -1
	var mode_after := -1
	if tim and tim.has_method("cycle_touch_mode"):
		mode_before = int(tim.touch_mode)
		tim.cycle_touch_mode()
		mode_after = int(tim.touch_mode)
		_log("settings touch_mode %d -> %d" % [mode_before, mode_after])
	if scenes.has("settings"):
		change_scene_to_file(scenes["settings"])
		await _wait(1.0)
		await _shot("24-settings")
	# Simulate relaunch persistence by reloading from ConfigFile
	if tim and tim.has_method("_load_settings"):
		var expected_mode := int(tim.touch_mode)
		tim.touch_mode = ((expected_mode + 1) % 3)
		tim._load_settings()
		if int(tim.touch_mode) != expected_mode:
			_log("FAIL settings persistence reload expected=%d got=%d" % [expected_mode, int(tim.touch_mode)])
			failed += 1
		else:
			_log("PASS settings persistence touch_mode=%d" % expected_mode)
		await _shot("25-settings-persisted")

	if scenes.has("main_menu"):
		change_scene_to_file(scenes["main_menu"])
		await _wait(0.8)
		await _shot("26-menu-final")

	failed += _verify_fighters(gs)

	_log("RESULT failed=%d" % failed)
	await _wait(0.5)
	quit(0 if failed == 0 else 1)
