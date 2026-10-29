extends SceneTree
## Shared combat bridge — Unbound/Derby/Flagline onto BattleScene without forked combat.

const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")
const Presentation = preload("res://scripts/trials/mode_presentation.gd")
const Seats = preload("res://scripts/trials/partylink_seat_enforcement.gd")
const ResonanceDummy = preload("res://scripts/trials/derby/resonance_dummy_actor.gd")

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

	check(Bridge.supports_live_shared_combat("convergence_unbound"), "live_unbound")
	check(Bridge.supports_live_shared_combat("resonance_trial"), "live_derby")
	check(Bridge.supports_live_shared_combat("fractured_accord"), "live_flagline")
	check(not Bridge.supports_live_shared_combat("prism_weave"), "prism_journey_only")
	check(not Bridge.supports_live_shared_combat("riftline_defense"), "rift_journey_only")
	check(not Bridge.supports_live_shared_combat("echoes_gauntlet"), "echoes_journey_only")

	var prep_u: Dictionary = Bridge.prepare_live_battle("convergence_unbound", 4, Unbound.PRESET_COLOSSUS, -1)
	check(bool(prep_u.get("ok", false)), "prep_unbound_ok")
	check(str(gs.mode) == "trials", "mode_trials")
	check(bool(gs.trial_live_combat), "live_combat_flag")
	check(not bool(gs.feeds_trial_ranked_mmr), "never_ranked_flag")
	check(float(gs.trial_knockback_mult) > 1.0, "unbound_kb_mult")
	check(float(gs.damage_ratio) > 1.0, "unbound_dmg_ratio")
	check(int(gs.stocks) >= 7, "unbound_stocks")
	check(not bool(prep_u.get("SHIPPING_ROLLBACK_ENABLED", true)), "no_shipping_rollback")
	check((gs.trial_colossus_rigs as Array).size() >= 2, "colossus_rigs_on_gs")
	check(not gs.trial_camera_profile.is_empty(), "colossus_camera_profile")

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
	check(bool(applied_d.get("bat_launch", false)), "resonance_bat_launch")
	check(bool(applied_d.get("distance_scoring", false)), "resonance_distance_scoring")

	var prep_f: Dictionary = Bridge.prepare_live_battle("fractured_accord", 4, Unbound.PRESET_TOTAL, -1)
	check(bool(prep_f.get("ok", false)), "prep_flagline_ok")
	check(bool(gs.team_mode), "flagline_team_mode")
	var art: Dictionary = Presentation.flagline_territory(1, 0)
	check(Presentation.assert_no_human_art(art), "flagline_no_human_art")

	var gate1: Dictionary = Seats.enforce("convergence_unbound", 1, 1)
	check(not bool(gate1.get("ok", true)), "unbound_rejects_single_seat")
	check(not bool(gate1.get("SHIPPING_ROLLBACK_ENABLED", true)), "reject_no_rollback")

	gs.end_trial()
	check(is_equal_approx(float(gs.damage_ratio), 1.0), "end_trial_resets_ratio")

	print("TRIALS_SHARED_COMBAT_BRIDGE ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
