extends RefCounted

## Shared playable objective machinery. Candidate acting/audio reuse existing original assets.
## Only the host BattleScene can issue an authenticated outcome receipt.
const FIGHTER := preload("res://scenes/fighters/Fighter.tscn")
var battle
var node: Dictionary
var route_state: Dictionary
var kind := ""
var actors: Array = []
var puppets: Array = []
var escorts: Array = []
var released: Array = []
var player_damage: Dictionary = {}
var player_hits := 0
var elapsed := 0.0
var guard_seconds := 0.0
var steps := 0
var alternations := 0
var decision := ""
var attacked := false
var guarded := false
var traversed := false
var identities_exercised := 0
var transformed := false
var _origin := Vector2.ZERO
var _label: Label
var _marker: Polygon2D
var _hold := 0.0
var _last_player_stocks := 0
var finished := false
var ground_y := 300.0


func setup(host, contract: Dictionary) -> void:
	battle = host
	node = contract["node"]
	route_state = contract["route_state"]
	kind = node["objective_contract"]
	ground_y = float(GameState.load_stage(GameState.stage_id).get("mainPlatform", {}).get("y", 300))
	actors = [battle.fighter1, battle.fighter2]
	_origin = battle.fighter1.position
	_last_player_stocks = battle.fighter1.stocks
	battle.fighter1.is_cpu = false
	battle.fighter1.dummy_mode = "idle"
	battle.fighter1.cpu.clear_simulated_inputs()
	_label = Label.new()
	_label.position = Vector2(30, 140)
	_label.size = Vector2(1220, 135)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 16)
	battle.hud.add_child(_label)
	_marker = Polygon2D.new()
	_marker.polygon = PackedVector2Array([Vector2(-25, -6), Vector2(25, -6), Vector2(25, 6), Vector2(-25, 6)])
	_marker.color = Color(0.8, 0.85, 1.0, 0.75)
	battle.stage_root.add_child(_marker)
	if route_state.get("form") == "PRISMATIC_GRAY" or kind.begins_with("SEVENFOLD"):
		set_form(battle.fighter1, "PRISMATIC_GRAY")
	if kind in ["PUPPET_IMBALANCE", "FIRST_RELEASE", "PUPPET_EQUILIBRIUM", "PAIRED_RELEASE"]:
		_setup_puppets()
	elif kind in ["GRAY_DEMONSTRATION", "SEVENFOLD_EQUILIBRIUM"]:
		battle.fighter2.set_meta("story_cosmic_contract", true)
		set_form(battle.fighter2, "COSMIC_BOSS")
		var yang = _spawn("yang", 3, Vector2(220, 170), 99, true)
		yang.set_meta("story_cosmic_contract", true)
		set_form(yang, "COSMIC_BOSS")
	elif kind == "SEVENFOLD_REUNION":
		var index := 0
		for fid in CampaignRuntime.campaign["spectral_order"]:
			if fid == "kaia-windrow": continue
			var actor = battle.fighter2 if index == 0 else _spawn(fid, index + 2, Vector2(-250 + index * 100, 180), 99, false)
			if index == 0: actor.configure(fid, 2, false, 99, Vector2(-250, 180))
			actor.controls_enabled = false
			actor.dummy_mode = "idle"
			actor.set_meta("story_team", "spectrum")
			actor.set_meta("story_cosmic_contract", true)
			set_form(actor, "PRISMATIC_GRAY")
			index += 1
	elif kind == "SEVENFOLD_TRIAL":
		var order: Array = CampaignRuntime.campaign["spectral_order"]
		battle.fighter1.configure(order[0], 1, false, battle.fighter1.stocks, Vector2(-140, ground_y - 2))
		GameState.p1_fighter_id = order[0]
		set_form(battle.fighter1, "PRISMATIC_GRAY")
		set_form(battle.fighter2, "PRISMATIC_GRAY")
		battle.fighter2.stocks = 1
	elif kind in ["FIRST_LOSS", "PRISMATIC_TRANSFORMATION"]:
		battle.fighter2.is_cpu = false
		battle.fighter2.dummy_mode = "idle"
		battle.fighter2.controls_enabled = false
		battle.fighter2.set_meta("story_cosmic_contract", true)
		battle.fighter2.model_3d.set_cinematic_expression("grief" if kind == "FIRST_LOSS" else "determination")
		if kind == "FIRST_LOSS":
			var interaction: String = node["consequence"]["interaction"]
			var lost_x: float = {"DECISIVE_INTERVENTION":0.0,"RESTRAINED_PROTECTION":-40.0,"SHARED_DEFENSE":250.0,"LAST_VECTOR_ESCORT":-170.0,"OPEN_BOUNDARY":220.0,"PERSONAL_VECTOR":100.0,"HONEST_SIGNAL":260.0}[interaction]
			battle.fighter2.position = Vector2(lost_x, ground_y - 2)
			battle.fighter2.model_3d.play_clip("shield_hold" if interaction == "DECISIVE_INTERVENTION" else "aura_charge")
			# The lost ally holds space while cosmic actors make traversal playable under pressure.
			for i in range(2):
				var boss = _spawn("yin" if i == 0 else "yang", i + 3, Vector2(-280 if i == 0 else 280, 160), 99, true)
				boss.set_meta("story_cosmic_contract", true)
				set_form(boss, "COSMIC_BOSS")
	if kind == "FIRST_LOSS" and node["consequence"]["interaction"] == "LAST_VECTOR_ESCORT":
		for fid in CampaignRuntime.campaign["spectral_order"]:
			if fid in [battle.fighter1.fighter_id, battle.fighter2.fighter_id]: continue
			var escort = _spawn(fid, actors.size() + 1, Vector2(-100 - escorts.size() * 25, ground_y - 2), 1, false)
			escort.dummy_mode = "idle"
			escort.controls_enabled = false
			escort.set_meta("story_team", "escape_team")
			escort.set_meta("story_cosmic_contract", true)
			escorts.append(escort)
	for actor in actors:
		actor.hit_resolver.hit_confirmed.connect(_on_hit)
		actor.koed.connect(_on_ko.bind(actor))
	for attacker in actors:
		for defender in actors:
			if attacker != defender and not (attacker == battle.fighter1 and defender == battle.fighter2) and not (attacker == battle.fighter2 and defender == battle.fighter1):
				battle._connect_hitboxes(attacker, defender)
	battle._battle_sim.bind_fighters(actors)
	if battle._battle_camera != null:
		battle._battle_camera.configure(battle.get_node("Camera2D"), battle._stage_camera_profile, actors, battle.blast)
	_update_prompt()


func _spawn(fid: String, slot: int, spawn: Vector2, stocks: int, cpu: bool):
	for suffix in ["left", "right", "up", "down", "jump", "attack", "special", "shield", "grab", "dodge", "taunt"]:
		var action := "p%d_%s" % [slot, suffix]
		if not InputMap.has_action(action): InputMap.add_action(action)
	var actor = FIGHTER.instantiate()
	battle.fighters_root.add_child(actor)
	actor.configure(fid, slot, cpu, stocks, spawn)
	var stage: Dictionary = GameState.load_stage(GameState.stage_id)
	actor.configure_stage_geometry(stage.get("mainPlatform", {}), stage.get("ledgeAnchors", []), bool(stage.get("ledges", true)))
	actors.append(actor)
	return actor


func set_form(actor, form: String) -> void:
	var data: Dictionary = actor.data.duplicate(true)
	data["collectible_review_form"] = form
	actor.data = data
	actor._model_presentation_data = data
	actor.model_3d.configure(data)
	actor.model_3d.set_form_id(form)
	actor.set_meta("story_form", form)


func _setup_puppets() -> void:
	var index := 0
	for side in ["yin", "yang"]:
		for fid in node["puppets"][side]:
			if fid in route_state.get("released", []): continue
			var actor = battle.fighter2 if index == 0 else _spawn(fid, index + 2, Vector2(-250 + index * 115, 180), 99, true)
			if index == 0: actor.configure(fid, 2, true, 99, Vector2(-250, 180))
			actor.set_meta("story_team", side)
			set_form(actor, "BLACK_PUPPET" if side == "yin" else "WHITE_PUPPET")
			puppets.append(actor)
			player_damage[fid] = 0.0
			index += 1
	battle.fighter1.set_meta("story_team", "anchor")


func _on_hit(attacker, defender, info: Dictionary) -> void:
	if attacker == battle.fighter1 and not info.get("blocked", false) and float(info.get("damage", 0)) > 0:
		if kind != "PUPPET_IMBALANCE" or defender.get_meta("story_team", "") == "yin": player_hits += 1
		StoryDialogue.fire("puppet_contact",{"target":defender.fighter_id})
		if defender in puppets:
			player_damage[defender.fighter_id] = float(player_damage.get(defender.fighter_id, 0)) + float(info["damage"])
			if float(player_damage[defender.fighter_id]) >= 40: StoryDialogue.fire("release_ready",{"target":defender.fighter_id,"earned_damage":player_damage[defender.fighter_id]})


func _on_ko(actor) -> void:
	if actor in puppets and float(player_damage.get(actor.fighter_id, 0)) >= 40:
		_release(actor)
	if kind == "SEVENFOLD_TRIAL" and actor == battle.fighter2 and battle.fighter1.stocks > 0:
		identities_exercised += 1
		if identities_exercised == 7:
			_finish()
		else:
			var order: Array = CampaignRuntime.campaign["spectral_order"]
			var stocks: int = battle.fighter1.stocks
			battle.fighter1.configure(order[identities_exercised], 1, false, stocks, Vector2(-140, ground_y - 2))
			GameState.p1_fighter_id = order[identities_exercised]
			StoryDialogue.fire("trial_identity:"+str(order[identities_exercised]),{"identity":identities_exercised})
			battle.fighter1.move_runner.cancel()
			battle.fighter1.reset_fighter()
			battle.fighter1.controls_enabled = true
			battle.fighter2.configure(order[(identities_exercised + 1) % 7], 2, true, 1, Vector2(140, 180))
			set_form(battle.fighter1, "PRISMATIC_GRAY")
			set_form(battle.fighter2, "PRISMATIC_GRAY")


func _can_release(actor) -> bool:
	if kind not in ["FIRST_RELEASE", "PAIRED_RELEASE"] or actor.fighter_id in released: return false
	var side: String = actor.get_meta("story_team", "")
	if kind == "FIRST_RELEASE" and side != "yin": return false
	for fid in released:
		if fid in node["puppets"][side]: return false
	return true


func _release(actor) -> void:
	if not _can_release(actor): return
	released.append(actor.fighter_id)
	StoryDialogue.fire("puppet_released",{"fighter":actor.fighter_id,"side":actor.get_meta("story_team","")})
	actor.cpu.clear_simulated_inputs()
	actor.is_cpu = false
	actor.dummy_mode = "idle"
	actor.controls_enabled = false
	actor.set_meta("story_released", true)
	actor.stocks = 0
	actor.set_physics_process(false)
	actor.hitbox.monitoring = false
	set_form(actor, "BASE")
	actor.model_3d.set_cinematic_expression("determination")
	actor.model_3d.play_clip("victory")
	preload("res://scripts/audio/v1_candidate_sfx.gd").play_event(actor.fighter_id, "transform", actor)
	if released.size() == (1 if kind == "FIRST_RELEASE" else 2): _finish()


func tick(delta: float) -> void:
	if finished: return
	elapsed += delta
	var p = battle.fighter1
	for actor in actors:
		if actor != p: battle._check_blast(actor)
	if p.stocks <= 0:
		finished = true
		battle._finish_match(2)
		return
	if p.stocks != _last_player_stocks:
		_hold = 0
		guard_seconds = 0
		_last_player_stocks = p.stocks
	attacked = attacked or p.move_runner.active
	guarded = guarded or p.shielding
	traversed = traversed or absf(p.position.x - _origin.x) > 180
	match kind:
		"FIRST_LOSS":
			_tick_loss_framing(delta)
			_tick_loss(delta)
		"PUPPET_IMBALANCE":
			_marker.position = Vector2(0, ground_y)
			if player_hits > 0 and absf(p.position.x) < 100 and p.shielding: guard_seconds += delta
			if guard_seconds >= 2: _finish()
		"FIRST_RELEASE", "PAIRED_RELEASE":
			_marker.visible = false
			if Input.is_action_just_pressed("p1_special"):
				var nearest = null
				for actor in puppets:
					if not _can_release(actor) or float(player_damage.get(actor.fighter_id, 0)) < 40: continue
					if p.position.distance_to(actor.position) < 110 and (nearest == null or p.position.distance_to(actor.position) < p.position.distance_to(nearest.position)):
						nearest = actor
				if nearest != null: _release(nearest)
		"PUPPET_EQUILIBRIUM":
			_marker.position = Vector2(0, ground_y)
			if absf(p.position.x) < 120 and p.shielding:
				guard_seconds += delta
				StoryDialogue.fire("center_guard")
			if guard_seconds >= 8: _finish()
		"PRISMATIC_TRANSFORMATION":
			if route_state.get("essence", 0) != 6: return
			if steps < 6:
				_visit_marker(Vector2(-250 + steps * 100, ground_y))
			elif p.shielding:
				StoryDialogue.fire("gray_signals_collected",{"signals":steps})
				_hold += delta
				if _hold >= 2 and not transformed:
					StoryDialogue.fire("transformation_started")
					set_form(p, "PRISMATIC_GRAY")
					p.model_3d.play_clip("aura_charge")
					p.model_3d.set_cinematic_expression("determination")
					preload("res://scripts/audio/v1_candidate_sfx.gd").play_event(p.fighter_id, "transform", p)
					transformed = true
					StoryDialogue.fire("gray_manifested",{"form":"PRISMATIC_GRAY"})
				if _hold >= 4: _finish()
		"GRAY_DEMONSTRATION":
			_marker.position = Vector2(250, ground_y)
			if elapsed >= 18 and attacked and guarded and traversed: _finish()
		"SEVENFOLD_REUNION":
			if steps < 6: _visit_marker(Vector2(-250 + steps * 100, ground_y))
			if steps == 6: _finish()
		"SEVENFOLD_EQUILIBRIUM":
			var target := Vector2(-180 if alternations % 2 == 0 else 180, ground_y)
			_marker.position = target
			if p.position.distance_to(target + Vector2(0, -2)) < 85 and p.shielding:
				_hold += delta
				if _hold >= 0.6:
					alternations += 1
					StoryDialogue.fire("equilibrium_signal",{"alternation":alternations})
					_hold = 0
			if elapsed >= 21 and alternations >= 6: _finish()
	_update_prompt()


func _visit_marker(target: Vector2) -> void:
	_marker.position = target
	if battle.fighter1.position.distance_to(target + Vector2(0, -2)) < 65:
		steps += 1
		StoryDialogue.fire("first_loss_signal",{"step":steps})
		StoryDialogue.fire("reunion_signal",{"step":steps})


func _tick_loss(delta: float) -> void:
	var p = battle.fighter1
	var interaction: String = node["consequence"]["interaction"]
	match interaction:
		"LAST_VECTOR_ESCORT":
			if decision.is_empty():
				_marker.position = Vector2(-140, ground_y)
				if Input.is_action_just_pressed("p1_shield"):
					decision = "ESCORT_TEAM"
					StoryDialogue.fire("decision_made",{"choice":decision})
				return
			for escort in escorts:
				if escort.has_meta("escort_target_x"):
					escort.position.x = move_toward(escort.position.x, float(escort.get_meta("escort_target_x")), 220.0 * delta)
			var previous_steps := steps
			if steps < 2: _visit_marker(Vector2(80 if steps == 0 else 280, ground_y))
			if steps > previous_steps:
				for i in range(escorts.size()):
					escorts[i].set_meta("escort_target_x", (80 if steps == 1 else 280) - i * 18)
					escorts[i].model_3d.play_clip("run")
					escorts[i].model_3d.set_cinematic_expression("determination")
		"RESTRAINED_PROTECTION":
			_marker.position = Vector2(-80, ground_y)
			if steps == 0:
				if p.position.distance_to(Vector2(-80, ground_y - 2)) < 90 and p.shielding and not p.move_runner.active: _hold += delta
				else: _hold = 0
				if _hold >= 2: steps = 1
			elif steps == 1: _visit_marker(Vector2(220, ground_y))
		"SHARED_DEFENSE":
			_marker.position = Vector2(180, ground_y)
			if p.position.distance_to(Vector2(180, ground_y - 2)) < 80 and p.shielding: _hold += delta
			if steps == 0 and _hold >= 1: steps = 1
			if steps == 1: _visit_marker(Vector2(-180, ground_y))
		"OPEN_BOUNDARY":
			_marker.position = Vector2(-220, ground_y)
			if steps == 0 and p.position.distance_to(Vector2(-220, ground_y - 2)) < 80 and Input.is_action_just_pressed("p1_special"): steps = 1
			if steps == 1: _visit_marker(Vector2(220, ground_y))
		"PERSONAL_VECTOR":
			_marker.position = Vector2(100, ground_y)
			if steps == 0 and p.position.distance_to(Vector2(100, ground_y - 2)) < 80 and p.shielding:
				_hold += delta
				if _hold >= 1.5: steps = 1
			if steps == 1: _visit_marker(Vector2(-200, ground_y))
		"HONEST_SIGNAL":
			_marker.position = Vector2(0, ground_y)
			if steps == 0 and absf(p.position.x) < 80 and Input.is_action_just_pressed("p1_special"): steps = 1
			if steps == 1: _visit_marker(Vector2(260, ground_y))
		"DECISIVE_INTERVENTION":
			if steps == 0:
				_marker.position = Vector2(0, ground_y)
				if absf(p.position.x) < 80 and p.move_runner.active: steps = 1
			elif steps == 1: _visit_marker(Vector2(240, ground_y))
	if steps > 0: StoryDialogue.fire("decision_made",{"interaction":interaction})
	if steps >= 2:
		_hold += delta
		if _hold >= 1.5:
			battle.fighter2.model_3d.set_cinematic_expression("grief")
			_finish()


func evidence() -> Dictionary:
	return {"objective_complete":finished, "elapsed":elapsed, "interaction":node.get("consequence", {}).get("interaction", ""),
		"decision":decision, "escorted_fighters":escorts.map(func(actor): return actor.fighter_id) if steps >= 2 else [], "steps":steps, "yin_count":node.get("puppets", {}).get("yin", []).size() - _prior_releases("yin"),
		"yang_count":node.get("puppets", {}).get("yang", []).size() - _prior_releases("yang"), "player_hits":player_hits,
		"guard_seconds":guard_seconds, "released":released.duplicate(), "player_damage":player_damage.duplicate(),
		"perspectives":route_state.get("essence", 0), "form":"PRISMATIC_GRAY" if transformed or route_state.get("form") == "PRISMATIC_GRAY" or kind.begins_with("SEVENFOLD") else "BASE",
		"attack":attacked, "guard":guarded, "traversal":traversed, "identities_exercised":identities_exercised, "alternations":alternations}


func _prior_releases(side: String) -> int:
	var count := 0
	for fid in route_state.get("released", []):
		if fid in node.get("puppets", {}).get(side, []): count += 1
	return count


func _finish() -> void:
	finished = true
	battle._finish_match(1)


func _update_prompt() -> void:
	_label.text = str(node.get("objective", ""))
	if kind == "FIRST_LOSS":
		_label.text += "\n" + {"LAST_VECTOR_ESCORT":"Orion holds the passage. Shield chooses to escort the team; then reach the two forward signals.", "RESTRAINED_PROTECTION":"Guard at the left signal for two seconds without attacking, then reach the right signal.", "SHARED_DEFENSE":"Guard beside the right signal, then leave a path to the left signal.", "OPEN_BOUNDARY":"Special opens the left boundary. Then follow Vesper's signal to the right.", "PERSONAL_VECTOR":"Listen with Shield at Kaia's signal on the right, then follow the left vector.", "HONEST_SIGNAL":"Special at the center reveals the path; follow the right signal.", "DECISIVE_INTERVENTION":"Attack at the center to intervene, then reach the right signal."}[node["consequence"]["interaction"]]
	if kind == "PUPPET_IMBALANCE":
		_label.text += "\nYin hit: %s · Center guard: %.1f / 2s" % ["confirmed" if player_hits > 0 else "needed", guard_seconds]
	elif kind == "PUPPET_EQUILIBRIUM":
		_label.text += "\nCenter guard: %.1f / 8s. Release Shield to move; guard may be interrupted by hits." % guard_seconds
	elif kind in ["FIRST_RELEASE", "PAIRED_RELEASE"]:
		var targets := PackedStringArray()
		for actor in puppets:
			var status := "RELEASED" if actor.fighter_id in released else "READY: K nearby" if _can_release(actor) and float(player_damage.get(actor.fighter_id,0)) >= 40 else "%d/40 earned" % int(player_damage.get(actor.fighter_id,0))
			targets.append("%s %s: %s" % [actor.get_meta("story_team", "").to_upper(), actor.data.get("displayName",actor.fighter_id), status])
		_label.text += "\n" + " · ".join(targets)
	elif kind == "PRISMATIC_TRANSFORMATION":
		_label.text += "\nSignals: %d/6 · Integration: %.1f/4s · %s" % [steps, _hold, "Gray manifested" if transformed else "walk off the upper platform; collect each ground signal, then guard"]
	elif kind in ["GRAY_DEMONSTRATION", "SEVENFOLD_EQUILIBRIUM"]:
		_label.text += "\nElapsed: %.1fs · Attack: %s · Guard: %s · Traversal: %s" % [elapsed, attacked, guarded, traversed]
		if kind == "SEVENFOLD_EQUILIBRIUM":
			_label.text += "\nGround signals: guard %s for 0.6s · Alternations: %d/6 · Survive at least 21s" % ["LEFT" if alternations%2==0 else "RIGHT",alternations]
	_label.text += "\nA/D Move · W Jump · J Attack · J+K Heavy · K Special/release · L Shield · U Grab · I Dodge"
	_label.text += "\nEssences: %d · Steps: %d · Released: %d · Guard: %.1fs" % [route_state.get("essence", 0), steps, released.size(), guard_seconds]


func activate_controls() -> void:
	if kind == "SEVENFOLD_TRIAL": StoryDialogue.fire("trial_identity:"+battle.fighter1.fighter_id,{"identity":0})
	for actor in actors:
		var passive: bool = actor in escorts or (kind in ["FIRST_LOSS", "PRISMATIC_TRANSFORMATION", "SEVENFOLD_REUNION"] and actor == battle.fighter2) or (kind == "SEVENFOLD_REUNION" and actor != battle.fighter1)
		actor.controls_enabled = not passive


func _tick_loss_framing(delta: float) -> void:
	# Brief route-specific candidate staging; player physics and control remain live.
	var controller = battle._battle_camera
	var camera := battle.get_node("Camera2D") as Camera2D
	if elapsed >= 1.5:
		if controller != null: controller.set_process(true)
		return
	if controller != null: controller.set_process(false)
	var p: Vector2 = battle.fighter1.position
	var lost: Vector2 = battle.fighter2.position
	var interaction: String = node["consequence"]["interaction"]
	var target := (p + lost) * 0.5
	var zoom := 1.0
	match interaction:
		"DECISIVE_INTERVENTION": target = lost.lerp(p, clampf(elapsed / 1.5, 0, 1)); zoom = 1.0
		"RESTRAINED_PROTECTION": target = p + Vector2(60, -20); zoom = 1.16
		"SHARED_DEFENSE": target = (p + lost) * 0.5; zoom = 0.94
		"LAST_VECTOR_ESCORT": target = lost if elapsed < 0.65 else p + Vector2(80, 0); zoom = 1.08
		"OPEN_BOUNDARY": target = lost + Vector2(-70, 0); zoom = 1.03
		"PERSONAL_VECTOR": target = lost.lerp(p, 0.35); zoom = 1.12
		"HONEST_SIGNAL": target = p; zoom = 1.20
	camera.position = camera.position.lerp(target + Vector2(0, -45), 1.0 - exp(-delta * 6.0))
	camera.zoom = Vector2.ONE * zoom
	battle.set_meta("first_loss_framing", interaction)
