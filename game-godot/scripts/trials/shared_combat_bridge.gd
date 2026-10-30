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
const ResonanceDummy = preload("res://scripts/trials/derby/resonance_dummy_actor.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")
const Prism = preload("res://scripts/trials/prism/prism_weave_sim.gd")
const Riftline = preload("res://scripts/trials/riftline/riftline_defense_sim.gd")
const Echoes = preload("res://scripts/trials/echoes/echoes_gauntlet_sim.gd")
const Colossus = preload("res://scripts/trials/unbound/colossus_rig.gd")
const FlaglineFourBody = preload("res://scripts/trials/flagline/flagline_four_body.gd")
const ColossusActor = preload("res://scripts/trials/unbound/colossus_actor.gd")
const Ownership = preload("res://scripts/trials/trial_real_player_ownership.gd")

## All six Trials modes enter shared BattleScene combat with overlay + live sim tick.
const LIVE_SHARED_COMBAT_MODES := [
	"resonance_trial",
	"fractured_accord",
	"prism_weave",
	"riftline_defense",
	"echoes_gauntlet",
	"convergence_unbound",
]


static func _gs() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("GameState")


static func supports_live_shared_combat(mode_id: String) -> bool:
	return mode_id in LIVE_SHARED_COMBAT_MODES


static func scale_hit_info(info: Dictionary) -> Dictionary:
	## Knockback-only overlay for Trials. Damage ratio is applied once in HitResolver
	## (10 @ 1.35 → 13.5). Do not re-multiply damage here or in fighter.receive_hit.
	var gs := _gs()
	if gs == null or str(gs.mode) != "trials":
		return info
	var out: Dictionary = info.duplicate(true)
	var kb: float = float(gs.trial_knockback_mult)
	if not is_equal_approx(kb, 1.0) and out.has("launch") and typeof(out["launch"]) == TYPE_VECTOR2:
		out["launch"] = out["launch"] * kb
	out["damage_ratio_owner"] = "HitResolver"
	out["damage_ratio"] = float(gs.damage_ratio)
	return out


static func expected_resolved_damage(authored: float, ratio: float = -1.0) -> float:
	## HitResolver contract probe: authored * GameState.damage_ratio.
	var gs := _gs()
	var r: float = ratio
	if r < 0.0:
		r = float(gs.damage_ratio) if gs != null else 1.0
	return authored * r


static func prepare_live_battle(mode_id: String, seats: int = 2, unbound_preset: String = Unbound.PRESET_TOTAL, connected_humans: int = -1) -> Dictionary:
	## Configure GameState for BattleScene entry. Returns honesty + presentation payload.
	## connected_humans < 0 => local/sim journey (CPU fill). >=0 => live PartyLink humans only.
	var gs := _gs()
	if gs == null:
		return {"ok": false, "reason": "gamestate_missing", "SHIPPING_ROLLBACK_ENABLED": false}
	var gate: Dictionary = Seats.enforce(mode_id, seats, connected_humans)
	if not bool(gate.get("ok", false)) and mode_id != "resonance_trial" and mode_id != "riftline_defense" and mode_id != "echoes_gauntlet":
		## Solo-capable modes allowed; multiplayer-promise modes must pass seat gate.
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
		"prism_weave":
			applied = _apply_prism(gs, seated)
			presentation = Presentation.prism_tiles(gs.match_seed)
		"riftline_defense":
			applied = _apply_riftline(gs, seated)
			presentation = Presentation.riftline_lanes(gs.match_seed)
		"echoes_gauntlet":
			applied = _apply_echoes(gs, seated)
			presentation = Presentation.survival_echoes(gs.match_seed)
		_:
			applied = {"note": "unknown_mode"}
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
	var runtime: Dictionary = Unbound.runtime_modifiers(preset_id)
	gs.damage_ratio = float(runtime.get("damage_mult", 1.35))
	gs.trial_knockback_mult = float(runtime.get("knockback_mult", 1.85))
	gs.trial_cooldown_mult = float(runtime.get("cooldown_mult", 0.15))
	gs.trial_full_supers = bool(runtime.get("full_supers", true))
	gs.trial_instant_resources = bool(runtime.get("instant_resources", true))
	gs.trial_respawn_frames = int(runtime.get("respawn_frames", 30))
	gs.trial_actors = runtime.get("controllable_actors", [])
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
	gs.trial_sim_snapshot = session
	return {
		"label": Unbound.LABEL,
		"preset": rules.get("preset_id", preset_id),
		"damage_ratio": gs.damage_ratio,
		"knockback_mult": gs.trial_knockback_mult,
		"cooldown_mult": gs.trial_cooldown_mult,
		"full_supers": gs.trial_full_supers,
		"instant_resources": gs.trial_instant_resources,
		"respawn_frames": gs.trial_respawn_frames,
		"controllable_actors": gs.trial_actors,
		"stocks": gs.stocks,
		"everlasting_permitted": bool(session.get("everlasting_permitted", false)),
		"feeds_ranked_mmr": false,
		"contaminates_versus": false,
		"contaminates_story": false,
		"camera_profile": cam,
		"shipping": Authority.shipping_flags_false(),
	}


static func _apply_derby(gs: Node) -> Dictionary:
	## Resonance live path — authored ResonanceDummyActor (not rook) + Kinetic Bat / distance.
	gs.damage_ratio = 1.0
	gs.trial_knockback_mult = 1.0
	gs.trial_cooldown_mult = 1.0
	gs.trial_full_supers = false
	gs.trial_instant_resources = false
	gs.trial_respawn_frames = 0
	gs.trial_actors = []
	gs.stocks = 99
	gs.match_timer_seconds = 10
	gs.match_type = "stock"
	gs.ruleset_id = "trial-resonance-live"
	var dummy_cfg: Dictionary = ResonanceDummy.live_cpu_config()
	gs.p2_is_cpu = true
	gs.p2_fighter_id = str(dummy_cfg.get("fighter_id", ResonanceDummy.battle_fighter_id()))
	gs.training_dummy_mode = "idle"
	gs.trial_colossus_rigs = []
	gs.trial_camera_profile = {}
	var sim: Dictionary = Derby.create(gs.match_seed if gs.match_seed != 0 else 42, gs.p1_fighter_id)
	sim["dummy_actor"] = ResonanceDummy.identity()
	sim["bat_launch_enabled"] = true
	sim["distance_scoring_enabled"] = true
	sim["player_owned_events"] = false
	gs.trial_sim_snapshot = sim
	return {
		"contract_seconds": 10,
		"kinetic_bat": true,
		"dummy_actor": ResonanceDummy.identity(),
		"dummy_geometry_standin": false,
		"authored_dummy": true,
		"not_rook_standin": true,
		"bat_launch": true,
		"distance_scoring": true,
		"damage_bat_flight_distance_records": true,
		"feeds_ranked_mmr": false,
		"result_kind_live": "REAL_PLAYER",
		"real_player_requires_player_owned_events": true,
		"shipping": Authority.shipping_flags_false(),
	}


static func _apply_flagline(gs: Node, seats: int) -> Dictionary:
	gs.damage_ratio = 1.0
	gs.trial_knockback_mult = 1.0
	gs.trial_cooldown_mult = 1.0
	gs.trial_actors = []
	gs.stocks = 3
	gs.match_timer_seconds = 180
	gs.match_type = "stock"
	gs.ruleset_id = "trial-fractured-accord-live"
	gs.team_mode = true
	gs.team_size = 2
	gs.team_attack = false
	gs.p2_is_cpu = seats < 2
	gs.trial_colossus_rigs = []
	gs.trial_camera_profile = {"minZoom": 0.55, "maxZoom": 1.35, "lerp": 0.12}
	## Local live entry: seated humans honest; CPU fills remaining 2v2 seats.
	## Actual four Fighter bodies spawn under BattleSim (not logical CPU-only).
	var humans_for_flagline: int = clampi(seats, 1, 4)
	var sim: Dictionary = Flagline.create(gs.match_seed if gs.match_seed != 0 else 42, 0, humans_for_flagline)
	sim["live_actor_sync"] = true
	sim["twovstwo_actors"] = true
	sim["actual_combat_bodies"] = true
	sim["logical_cpu_only"] = false
	sim["battle_scene_fighter_slots"] = 4
	sim["multi_actor_depth"] = true
	var roster: Array = FlaglineFourBody.roster_from_sim(sim)
	gs.trial_four_body = true
	gs.trial_body_roster = roster
	if roster.size() >= 2:
		gs.p1_fighter_id = str(roster[0].get("fighter_id", gs.p1_fighter_id))
		gs.p2_fighter_id = str(roster[1].get("fighter_id", gs.p2_fighter_id))
		gs.p1_is_cpu = bool(roster[0].get("is_bot", false))
		gs.p2_is_cpu = bool(roster[1].get("is_bot", true))
	gs.trial_sim_snapshot = sim
	var honesty: Dictionary = FlaglineFourBody.honesty(sim, 4)
	sim["honesty"] = honesty
	gs.trial_sim_snapshot = sim
	return {
		"rooms": [-2, -1, 0, 1, 2],
		"aliases": Flagline.DISPLAY_ALIAS.duplicate(),
		"territory": str(sim.get("art_territory_name", "")),
		"yin_yang_not_ordinary_captains": true,
		"twovstwo_plus_capture": true,
		"core_occupancy": true,
		"contested_capture": true,
		"overtime": true,
		"stronghold": true,
		"connected_humans": humans_for_flagline,
		"actor_count": Flagline.actor_slots(sim).size(),
		"logical_actor_count": 4,
		"multi_actor_depth": true,
		"independent_cpu_fill": humans_for_flagline < 4,
		"battle_scene_fighter_slots": 4,
		"actual_combat_bodies": true,
		"logical_cpu_only": false,
		"combat_authority": "BattleSim+HitResolver",
		"not_four_simultaneous_human_bodies": humans_for_flagline < 4,
		"body_roster": roster,
		"occupancy": Flagline.occupancy_summary(sim),
		"feeds_ranked_mmr": false,
		"shipping": Authority.shipping_flags_false(),
	}


static func _apply_prism(gs: Node, seats: int) -> Dictionary:
	gs.damage_ratio = 1.0
	gs.trial_knockback_mult = 1.0
	gs.trial_cooldown_mult = 1.0
	gs.trial_actors = []
	gs.stocks = 3
	gs.match_timer_seconds = 60
	gs.match_type = "stock"
	gs.ruleset_id = "trial-prism-weave-live"
	gs.p2_is_cpu = seats < 2
	gs.trial_colossus_rigs = []
	gs.trial_camera_profile = {}
	var n: int = clampi(seats, 2, 4)
	var sim: Dictionary = Prism.create(gs.match_seed if gs.match_seed != 0 else 42, n)
	sim["live_shared_combat"] = true
	sim["real_movement"] = true
	gs.trial_sim_snapshot = sim
	return {
		"live_shared_combat": true,
		"real_movement": true,
		"real_attacks": true,
		"attack_paint_burst": true,
		"markers_beyond_color": true,
		"fighter_count": n,
		"battle_scene_fighter_slots": 2,
		"live_max_honest": 4,
		"catalog_max_aspirational": 10,
		"feeds_ranked_mmr": false,
		"shipping": Authority.shipping_flags_false(),
	}


static func _apply_riftline(gs: Node, seats: int) -> Dictionary:
	gs.damage_ratio = 1.0
	gs.trial_knockback_mult = 1.0
	gs.trial_cooldown_mult = 1.0
	gs.trial_actors = []
	gs.stocks = 3
	gs.match_timer_seconds = 180
	gs.match_type = "stock"
	gs.ruleset_id = "trial-riftline-live"
	gs.p2_is_cpu = true
	gs.trial_colossus_rigs = []
	gs.trial_camera_profile = {}
	var sim: Dictionary = Riftline.create(gs.match_seed if gs.match_seed != 0 else 42, gs.p1_fighter_id, clampi(seats, 1, 2))
	sim["live_shared_combat"] = true
	sim["real_enemies"] = true
	gs.trial_sim_snapshot = sim
	return {
		"live_shared_combat": true,
		"real_movement": true,
		"real_attacks": true,
		"real_enemies": true,
		"fracture_echoes": true,
		"lanes": 4,
		"feeds_ranked_mmr": false,
		"shipping": Authority.shipping_flags_false(),
	}


static func _apply_echoes(gs: Node, seats: int) -> Dictionary:
	gs.damage_ratio = 1.0
	gs.trial_knockback_mult = 1.0
	gs.trial_cooldown_mult = 1.0
	gs.trial_actors = []
	gs.stocks = 3
	gs.match_timer_seconds = 300
	gs.match_type = "stock"
	gs.ruleset_id = "trial-echoes-live"
	gs.p2_is_cpu = true
	gs.trial_colossus_rigs = []
	gs.trial_camera_profile = {}
	var sim: Dictionary = Echoes.create(gs.match_seed if gs.match_seed != 0 else 42, seats >= 2)
	sim["live_shared_combat"] = true
	sim["real_enemies"] = true
	gs.trial_sim_snapshot = sim
	return {
		"live_shared_combat": true,
		"real_movement": true,
		"real_attacks": true,
		"real_enemies": true,
		"bosses_are_simulations": true,
		"canonical_cosmic_defeat": false,
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
	if overlay.has_method("bind_battle"):
		overlay.bind_battle(battle)
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
					var focus: Array = [battle.fighter1, battle.fighter2]
					if "fighter3" in battle and battle.fighter3 != null:
						focus.append(battle.fighter3)
					if "fighter4" in battle and battle.fighter4 != null:
						focus.append(battle.fighter4)
					battle._battle_camera.configure(cam, merged, focus, battle.blast)
	## Real Colossus actors (CharacterBody2D + capsule) for Unbound presets.
	if str(gs.trial_mode_id) == "convergence_unbound" and not (gs.trial_colossus_rigs as Array).is_empty():
		mount_colossus_actors_on_battle(battle)
	return overlay


static func tick_live_from_battle(battle: Node) -> Dictionary:
	## Advance mode sim from real BattleScene fighter movement/attacks/enemies.
	var gs := _gs()
	if gs == null or not bool(gs.trial_live_combat) or battle == null:
		return {}
	var mode_id: String = str(gs.trial_mode_id)
	var snap: Dictionary = gs.trial_sim_snapshot
	if snap.is_empty():
		return {}
	var f1 = battle.get("fighter1") if "fighter1" in battle else battle.get_node_or_null("Fighter1")
	var f2 = battle.get("fighter2") if "fighter2" in battle else battle.get_node_or_null("Fighter2")
	var p1_pos: Vector2 = f1.global_position if f1 != null else Vector2(400, 700)
	var p2_pos: Vector2 = f2.global_position if f2 != null else Vector2(1400, 700)
	match mode_id:
		"fractured_accord":
			## Actual four-body combat: sync all live Fighter positions into Flagline capture/OT.
			var positions: Array = FlaglineFourBody.collect_positions(battle)
			if positions.size() >= 4:
				snap = Flagline.tick_live_multi(snap, positions)
			else:
				snap = Flagline.tick_live(snap, p1_pos, p2_pos)
			snap["actual_combat_bodies"] = positions.size() >= 4
			snap["battle_scene_fighter_slots"] = maxi(2, positions.size())
			snap["logical_cpu_only"] = false
			gs.trial_sim_snapshot = snap
			## Room/game end → player-owned Flagline results (capture/OT already in sim).
			if str(snap.get("phase", "")) == "gameWon":
				_seal_flagline_results(gs, snap)
			return Flagline.occupancy_summary(snap)
		"prism_weave":
			var atk1: bool = false
			var atk2: bool = false
			if f1 != null and "state_machine" in f1 and f1.state_machine != null:
				atk1 = str(f1.state_machine.current_state).contains("attack")
			if f2 != null and "state_machine" in f2 and f2.state_machine != null:
				atk2 = str(f2.state_machine.current_state).contains("attack")
			snap = Prism.tick_live_from_world(snap, [p1_pos, p2_pos], [atk1, atk2])
			gs.trial_sim_snapshot = snap
			return Prism.live_scoreboard(snap)
		"riftline_defense":
			var r_atk1: bool = false
			var r_atk2: bool = false
			if f1 != null and "state_machine" in f1 and f1.state_machine != null:
				r_atk1 = str(f1.state_machine.current_state).contains("attack")
			if f2 != null and "state_machine" in f2 and f2.state_machine != null:
				r_atk2 = str(f2.state_machine.current_state).contains("attack")
			snap = Riftline.tick_live_from_battle(snap, p1_pos, p2_pos, r_atk1, r_atk2, f2 != null)
			gs.trial_sim_snapshot = snap
			return Riftline.live_hud(snap)
		"echoes_gauntlet":
			var e_atk: bool = false
			var e_coop: bool = false
			if f1 != null and "state_machine" in f1 and f1.state_machine != null:
				e_atk = str(f1.state_machine.current_state).contains("attack")
			if f2 != null and "state_machine" in f2 and f2.state_machine != null:
				e_coop = str(f2.state_machine.current_state).contains("attack")
			snap = Echoes.tick_live_from_battle(snap, e_atk, e_coop)
			gs.trial_sim_snapshot = snap
			return Echoes.live_hud(snap)
		"resonance_trial":
			## Damage phase advances on timer; live hits feed apply_damage_event separately.
			var inp: Dictionary = {}
			if f1 != null and "velocity" in f1:
				inp["right"] = f1.velocity.x > 10.0
				inp["left"] = f1.velocity.x < -10.0
				inp["jump"] = f1.velocity.y < -50.0
			snap = Derby.step(snap, inp)
			gs.trial_sim_snapshot = snap
			return {
				"phase": snap.get("phase", ""),
				"damage": snap.get("dummy", {}).get("damage", 0),
				"distance": snap.get("final_distance", 0),
				"player_owned_events": bool(snap.get("player_owned_events", false)),
				"live": true,
			}
		"convergence_unbound":
			if str(snap.get("phase", "")) == "play":
				snap = Unbound.simulate_play_frames(snap, 1)
				gs.trial_sim_snapshot = snap
				if not (snap.get("colossus_rigs", []) as Array).is_empty():
					gs.trial_colossus_rigs = snap.get("colossus_rigs", [])
				## Tick real ColossusActor nodes when mounted (beyond dict scaffolds).
				var root: Node = battle.get_node_or_null("ColossusActors")
				if root != null:
					var synced: Array = []
					for child in root.get_children():
						if child != null and child.has_method("tick_frame"):
							child.tick_frame(int(snap.get("frame", 0)), int(snap.get("seed", 1)))
							if child.has_method("to_rig_dictionary"):
								synced.append(child.to_rig_dictionary())
					if not synced.is_empty():
						gs.trial_colossus_rigs = synced
						snap["colossus_rigs"] = synced
						snap["colossus_actors_live"] = true
						gs.trial_sim_snapshot = snap
			return {
				"preset": gs.trial_unbound_preset,
				"cooldown_mult": gs.trial_cooldown_mult,
				"full_supers": gs.trial_full_supers,
				"actors": (gs.trial_actors as Array).size(),
				"colossus_rigs": (gs.trial_colossus_rigs as Array).size(),
				"colossus_actors_live": bool(snap.get("colossus_actors_live", false)),
				"beyond_dictionary_scaffold": true,
				"live": true,
			}
		_:
			return {}


static func notify_live_hit(damage: float, facing: int = 1, lane: int = -1) -> void:
	## Player-owned hits from BattleScene HitResolver path → mode-specific live feeds.
	var gs := _gs()
	if gs == null or not bool(gs.trial_live_combat):
		return
	var mode_id: String = str(gs.trial_mode_id)
	var snap: Dictionary = gs.trial_sim_snapshot
	if snap.is_empty():
		return
	match mode_id:
		"resonance_trial":
			snap = Derby.apply_damage_event(snap, int(ceil(damage)), facing)
			snap["player_owned_events"] = true
		"echoes_gauntlet":
			snap = Echoes.notify_player_attack(snap, maxi(1, int(ceil(damage))))
		"riftline_defense":
			var use_lane: int = lane if lane >= 0 else 0
			snap = Riftline.notify_echo_hit(snap, use_lane, maxi(50, int(ceil(damage)) * 10))
		"convergence_unbound":
			var rigs: Array = gs.trial_colossus_rigs
			if not rigs.is_empty():
				var idx: int = 0
				rigs[idx] = Colossus.apply_hit(rigs[idx], float(gs.trial_knockback_mult), facing)
				gs.trial_colossus_rigs = rigs
				snap["colossus_rigs"] = rigs
		_:
			## Still record digital ownership for modes that only mark owned via notify.
			snap["mode_id"] = mode_id
			snap = Ownership.append_hit_event(snap, damage, facing, lane)
			gs.trial_sim_snapshot = snap
			return
	snap["mode_id"] = mode_id
	snap = Ownership.append_hit_event(snap, damage, facing, lane)
	gs.trial_sim_snapshot = snap


static func seal_live_resonance_result() -> Dictionary:
	var gs := _gs()
	if gs == null:
		return {}
	var snap: Dictionary = gs.trial_sim_snapshot
	var owned: bool = bool(snap.get("player_owned_events", false))
	var sealed: Dictionary = Derby.seal_real_player(snap, owned)
	sealed = Ownership.seal_trace(sealed, str(sealed.get("result_kind", "SIMULATION")))
	gs.trial_sim_snapshot = sealed
	return sealed


static func _seal_flagline_results(gs: Node, snap: Dictionary) -> Dictionary:
	## Player-owned Flagline receipt only when live four-body combat produced gameWon.
	var owned: bool = bool(snap.get("actual_combat_bodies", false)) \
		and bool(snap.get("live_actor_sync", false)) \
		and str(snap.get("phase", "")) == "gameWon"
	var sealed: Dictionary = snap.duplicate(true)
	sealed["result_kind"] = "REAL_PLAYER" if owned else "SIMULATION"
	sealed["earned_personal_best"] = owned
	sealed["feeds_ranked_mmr"] = false
	sealed["SHIPPING_ROLLBACK_ENABLED"] = false
	sealed["HUMAN_ART_APPROVED"] = false
	## Flagline ownership is four-body sync — synthesize one digital event when owned.
	if owned:
		sealed["mode_id"] = "fractured_accord"
		sealed["player_owned_events"] = true
		if not sealed.has("ownership_trace") or (sealed.get("ownership_trace", {}) as Dictionary).is_empty():
			sealed = Ownership.append_hit_event(sealed, 1.0, 1, -1)
	sealed = Ownership.seal_trace(sealed, str(sealed.get("result_kind", "SIMULATION")))
	sealed["rematch"] = FlaglineFourBody.rematch_payload(sealed)
	gs.trial_sim_snapshot = sealed
	if owned:
		gs.record_trial_result({
			"mode_id": "fractured_accord",
			"result_kind": "REAL_PLAYER",
			"winning_team": sealed.get("winning_team", ""),
			"display_winner": Flagline.display_team(str(sealed.get("winning_team", ""))),
			"rooms_won": sealed.get("rooms_won", {}),
			"four_body": true,
			"battle_scene_fighter_slots": 4,
			"seed": sealed.get("seed", 0),
			"ownership_trace": sealed.get("ownership_trace", {}),
			"digital_only": true,
			"physical_device": false,
		})
	return sealed


static func mount_colossus_actors_on_battle(battle: Node) -> Array:
	## Spawn real ColossusActor nodes (capsule collision) beyond dictionary scaffolds.
	var gs := _gs()
	if battle == null or gs == null:
		return []
	if str(gs.trial_mode_id) != "convergence_unbound":
		return []
	var rigs: Array = gs.trial_colossus_rigs
	if rigs.is_empty():
		return []
	var existing: Node = battle.get_node_or_null("ColossusActors")
	if existing != null:
		existing.queue_free()
	var root := Node2D.new()
	root.name = "ColossusActors"
	battle.add_child(root)
	var actors: Array = []
	for rig in rigs:
		var actor = ColossusActor.spawn_from_rig(root, rig)
		actors.append(actor)
	gs.trial_overlay_state["colossus_actors_mounted"] = actors.size()
	gs.trial_overlay_state["colossus_beyond_dictionary"] = true
	return actors


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
				lines.append("KB×%.2f DMG×%.2f CD×%.2f stocks=%d actors=%d" % [
					float(gs.trial_knockback_mult), float(gs.damage_ratio),
					float(gs.trial_cooldown_mult), int(gs.stocks), (gs.trial_actors as Array).size(),
				])
		"resonance_trial":
			lines.append("Resonance · 10s · %s · Kinetic Bat + distance" % ResonanceDummy.DISPLAY_NAME)
			lines.append("Authored dummy · not rook · REAL_PLAYER only if player-owned")
		"fractured_accord":
			var snap: Dictionary = gs.trial_sim_snapshot if gs else {}
			var occ: Dictionary = Flagline.occupancy_summary(snap) if not snap.is_empty() else {}
			lines.append("Flagline · %s" % str(snap.get("art_territory_name", "Accord Fracture")))
			lines.append("Beaconward vs Veilward · core %d/%d contested=%s" % [
				int(occ.get("solar_in_core", 0)), int(occ.get("lunar_in_core", 0)),
				str(occ.get("contested", false)),
			])
		"prism_weave":
			lines.append("Prism Weave · live movement paints tiles")
		"riftline_defense":
			var rsnap: Dictionary = gs.trial_sim_snapshot if gs else {}
			lines.append("Riftline · wave %s · echoes %d" % [
				str(rsnap.get("wave", 1)), (rsnap.get("echoes", []) as Array).size(),
			])
		"echoes_gauntlet":
			var esnap: Dictionary = gs.trial_sim_snapshot if gs else {}
			lines.append("Echoes · wave %s · sim bosses only" % str(esnap.get("wave_index", 0)))
		_:
			lines.append("Journey presentation active")
	lines.append("HUMAN_ART=false · SHIPPING_ROLLBACK=false")
	return lines
