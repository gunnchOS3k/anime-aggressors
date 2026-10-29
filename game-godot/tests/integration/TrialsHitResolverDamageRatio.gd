extends SceneTree
## HitResolver damage_ratio contract: 10 dmg @ 1.35 → 13.5 (single application).
## Fighter.receive_hit and TrialsSharedCombatBridge.scale_hit_info must not re-multiply damage.

const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")

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
		print("TRIALS_HIT_RESOLVER_DAMAGE_RATIO FAIL checks=", checks, " failures=", failures)
		quit(1)
		return

	## Canonical HitResolver math: authored * GameState.damage_ratio once.
	check(is_equal_approx(Bridge.expected_resolved_damage(10.0, 1.35), 13.5), "ten_at_1_35_is_13_5")

	var prep: Dictionary = Bridge.prepare_live_battle("convergence_unbound", 2, Unbound.PRESET_TOTAL, -1)
	check(bool(prep.get("ok", false)), "prep_unbound")
	check(is_equal_approx(float(gs.damage_ratio), 1.35), "unbound_base_damage_mult")
	check(is_equal_approx(Bridge.expected_resolved_damage(10.0), 13.5), "live_gs_ratio_13_5")

	## scale_hit_info must NOT re-multiply damage (HitResolver is sole damage owner).
	var hit := {"damage": 10.0, "resolved_damage": 10.0, "launch": Vector2(100, -50)}
	var scaled: Dictionary = Bridge.scale_hit_info(hit)
	check(is_equal_approx(float(scaled.get("damage", -1.0)), 10.0), "no_damage_double_apply")
	check(is_equal_approx(float(scaled.get("resolved_damage", -1.0)), 10.0), "no_resolved_double_apply")
	check(str(scaled.get("damage_ratio_owner", "")) == "HitResolver", "owner_label")
	check(scaled["launch"].x > 100.0, "knockback_still_scales")

	## Source integrity: HitResolver applies damage_ratio; fighter must not re-multiply damage fields.
	var hr := FileAccess.get_file_as_string("res://scripts/combat/hit_resolver.gd")
	check(hr.find("damage_ratio") >= 0 and hr.find("dealt *= rules_ratio") >= 0, "hit_resolver_owns_ratio")
	var fighter_src := FileAccess.get_file_as_string("res://scripts/fighters/fighter.gd")
	var trials_block_start := fighter_src.find("## Trials shared combat")
	check(trials_block_start >= 0, "trials_receive_hit_block")
	if trials_block_start >= 0:
		var slice := fighter_src.substr(trials_block_start, 520)
		check(slice.find('info["resolved_damage"]') < 0 and slice.find('info["damage"]') < 0, "fighter_no_damage_field_reapply")
		check(slice.find("trial_knockback_mult") >= 0, "fighter_keeps_kb_mult")
		check(slice.find("never re-multiply") >= 0 or slice.find("HitResolver.resolve") >= 0, "fighter_documents_single_owner")

	gs.clear_trial_modifiers()
	check(is_equal_approx(float(gs.damage_ratio), 1.0), "modifiers_reset_on_clear")
	check(not bool(gs.trial_live_combat), "live_flag_cleared")

	print("TRIALS_HIT_RESOLVER_DAMAGE_RATIO ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
