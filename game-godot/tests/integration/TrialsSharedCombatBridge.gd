extends SceneTree
## Shared combat bridge — all six Trials modes onto BattleScene without forked combat.

const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")
const Presentation = preload("res://scripts/trials/mode_presentation.gd")
const Seats = preload("res://scripts/trials/partylink_seat_enforcement.gd")
const ResonanceDummy = preload("res://scripts/trials/derby/resonance_dummy_actor.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")
const Derby = preload("res://scripts/trials/derby/resonance_trial_sim.gd")

var failures: Array = []
var checks := 0


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	var gs = root.get_node_or_null("GameState")
	check(gs != null, "gamestate_autoload")
	if gs == null:
		print("TRIALS_SHARED_COMBAT_BRIDGE FAIL checks=", checks, " failures=", failures)
		quit(1)
		return

	for mid in Bridge.LIVE_SHARED_COMBAT_MODES:
		check(Bridge.supports_live_shared_combat(mid), "live_" + mid)

	var prep_u: Dictionary = Bridge.prepare_live_battle("convergence_unbound", 4, Unbound.PRESET_COLOSSUS, -1)
	check(bool(prep_u.get("ok", false)), "prep_unbound_ok")
	check(str(gs.mode) == "trials", "mode_trials")
	check(bool(gs.trial_live_combat), "live_combat_flag")
	check(not bool(gs.feeds_trial_ranked_mmr), "never_ranked_flag")
	check(float(gs.trial_knockback_mult) > 1.0, "unbound_kb_mult")
	check(float(gs.damage_ratio) > 1.0, "unbound_dmg_ratio")
	check(float(gs.trial_cooldown_mult) < 0.5, "unbound_cooldown_mult")
	check(bool(gs.trial_full_supers), "unbound_full_supers")
	check(bool(gs.trial_instant_resources), "unbound_instant_resources")
	check(int(gs.trial_respawn_frames) > 0, "unbound_respawn_frames")
	check((gs.trial_actors as Array).size() >= 2, "unbound_controllable_actors")
	check(int(gs.stocks) >= 7, "unbound_stocks")
	check(not bool(prep_u.get("SHIPPING_ROLLBACK_ENABLED", true)), "no_shipping_rollback")
	check((gs.trial_colossus_rigs as Array).size() >= 2, "colossus_rigs_on_gs")
	check(not gs.trial_camera_profile.is_empty(), "colossus_camera_profile")
	check(not bool(prep_u.get("applied", {}).get("contaminates_versus", true)), "unbound_no_versus_contam")

	## Damage owned by HitResolver; scale_hit_info only scales knockback.
	check(is_equal_approx(Bridge.expected_resolved_damage(10.0, 1.35), 13.5), "hit_resolver_13_5")
	var hit := {"damage": 10.0, "resolved_damage": 10.0, "launch": Vector2(100, -50)}
	var scaled: Dictionary = Bridge.scale_hit_info(hit)
	check(is_equal_approx(float(scaled.get("damage", 0.0)), 10.0), "no_damage_double")
	check(scaled["launch"].x > 100.0, "scale_knockback")

	var prep_d: Dictionary = Bridge.prepare_live_battle("resonance_trial", 1, Unbound.PRESET_TOTAL, -1)
	check(bool(prep_d.get("ok", false)), "prep_derby_ok")
	check(int(gs.match_timer_seconds) == 10, "derby_10s")
	check(bool(gs.trial_overlay_state.get("presentation", {}).get("HUMAN_ART", true)) == false, "derby_human_art_false")
	var applied_d: Dictionary = prep_d.get("applied", {})
	check(str(applied_d.get("dummy_actor", {}).get("actor_id", "")) == ResonanceDummy.DUMMY_ID, "resonance_real_dummy")
	check(bool(applied_d.get("not_rook_standin", false)), "resonance_not_rook")
	check(bool(applied_d.get("authored_dummy", false)), "resonance_authored_dummy")
	check(str(gs.p2_fighter_id) == ResonanceDummy.battle_fighter_id(), "resonance_p2_is_dummy")
	check(bool(applied_d.get("bat_launch", false)), "resonance_bat_launch")
	check(bool(applied_d.get("distance_scoring", false)), "resonance_distance_scoring")
	## SIMULATION seal never claims REAL_PLAYER; REAL_PLAYER requires player-owned events.
	var sim_seal: Dictionary = Derby.seal_simulation(Derby.create(3, "ember-vale"))
	check(str(sim_seal.get("result_kind", "")) == "SIMULATION", "sim_seal_kind")
	var fake_real: Dictionary = Derby.seal_real_player(Derby.create(3, "ember-vale"), true)
	check(str(fake_real.get("result_kind", "")) == "SIMULATION", "real_requires_results_phase")

	var prep_f: Dictionary = Bridge.prepare_live_battle("fractured_accord", 4, Unbound.PRESET_TOTAL, -1)
	check(bool(prep_f.get("ok", false)), "prep_flagline_ok")
	check(bool(gs.team_mode), "flagline_team_mode")
	check(bool(prep_f.get("applied", {}).get("core_occupancy", false)), "flagline_core_occupancy")
	check(bool(prep_f.get("applied", {}).get("contested_capture", false)), "flagline_contested")
	check(bool(prep_f.get("applied", {}).get("overtime", false)), "flagline_ot")
	check(bool(prep_f.get("applied", {}).get("stronghold", false)), "flagline_stronghold")
	check(int(prep_f.get("applied", {}).get("actor_count", 0)) == 4, "flagline_four_actors")
	check(bool(prep_f.get("applied", {}).get("multi_actor_depth", false)), "flagline_multi_actor_depth")
	check(bool(prep_f.get("applied", {}).get("independent_cpu_fill", false)), "flagline_independent_cpu")
	check(bool(prep_f.get("applied", {}).get("not_four_simultaneous_human_bodies", false)), "flagline_slot_honesty")
	var art: Dictionary = Presentation.flagline_territory(1, 0)
	check(Presentation.assert_no_human_art(art), "flagline_no_human_art")
	## Live occupancy sync from positions is not HUD-only.
	var live_fa: Dictionary = Flagline.tick_live(Flagline.create(5, 0, 2), Vector2(960, 540), Vector2(200, 540))
	var occ: Dictionary = Flagline.occupancy_summary(live_fa)
	check(int(occ.get("solar_in_core", 0)) >= 1, "live_solar_occupancy")
	check(bool(occ.get("contested", true)) == false or int(occ.get("lunar_in_core", 0)) == 0, "live_uncontested_or_clear")
	check(bool(occ.get("multi_actor_depth", false)), "live_multi_actor_depth")

	var prep_p: Dictionary = Bridge.prepare_live_battle("prism_weave", 4, Unbound.PRESET_TOTAL, -1)
	check(bool(prep_p.get("ok", false)), "prep_prism_ok")
	check(bool(prep_p.get("applied", {}).get("live_shared_combat", false)), "prism_live")
	check(bool(prep_p.get("applied", {}).get("real_movement", false)), "prism_movement")
	check(bool(prep_p.get("applied", {}).get("attack_paint_burst", false)), "prism_attack_paint")
	check(bool(prep_p.get("applied", {}).get("markers_beyond_color", false)), "prism_a11y")

	var prep_r: Dictionary = Bridge.prepare_live_battle("riftline_defense", 1, Unbound.PRESET_TOTAL, -1)
	check(bool(prep_r.get("ok", false)), "prep_rift_ok")
	check(bool(prep_r.get("applied", {}).get("real_enemies", false)), "rift_enemies")

	var prep_e: Dictionary = Bridge.prepare_live_battle("echoes_gauntlet", 1, Unbound.PRESET_TOTAL, -1)
	check(bool(prep_e.get("ok", false)), "prep_echoes_ok")
	check(bool(prep_e.get("applied", {}).get("real_enemies", false)), "echoes_enemies")
	check(not bool(prep_e.get("applied", {}).get("canonical_cosmic_defeat", true)), "echoes_no_cosmic")

	var gate1: Dictionary = Seats.enforce("convergence_unbound", 1, 1)
	check(not bool(gate1.get("ok", true)), "unbound_rejects_single_seat")
	check(not bool(gate1.get("SHIPPING_ROLLBACK_ENABLED", true)), "reject_no_rollback")

	## Versus must not keep Unbound modifiers.
	gs.begin_local_versus(true)
	check(str(gs.mode) == "versus", "versus_mode")
	check(is_equal_approx(float(gs.damage_ratio), 1.0), "versus_clears_ratio")
	check(is_equal_approx(float(gs.trial_cooldown_mult), 1.0), "versus_clears_cd")
	check(not bool(gs.trial_full_supers), "versus_clears_supers")
	check((gs.trial_actors as Array).is_empty(), "versus_clears_actors")
	check(not bool(gs.trial_live_combat), "versus_clears_live")

	gs.begin_trial("convergence_unbound", 2)
	Bridge.prepare_live_battle("convergence_unbound", 2, Unbound.PRESET_TOTAL, -1)
	gs.end_trial()
	check(is_equal_approx(float(gs.damage_ratio), 1.0), "end_trial_resets_ratio")

	print("TRIALS_SHARED_COMBAT_BRIDGE ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
