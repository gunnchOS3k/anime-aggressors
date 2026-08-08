extends RefCounted
class_name SmokeWaveD2AlphaExit

## Wave D2 toward Alpha exit — tutorial, hazards, runtime audit, online scaffold, matrix.
## Honest: does NOT claim Alpha exit.

const _AuraSpecialRuntime = preload("res://scripts/combat/aura_special_runtime.gd")
const _BatchMatchHarness = preload("res://scripts/battle/batch_match_harness.gd")
const _OnlineProtocol = preload("res://scripts/net/online_protocol.gd")
const _OnlineSessionState = preload("res://scripts/net/session_state.gd")
const _RollbackLatencyPolicy = preload("res://scripts/net/rollback_latency_policy.gd")
const _NetworkSim = preload("res://scripts/net/network_sim.gd")
const _SmokeAssert = preload("res://tests/smoke_assert.gd")


static func run() -> bool:
	_SmokeAssert.reset()

	# 1) Tutorial + first-run wiring (script/scene presence; no autoload required).
	_SmokeAssert.ok(ResourceLoader.exists("res://scenes/menus/TutorialScene.tscn"), "TutorialScene missing")
	_SmokeAssert.ok(ResourceLoader.exists("res://scenes/training/TutorialBattleScene.tscn"), "TutorialBattleScene missing")
	_SmokeAssert.ok(FileAccess.file_exists("res://scripts/menus/tutorial_scene.gd"), "tutorial_scene.gd missing")
	_SmokeAssert.ok(FileAccess.file_exists("res://scripts/training/tutorial_battle_scene.gd"), "tutorial_battle_scene.gd missing")
	var gs := FileAccess.open("res://scripts/core/GameState.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(gs.contains("begin_tutorial"), "GameState begin_tutorial missing")
	_SmokeAssert.ok(gs.contains("first_run_pending"), "GameState first_run_pending missing")
	_SmokeAssert.ok(gs.contains("ensure_first_run_loaded"), "GameState ensure_first_run_loaded missing")
	var boot := FileAccess.open("res://scripts/core/boot_scene.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(boot.contains("first_run_pending"), "boot first-run path missing")
	var mode_src := FileAccess.open("res://scripts/menus/mode_select_scene.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(mode_src.contains("_on_tutorial_pressed"), "mode select tutorial hook missing")
	var router := FileAccess.open("res://scripts/core/SceneRouter.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(router.contains('"tutorial"'), "SceneRouter tutorial route missing")
	_SmokeAssert.ok(router.contains('"tutorial_battle"'), "SceneRouter tutorial_battle route missing")

	# 2) Items/Hazards mode path.
	_SmokeAssert.ok(ResourceLoader.exists("res://scenes/menus/HazardsScene.tscn"), "HazardsScene missing")
	_SmokeAssert.ok(FileAccess.file_exists("res://scripts/menus/hazards_scene.gd"), "hazards_scene.gd missing")
	_SmokeAssert.ok(FileAccess.file_exists("res://scripts/battle/hazard_item_runtime.gd"), "hazard_item_runtime.gd missing")
	_SmokeAssert.ok(gs.contains("begin_hazards_mode"), "GameState begin_hazards_mode missing")
	_SmokeAssert.ok(mode_src.contains("_on_hazards_pressed"), "mode select hazards hook missing")
	_SmokeAssert.ok(router.contains('"hazards"'), "SceneRouter hazards route missing")
	var battle := FileAccess.open("res://scripts/battle/battle_scene.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(battle.contains("HazardItemRuntime") or battle.contains("hazard_item_runtime"), "battle missing hazard runtime")

	# 3) Per-fighter runtime audit — all 7 distinct aura/specials wired in combat scripts.
	_SmokeAssert.ok(FileAccess.file_exists("res://scripts/combat/aura_special_runtime.gd"), "aura_special_runtime.gd missing")
	var audit: Dictionary = _AuraSpecialRuntime.audit_roster_runtime()
	_SmokeAssert.ok(bool(audit.get("ok", false)), "runtime audit failed: %s" % str(audit.get("missing", [])))
	_SmokeAssert.ok(int(audit.get("fighter_count", 0)) >= 7, "audit fighter_count")
	_SmokeAssert.ok(str(audit.get("alpha_claim", "")).contains("NOT_ALPHA_EXIT"), "audit must not claim Alpha exit")
	var fighter_src := FileAccess.open("res://scripts/fighters/fighter.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(fighter_src.contains("AuraSpecialRuntime") or fighter_src.contains("aura_special_runtime"), "fighter must use AuraSpecialRuntime")
	_SmokeAssert.ok(fighter_src.contains("enable_phase_cancel"), "fighter phase cancel hook missing")
	_SmokeAssert.ok(fighter_src.contains("enable_dash_cancel"), "fighter dash cancel hook missing")
	var hit_src := FileAccess.open("res://scripts/combat/hit_resolver.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(hit_src.contains("apply_attacker_on_confirm"), "hit_resolver missing special runtime confirm")
	_SmokeAssert.ok(hit_src.contains("should_block_hit_with_armor"), "hit_resolver missing armor runtime")

	# 4) Online architecture scaffold + network sim (no public deploy claim).
	for p in [
		"res://scripts/net/online_protocol.gd",
		"res://scripts/net/session_state.gd",
		"res://scripts/net/rollback_latency_policy.gd",
		"res://scripts/net/network_sim.gd",
	]:
		_SmokeAssert.ok(FileAccess.file_exists(p), "missing %s" % p)
	var proto: Dictionary = _OnlineProtocol.self_test()
	_SmokeAssert.ok(bool(proto.get("ok", false)), "online protocol self_test")
	_SmokeAssert.ok(str(proto.get("alpha_claim", "")).contains("NOT_PUBLIC"), "protocol must not claim public online")
	var sess: Dictionary = _OnlineSessionState.self_test()
	_SmokeAssert.ok(bool(sess.get("ok", false)), "session_state self_test")
	var pol: Dictionary = _RollbackLatencyPolicy.self_test()
	_SmokeAssert.ok(bool(pol.get("ok", false)), "rollback_latency_policy self_test")
	var net: Dictionary = _NetworkSim.self_test()
	_SmokeAssert.ok(bool(net.get("ok", false)), "network_sim self_test: %s" % str(net))

	# 5) CPU batch matrix 7×7 × tiers with deadlock/diversity metrics.
	var matrix: Dictionary = _BatchMatchHarness.run_full_matrix([1, 3, 5], 48, 7)
	_SmokeAssert.ok(int(matrix.get("match_count", 0)) == 7 * 7 * 3, "matrix match_count 7x7x3")
	_SmokeAssert.ok(matrix.has("deadlock_rate"), "matrix deadlock_rate")
	_SmokeAssert.ok(matrix.has("diversity"), "matrix diversity")
	var div: Dictionary = matrix.get("diversity", {})
	_SmokeAssert.ok(int(div.get("unique_winners", 0)) >= 3, "matrix needs diverse winners")
	_SmokeAssert.ok(str(matrix.get("alpha_claim", "")).contains("NOT_ALPHA_EXIT"), "matrix must not claim Alpha exit")
	_SmokeAssert.ok(_BatchMatchHarness.assert_deterministic(7, 40, 3), "batch still deterministic")

	return _SmokeAssert.passed()
