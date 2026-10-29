extends RefCounted
class_name TrialsSharedCombatBridge
## Wire Trials modes onto live BattleScene / shared combat overlay.
## Does NOT fork fighter combat — applies GameState modifiers + mounts overlay HUD.
## Unbound never feeds ranked MMR. Everlasting Origin only via mythic consent.
## Resolves GameState via scene-tree (not autoload identifier) so headless --script suites compile.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const Seats = preload("res://scripts/trials/partylink_seat_enforcement.gd")
const Presentation = preload("res://scripts/trials/mode_presentation.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")
const Derby = preload("res://scripts/trials/derby/resonance_trial_sim.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")
const Colossus = preload("res://scripts/trials/unbound/colossus_rig.gd")

## Modes that can enter shared BattleScene combat with overlay (not journey-only).
const LIVE_SHARED_COMBAT_MODES := ["resonance_trial", "fractured_accord", "convergence_unbound"]


static func _gs() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("GameState")


static func supports_live_shared_combat(mode_id: String) -> bool:
	return mode_id in LIVE_SHARED_COMBAT_MODES


static func scale_hit_info(info: Dictionary) -> Dictionary:
	## Shared combat path: scale damage/knockback from GameState trial modifiers.
	var gs := _gs()
	if gs == null or str(gs.mode) != "trials":
		return info
	var out: Dictionary = info.duplicate(true)
	var dr: float = float(gs.damage_ratio)
	var kb: float = float(gs.trial_knockback_mult)
	if not is_equal_approx(dr, 1.0):
		if out.has("resolved_damage"):
			out["resolved_damage"] = float(out.get("resolved_damage", 0.0)) * dr
		if out.has("damage"):
			out["damage"] = float(out.get("damage", 0.0)) * dr
	if not is_equal_approx(kb, 1.0) and out.has("launch") and typeof(out["launch"]) == TYPE_VECTOR2:
		out["launch"] = out["launch"] * kb
	return out


static func prepare_live_battle(mode_id: String, seats: int = 2, unbound_preset: String = Unbound.PRESET_TOTAL) -> Dictionary:
	## Configure GameState for BattleScene entry. Returns honesty + presentation payload.
	var gs := _gs()
	if gs == null:
		return {"ok": false, "reason": "gamestate_missing", "SHIPPING_ROLLBACK_ENABLED": false}
	var gate: Dictionary = Seats.enforce(mode_id, seats, seats)
	if not bool(gate.get("ok", false)) and mode_id != "resonance_trial":
		## Solo Resonance is allowed; multiplayer-promise modes must pass seat gate.
		if int(Authority.player_count_truth(mode_id).get("min", 1)) >= 2:
			return {"ok": false, "gate": gate, "SHIPPING_ROLLBACK_ENABLED": false}
	var seated: int = int(gate.get("seated", seats)) if bool(gate.get("ok", false)) else clampi(seats, 1, 2)
	gs.begin_trial(mode_id, seated)
	gs.trial_live_combat = true
	gs.trial_unbound_preset = unbound_preset
	gs.feeds_trial_ranked_mmr = false
	var presentation: Dictionary = Presentation.for_mode(mode_id, gs.match_seed)
	var applied: Dictionary = {}
	match mode_id:
		"convergence_unbound":
			applied = _apply_unbound(gs, unbound_preset, seated)
			presentation = Presentation.unbound_colossus(gs.match_seed, unbound_preset)
		"resonance_trial":
			applied = _apply_derby(gs)
			presentation = Presentation.derby(gs.match_seed)
		"fractured_accord":
			applied = _apply_flagline(gs, seated)
			presentation = Presentation.flagline_territory(gs.match_seed, 0)
		_:
			applied = {"note": "journey_only"}
	gs.trial_overlay_state = {
		"mode_id": mode_id,
		"presentation": presentation,
		"applied": applied,
		"gate": gate,
		"feeds_ranked_mmr": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"HUMAN_ART_APPROVED": false,
	}
	return {
		"ok": true,
		"mode_id": mode_id,
		"seated": seated,
		"gate": gate,
		"applied": applied,
		"presentation": presentation,
		"feeds_ranked_mmr": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
	}


static func _apply_unbound(gs: Node, preset_id: String, seats: int) -> Dictionary:
	var session: Dictionary = Unbound.create_session(
		gs.match_seed if gs.match_seed != 0 else 42,
		preset_id,
		gs.mythic_party_consent,
		seats
	)
	var rules: Dictionary = session.get("rules", Unbound.preset(preset_id))
	gs.damage_ratio = float(rules.get("damage_mult", 1.35))
	gs.trial_knockback_mult = float(rules.get("knockback_mult", 1.85))
	gs.stocks = int(rules.get("stocks", 7))
	var timer_s: int = int(rules.get("timer_seconds", 0))
	gs.match_timer_seconds = timer_s
	gs.match_type = "stock_untimed" if timer_s <= 0 else "stock"
	gs.ruleset_id = "trial-unbound-%s" % str(rules.get("preset_id", preset_id))
	gs.hazards_enabled = false
	gs.items_enabled = false
	gs.p2_is_cpu = seats < 2
	## Colossus camera scaffold merges into stage profile when preset enables giants.
	var cam: Dictionary = {}
	if bool(rules.get("colossus_enabled", false)):
		session = Unbound.advance_journey(session)
		session = Unbound.advance_journey(session)
		var rigs: Array = session.get("colossus_rigs", [])
		if not rigs.is_empty():
			cam = Colossus.camera_profile_for_battle(rigs[0])
		gs.trial_colossus_rigs = rigs
	else:
		gs.trial_colossus_rigs = []
	gs.trial_camera_profile = cam
	return {
		"label": Unbound.LABEL,
		"preset": rules.get("preset_id", preset_id),
		"damage_ratio": gs.damage_ratio,
		"knockback_mult": gs.trial_knockback_mult,
		"stocks": gs.stocks,
		"everlasting_permitted": bool(session.get("everlasting_permitted", false)),
		"feeds_ranked_mmr": false,
		"camera_profile": cam,
		"shipping": Authority.shipping_flags_false(),
	}


static func _apply_derby(gs: Node) -> Dictionary:
	## Shared fighter combat overlay for Resonance — 10s contract chrome; dummy as CPU idle.
	gs.damage_ratio = 1.0
	gs.trial_knockback_mult = 1.0
	gs.stocks = 99
	gs.match_timer_seconds = 10
	gs.match_type = "stock"
	gs.ruleset_id = "trial-resonance-live"
	gs.p2_is_cpu = true
	gs.p2_fighter_id = "rook-ironside"  # stand-in dummy body until dedicated dummy actor
	gs.training_dummy_mode = "idle"
	gs.trial_colossus_rigs = []
	gs.trial_camera_profile = {}
	var sim: Dictionary = Derby.create(gs.match_seed if gs.match_seed != 0 else 42, gs.p1_fighter_id)
	gs.trial_sim_snapshot = sim
	return {
		"contract_seconds": 10,
		"kinetic_bat": true,
		"dummy_standin": true,
		"feeds_ranked_mmr": false,
		"shipping": Authority.shipping_flags_false(),
	}


static func _apply_flagline(gs: Node, seats: int) -> Dictionary:
	gs.damage_ratio = 1.0
	gs.trial_knockback_mult = 1.0
	gs.stocks = 3
	gs.match_timer_seconds = 180
	gs.match_type = "stock"
	gs.ruleset_id = "trial-fractured-accord-live"
	gs.team_mode = true
	gs.team_size = 2
	gs.p2_is_cpu = seats < 2
	gs.trial_colossus_rigs = []
	gs.trial_camera_profile = {"minZoom": 0.75, "maxZoom": 1.25, "lerp": 0.14}
	var sim: Dictionary = Flagline.create(gs.match_seed if gs.match_seed != 0 else 42, 0)
	gs.trial_sim_snapshot = sim
	return {
		"rooms": [-2, -1, 0, 1, 2],
		"aliases": Flagline.DISPLAY_ALIAS.duplicate(),
		"territory": str(sim.get("art_territory_name", "")),
		"yin_yang_not_ordinary_captains": true,
		"feeds_ranked_mmr": false,
		"shipping": Authority.shipping_flags_false(),
	}


static func mount_overlay_on_battle(battle: Node) -> Node:
	## Attach shared trial combat overlay under BattleScene HUD. Idempotent.
	var gs := _gs()
	if battle == null or gs == null or str(gs.mode) != "trials":
		return null
	if not bool(gs.trial_live_combat):
		return null
	var existing: Node = battle.get_node_or_null("TrialCombatOverlay")
	if existing != null:
		return existing
	var overlay_script = load("res://scripts/trials/trial_combat_overlay.gd")
	if overlay_script == null:
		return null
	var overlay: Node = overlay_script.new()
	overlay.name = "TrialCombatOverlay"
	battle.add_child(overlay)
	if overlay.has_method("configure"):
		overlay.configure(gs.trial_overlay_state)
	## Merge colossus / flagline camera scaffold into battle camera when present.
	if battle.has_method("_apply_device_role") and not gs.trial_camera_profile.is_empty():
		if "_stage_camera_profile" in battle:
			var merged: Dictionary = battle._stage_camera_profile.duplicate(true)
			for k in gs.trial_camera_profile.keys():
				merged[k] = gs.trial_camera_profile[k]
			battle._stage_camera_profile = merged
			if battle._battle_camera != null and battle._battle_camera.has_method("configure"):
				var cam := battle.get_node_or_null("Camera2D")
				if cam:
					battle._battle_camera.configure(cam, merged, [battle.fighter1, battle.fighter2], battle.blast)
	return overlay


static func overlay_hud_lines(state: Dictionary = {}) -> PackedStringArray:
	var gs := _gs()
	var st: Dictionary = state
	if st.is_empty() and gs != null:
		st = gs.trial_overlay_state
	var mode_id: String = str(st.get("mode_id", gs.trial_mode_id if gs else ""))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("TRIAL · %s" % mode_id)
	lines.append("Shared fighter combat · never ranked MMR")
	match mode_id:
		"convergence_unbound":
			var applied: Dictionary = st.get("applied", {})
			lines.append("%s · %s" % [Unbound.LABEL, str(applied.get("preset", ""))])
			if gs != null:
				lines.append("KB×%.2f DMG×%.2f stocks=%d" % [
					float(gs.trial_knockback_mult), float(gs.damage_ratio), int(gs.stocks),
				])
		"resonance_trial":
			lines.append("Resonance · 10s damage contract · Kinetic Bat scaffold")
		"fractured_accord":
			var snap: Dictionary = gs.trial_sim_snapshot if gs else {}
			lines.append("Flagline · %s" % str(snap.get("art_territory_name", "Accord Fracture")))
			lines.append("Beaconward vs Veilward")
		_:
			lines.append("Journey presentation active")
	lines.append("HUMAN_ART=false · SHIPPING_ROLLBACK=false")
	return lines
