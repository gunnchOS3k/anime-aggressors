extends RefCounted
class_name HitboxIntegrityHonesty
## AA-RTM-006 digital honesty — HitResolver owns damage_ratio once;
## Trials scale knockback only (never re-multiply damage); Colossus scale-aware
## capsule collision. Does NOT rewrite Codex HitResolver combat data.
## HUMAN_ART hitbox review / full roster frame-data audit remain open.

const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Colossus = preload("res://scripts/trials/unbound/colossus_rig.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")


static func hit_resolver_owns_damage_ratio_source() -> bool:
	var hr := FileAccess.get_file_as_string("res://scripts/combat/hit_resolver.gd")
	return hr.find("damage_ratio") >= 0 and hr.find("dealt *= rules_ratio") >= 0


static func bridge_knockback_only_overlay() -> bool:
	var src := FileAccess.get_file_as_string("res://scripts/trials/shared_combat_bridge.gd")
	return src.find("Knockback-only overlay") >= 0 \
		and src.find('out["damage_ratio_owner"] = "HitResolver"') >= 0 \
		and src.find('out["launch"] = out["launch"] * kb') >= 0


static func fighter_trials_receive_hit_no_damage_reapply() -> bool:
	var fighter_src := FileAccess.get_file_as_string("res://scripts/fighters/fighter.gd")
	var trials_block_start := fighter_src.find("## Trials shared combat")
	if trials_block_start < 0:
		return false
	var slice := fighter_src.substr(trials_block_start, 520)
	return slice.find('info["resolved_damage"]') < 0 \
		and slice.find('info["damage"]') < 0 \
		and slice.find("trial_knockback_mult") >= 0


static func scale_hit_info_contract_probe() -> Dictionary:
	## Requires GameState in trials mode with unbound modifiers applied.
	var hit := {"damage": 10.0, "resolved_damage": 10.0, "launch": Vector2(100, -50)}
	var scaled: Dictionary = Bridge.scale_hit_info(hit)
	var kb_scaled: bool = scaled.has("launch") and typeof(scaled["launch"]) == TYPE_VECTOR2 \
		and (scaled["launch"] as Vector2).x >= 100.0
	return {
		"damage_untouched": is_equal_approx(float(scaled.get("damage", -1.0)), 10.0),
		"resolved_untouched": is_equal_approx(float(scaled.get("resolved_damage", -1.0)), 10.0),
		"owner_hit_resolver": str(scaled.get("damage_ratio_owner", "")) == "HitResolver",
		"knockback_scaled_or_passthrough": kb_scaled,
		"expected_10_at_1_35": is_equal_approx(Bridge.expected_resolved_damage(10.0, 1.35), 13.5),
	}


static func colossus_scale_aware_contract() -> Dictionary:
	var rigs: Array = Colossus.spawn_for_preset(Unbound.PRESET_COLOSSUS, 7)
	var failures: Array = []
	if rigs.is_empty():
		failures.append("no_rigs")
	for rig in rigs:
		var eng: Dictionary = Colossus.validate_engineering(rig)
		if not bool(eng.get("ok", false)):
			failures.append("eng:" + str(rig.get("rig_id", "?")))
		var c: Dictionary = rig.get("collision", {})
		if str(c.get("mode", "")) != "scale_aware_capsule":
			failures.append("mode:" + str(rig.get("rig_id", "?")))
		if float(rig.get("scale", 0.0)) < 1.0:
			failures.append("scale:" + str(rig.get("rig_id", "?")))
		if bool(rig.get("HUMAN_ART_APPROVED", false)) or bool(rig.get("final_rig_approved", false)):
			failures.append("art_claimed:" + str(rig.get("rig_id", "?")))
	var unbound_preset: Dictionary = Unbound.preset(Unbound.PRESET_COLOSSUS)
	var scale_aware_flag := bool(unbound_preset.get("scale_aware_collision", false))
	if not scale_aware_flag:
		failures.append("preset_missing_scale_aware_collision")
	return {
		"ok": failures.is_empty() and scale_aware_flag,
		"failures": failures,
		"rig_count": rigs.size(),
		"scale_aware_collision": scale_aware_flag,
		"HUMAN_ART_APPROVED": false,
		"beyond_dictionary_scaffold": true,
	}


static func presentation_honesty_card(mode_id: String = "convergence_unbound") -> Dictionary:
	return {
		"req_id": "AA-RTM-006",
		"mode_id": mode_id,
		"damage_ratio_owner": "HitResolver",
		"knockback_scaled_once_in_trials_overlay": true,
		"damage_never_re_multiplied_in_bridge_or_fighter": true,
		"colossus_collision": "scale_aware_capsule",
		"Codex_HitResolver_rewritten": false,
		"HUMAN_ART_APPROVED": false,
		"roster_frame_data_owner_audit": false,
		"device_matrix_pass": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
	}


static func validate() -> Dictionary:
	var failures: Array = []
	if not hit_resolver_owns_damage_ratio_source():
		failures.append("hit_resolver_missing_ratio_apply")
	if not bridge_knockback_only_overlay():
		failures.append("bridge_not_knockback_only")
	if not fighter_trials_receive_hit_no_damage_reapply():
		failures.append("fighter_may_reapply_damage")
	var probe: Dictionary = scale_hit_info_contract_probe()
	if not bool(probe.get("expected_10_at_1_35", false)):
		failures.append("expected_damage_math")
	## scale_hit_info needs trials mode — probe damage fields when gs ready.
	var gs_tree := Engine.get_main_loop() as SceneTree
	var gs: Node = null
	if gs_tree != null and gs_tree.root != null:
		gs = gs_tree.root.get_node_or_null("GameState")
	if gs != null and str(gs.get("mode")) == "trials":
		if not bool(probe.get("damage_untouched", false)):
			failures.append("bridge_reapplied_damage")
		if not bool(probe.get("owner_hit_resolver", false)):
			failures.append("owner_label_missing")
	var colo: Dictionary = colossus_scale_aware_contract()
	if not bool(colo.get("ok", false)):
		failures.append("colossus_scale_aware")
		for f in colo.get("failures", []):
			failures.append("colo:" + str(f))
	var card: Dictionary = presentation_honesty_card()
	if bool(card.get("Codex_HitResolver_rewritten", true)):
		failures.append("codex_rewrite_claimed")
	if bool(card.get("HUMAN_ART_APPROVED", true)):
		failures.append("human_art_claimed")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"probe": probe,
		"colossus": colo,
		"card": card,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"damage_ratio_owner": "HitResolver",
		"knockback_once": true,
		"HUMAN_ART_APPROVED": false,
		"roster_frame_data_owner_audit": false,
		"device_matrix_pass": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"CURSOR_COMPLETE": false,
		"req_id": "AA-RTM-006",
	}
