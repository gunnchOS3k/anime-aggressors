extends SceneTree
## AA-RTM-006 — HitResolver owns damage_ratio; Trials KB overlay once; Colossus scale-aware.
## Does not rewrite Codex HitResolver. HUMAN_ART / roster frame audit remain open.

const Honesty = preload("res://scripts/rc/hitbox_integrity_honesty.gd")
const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")
const ColossusActor = preload("res://scripts/trials/unbound/colossus_actor.gd")

var failures: Array = []
var checks := 0
var output := ""


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			output = arg.trim_prefix("--ordinary-output=")

	check(Honesty.hit_resolver_owns_damage_ratio_source(), "hr_source_owns_ratio")
	check(Honesty.bridge_knockback_only_overlay(), "bridge_kb_only")
	check(Honesty.fighter_trials_receive_hit_no_damage_reapply(), "fighter_no_dmg_reapply")
	check(is_equal_approx(Bridge.expected_resolved_damage(10.0, 1.35), 13.5), "ten_at_1_35")

	var colo: Dictionary = Honesty.colossus_scale_aware_contract()
	check(bool(colo.get("ok", false)), "colossus_contract")
	for f in colo.get("failures", []):
		check(false, "colo:" + str(f))
	check(not bool(colo.get("HUMAN_ART_APPROVED", true)), "colo_art_false")

	var gs = root.get_node_or_null("GameState")
	check(gs != null, "gamestate")
	if gs != null:
		var prep: Dictionary = Bridge.prepare_live_battle("convergence_unbound", 2, Unbound.PRESET_COLOSSUS, -1)
		check(bool(prep.get("ok", false)), "prep_colossus")
		check(is_equal_approx(float(gs.damage_ratio), 1.35), "unbound_dmg_mult")
		check(float(gs.trial_knockback_mult) > 1.0, "kb_mult_amplified")
		var hit := {"damage": 10.0, "resolved_damage": 10.0, "launch": Vector2(100, -50)}
		var scaled: Dictionary = Bridge.scale_hit_info(hit)
		check(is_equal_approx(float(scaled.get("damage", -1.0)), 10.0), "no_damage_double_apply")
		check(is_equal_approx(float(scaled.get("resolved_damage", -1.0)), 10.0), "no_resolved_double_apply")
		check(str(scaled.get("damage_ratio_owner", "")) == "HitResolver", "owner_label")
		check((scaled["launch"] as Vector2).x > 100.0, "knockback_scales_once")
		var overlay: Dictionary = gs.trial_overlay_state
		var card: Dictionary = overlay.get("hitbox_integrity", {})
		if card.is_empty():
			card = Honesty.presentation_honesty_card(str(gs.trial_mode_id))
		check(str(card.get("damage_ratio_owner", "")) == "HitResolver", "overlay_owner")
		check(not bool(card.get("Codex_HitResolver_rewritten", true)), "codex_untouched_card")
		check(not bool(card.get("HUMAN_ART_APPROVED", true)), "card_art_false")
		check(not bool(card.get("roster_frame_data_owner_audit", true)), "no_roster_audit_claim")

		var battle := Node2D.new()
		battle.name = "HitboxIntegrityBattle"
		root.add_child(battle)
		var mounted: Array = Bridge.mount_colossus_actors_on_battle(battle)
		check(mounted.size() >= 2, "mounted_actors")
		for a in mounted:
			check(a is CharacterBody2D, "actor_body")
			check(a.get_node_or_null("BodyCapsule") != null, "actor_capsule")
			check(not bool(a.HUMAN_ART_APPROVED), "actor_art_false")
			var shape: Shape2D = (a.get_node("BodyCapsule") as CollisionShape2D).shape
			check(shape is CapsuleShape2D, "capsule_shape")
			if shape is CapsuleShape2D:
				check((shape as CapsuleShape2D).radius > 48.0, "scale_aware_radius")

		gs.clear_trial_modifiers()
		check(is_equal_approx(float(gs.damage_ratio), 1.0), "modifiers_reset")

	var report: Dictionary = Honesty.validate()
	check(bool(report.get("ok", false)), "validate_ok")
	for f in report.get("failures", []):
		check(false, "fail:" + str(f))
	check(bool(report.get("HitResolver_untouched", false)), "hr_untouched")
	check(bool(report.get("Codex_combat_data_untouched", false)), "codex_untouched")
	check(not bool(report.get("device_matrix_pass", true)), "no_device_matrix")
	check(not bool(report.get("CURSOR_COMPLETE", true)), "cursor_complete_false")
	check(not bool(report.get("SHIPPING_ROLLBACK_ENABLED", true)), "rollback_false")

	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"scope": "AA-RTM-006 hitbox integrity honesty — HitResolver owns damage_ratio; KB once; Colossus scale-aware; ≠ HUMAN_ART",
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"HUMAN_ART_APPROVED": false,
		"roster_frame_data_owner_audit": false,
		"device_matrix_pass": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"req_id": "AA-RTM-006",
	}
	if not output.is_empty():
		var f := FileAccess.open(output.path_join("HITBOX_INTEGRITY_HONESTY.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	print("HITBOX_INTEGRITY_HONESTY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
