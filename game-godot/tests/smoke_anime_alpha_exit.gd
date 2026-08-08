extends RefCounted
class_name SmokeAnimeAlphaExit

## FULL PRODUCT continuation III — Alpha exit digital systems.
## Avoids compile-time GameState identifier (Godot 4.5 -s).
## Does NOT claim Beta/RC as new. Art may be PROCEDURAL_FINAL after Cont V.

const _PrivateNetplayStack = preload("res://scripts/net/private_netplay_stack.gd")
const _BattleSceneCpuEval = preload("res://scripts/battle/battle_scene_cpu_eval.gd")
const _AntiTamper = preload("res://scripts/net/anti_tamper.gd")
const _SmokeAssert = preload("res://tests/smoke_assert.gd")


static func _gs():
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("GameState")


static func run() -> bool:
	_SmokeAssert.reset()

	for p in [
		"res://scripts/net/private_netplay_stack.gd",
		"res://scripts/net/rollback_session_gd.gd",
		"res://scripts/net/anti_tamper.gd",
		"res://scripts/net/disconnect_policy.gd",
		"res://scripts/net/replay_store.gd",
		"res://scripts/net/matchmaking_dev.gd",
		"res://scenes/menus/OnlinePrivateScene.tscn",
	]:
		_SmokeAssert.ok(FileAccess.file_exists(p) or ResourceLoader.exists(p), "missing %s" % p)

	var net: Dictionary = _PrivateNetplayStack.digital_pass_self_test()
	_SmokeAssert.ok(bool(net.get("ok", false)), "private netplay digital_pass_self_test failed")
	_SmokeAssert.ok(bool(net.get("token_earned", false)), "netplay token not earned")
	_SmokeAssert.ok(str(net.get("token", "")) == _PrivateNetplayStack.TOKEN, "netplay token string")
	_SmokeAssert.ok(bool(net.get("public_deploy", true)) == false, "must not claim public deploy")
	_SmokeAssert.ok(typeof(net.get("features", [])) == TYPE_ARRAY and int(net.get("features", []).size()) >= 10, "netplay feature coverage")

	var evidence_dir := ProjectSettings.globalize_path("res://").path_join("../playtest-evidence")
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	var np_path := evidence_dir.path_join("private_netplay_digital_pass.json")
	var nf := FileAccess.open(np_path, FileAccess.WRITE)
	if nf:
		nf.store_string(JSON.stringify(net, "\t"))
		nf.close()

	_SmokeAssert.ok(FileAccess.file_exists("res://scripts/battle/battle_scene_cpu_eval.gd"), "cpu eval helper")
	_SmokeAssert.ok(FileAccess.file_exists("res://tests/battle_scene_cpu_eval_runner.gd"), "cpu eval runner")
	var battle := FileAccess.open("res://scripts/battle/battle_scene.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(battle.contains("_eval_mode"), "battle eval mode")
	_SmokeAssert.ok(battle.contains("_complete_eval"), "battle eval complete")
	_SmokeAssert.ok(battle.contains("p1_cpu"), "battle both-cpu path")
	var gs_src := FileAccess.open("res://scripts/core/GameState.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(gs_src.contains("reset_battle_eval"), "GameState reset_battle_eval")
	_SmokeAssert.ok(gs_src.contains("p1_is_cpu"), "GameState p1_is_cpu")
	_SmokeAssert.ok(_BattleSceneCpuEval.ROSTER.size() == 7, "roster 7")
	_SmokeAssert.ok(_BattleSceneCpuEval.TOKEN.begins_with("ANIME_COMPETITIVE_AI"), "cpu token constant")

	var gs = _gs()
	_SmokeAssert.ok(gs != null, "GameState autoload")
	if gs != null:
		_BattleSceneCpuEval.configure_match("ember-vale", "rook-ironside", 3, 11)
		_SmokeAssert.ok(bool(gs.battle_eval_mode), "eval mode on")
		_SmokeAssert.ok(bool(gs.p1_is_cpu) and bool(gs.p2_is_cpu), "both cpu")
		_SmokeAssert.ok(int(gs.stocks) == 1, "eval stocks")

	_SmokeAssert.ok(gs_src.contains("begin_local_multiplayer"), "local multi")
	_SmokeAssert.ok(gs_src.contains("save_ruleset_preset"), "ruleset presets")
	_SmokeAssert.ok(gs_src.contains("_persist_save"), "save progress")
	_SmokeAssert.ok(gs_src.contains("high_contrast"), "high contrast")
	_SmokeAssert.ok(gs_src.contains("colorblind_markers"), "colorblind")
	_SmokeAssert.ok(gs_src.contains("master_volume"), "master volume")
	_SmokeAssert.ok(gs_src.contains("career_wins"), "career progression")
	var rules := FileAccess.open("res://scripts/menus/ruleset_scene.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(rules.contains("Local Multi") or rules.contains("begin_local_multiplayer"), "ruleset local multi UI")
	_SmokeAssert.ok(rules.contains("cpu_level = clampi") and rules.contains("1, 5"), "cpu tiers 1-5 in ruleset")
	var settings := FileAccess.open("res://scripts/menus/settings_scene.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(settings.contains("High Contrast"), "settings contrast")
	_SmokeAssert.ok(settings.contains("Colorblind"), "settings colorblind")
	_SmokeAssert.ok(settings.contains("Master Volume"), "settings volume")
	_SmokeAssert.ok(settings.contains("Career"), "settings career")

	if gs != null:
		gs.ensure_save_loaded()
		gs.career_wins = maxi(int(gs.career_wins), 1)
		gs.high_contrast = true
		gs.colorblind_markers = true
		gs.master_volume = 0.75
		gs.save_ruleset_preset("alpha-smoke")
		_SmokeAssert.ok(bool(gs.load_ruleset_preset("alpha-smoke")), "load ruleset preset")
		gs._persist_save()
	_SmokeAssert.ok(FileAccess.file_exists("user://aa_save.cfg") or FileAccess.file_exists("user://aa_rulesets.cfg"), "save files")

	var router := FileAccess.open("res://scripts/core/SceneRouter.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(router.contains("online_private"), "router online_private")
	var mode := FileAccess.open("res://scripts/menus/mode_select_scene.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(mode.contains("_on_online_pressed"), "mode select online")
	var fp := str(_AntiTamper.build_fingerprint())
	_SmokeAssert.ok(
		("anime-digital-rc-private" in fp) or ("anime-alpha-private" in fp),
		"build fingerprint (%s)" % fp,
	)

	return _SmokeAssert.passed()
