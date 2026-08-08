extends RefCounted
class_name SmokeAnimeBetaContent

## FULL PRODUCT Continuation IV — Anime Beta Content Complete (digital).
## Does NOT claim Alpha tokens as new. Art gaps remain honest.

const _AuraIdentity = preload("res://scripts/combat/aura_identity.gd")
const _StageBuilder = preload("res://scripts/battle/stage_procedural_builder.gd")
const _OnlineMM = preload("res://scripts/net/online_matchmaking_architecture.gd")
const _TournamentRooms = preload("res://scripts/net/tournament_rooms.gd")
const _SmokeAssert = preload("res://tests/smoke_assert.gd")

const FIGHTERS: Array[String] = [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

const COMPETITIVE: Array[String] = [
	"skyline-arena", "neon-rooftops", "cascade-foundry", "void-pier", "ember-courtyard",
]


static func _gs():
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("GameState")


static func run() -> bool:
	_SmokeAssert.reset()

	# Content inventory files (repo-relative via ProjectSettings).
	var root := ProjectSettings.globalize_path("res://").path_join("..")
	for rel in [
		"content/production_manifest.json",
		"content/provenance.json",
		"content/missing_assets.json",
		"docs/decisions/ADR-GAME-AA-001-launch-fighters.md",
		"docs/decisions/ADR-GAME-AA-002-launch-stages.md",
		"docs/decisions/ADR-GAME-AA-003-launch-modes.md",
		"docs/decisions/ADR-GAME-AA-004-online-rc-bar.md",
	]:
		_SmokeAssert.ok(FileAccess.file_exists(root.path_join(rel)), "missing %s" % rel)

	var mf := FileAccess.open(root.path_join("content/production_manifest.json"), FileAccess.READ)
	var manifest: Dictionary = JSON.parse_string(mf.get_as_text())
	_SmokeAssert.ok(str(manifest.get("token_target", "")) == "ANIME_BETA_CONTENT_COMPLETE_DIGITAL", "token target")
	_SmokeAssert.ok(bool(manifest.get("honesty", {}).get("alpha_tokens_not_repackaged", false)), "must not repackage alpha")
	_SmokeAssert.ok(bool(manifest.get("honesty", {}).get("final_painted_art_complete", true)) == false, "must not claim final art")
	_SmokeAssert.ok(int(manifest.get("fighters", []).size()) == 7, "7 fighters")
	_SmokeAssert.ok(int(manifest.get("modes", []).size()) >= 13, "mode suite")

	# Fighters fully authored (data + uniqueness fields).
	var silhouettes := {}
	var victories := {}
	for fid in FIGHTERS:
		var fp := "res://data/fighters/%s.json" % fid
		_SmokeAssert.ok(FileAccess.file_exists(fp), "fighter %s" % fid)
		var f := FileAccess.open(fp, FileAccess.READ)
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		var auth: Dictionary = data.get("authorship", {})
		_SmokeAssert.ok(not auth.is_empty(), "%s authorship" % fid)
		_SmokeAssert.ok(str(auth.get("silhouette", "")) != "", "%s silhouette" % fid)
		_SmokeAssert.ok(str(auth.get("victory_pose", "")) != "", "%s victory" % fid)
		_SmokeAssert.ok(not silhouettes.has(str(auth.silhouette)), "unique silhouette %s" % auth.silhouette)
		silhouettes[str(auth.silhouette)] = fid
		_SmokeAssert.ok(not victories.has(str(auth.victory_pose)), "unique victory %s" % auth.victory_pose)
		victories[str(auth.victory_pose)] = fid
		var statuses: Dictionary = auth.get("assetStatuses", {})
		_SmokeAssert.ok(str(statuses.get("moves", "")) == "FINAL_ORIGINAL", "%s moves status" % fid)
		_SmokeAssert.ok(str(statuses.get("model_glb", "")) == "REQUIRES_ART_PRODUCTION", "%s honest glb gap" % fid)
		var mp := FileAccess.open("res://data/moves/%s.json" % fid, FileAccess.READ)
		var moves: Dictionary = JSON.parse_string(mp.get_as_text())
		_SmokeAssert.ok(int(moves.get("moves", []).size()) >= 20, "%s move count" % fid)
		_SmokeAssert.ok(_AuraIdentity.profile_for(fid).get("tag", "") != "", "%s aura" % fid)

	# Stages: no greybox for launch competitive candidates.
	for sid in COMPETITIVE:
		var sf := FileAccess.open("res://data/stages/%s.json" % sid, FileAccess.READ)
		var sd: Dictionary = JSON.parse_string(sf.get_as_text())
		_SmokeAssert.ok(str(sd.get("productionStatus", "")).begins_with("procedural_final"), "%s not greybox" % sid)
		_SmokeAssert.ok(str(sd.get("geometryStatus", "")) == "PROCEDURAL_FINAL", "%s geometry" % sid)
		_SmokeAssert.ok(str(sd.get("artStatus", "")) == "REQUIRES_ART_PRODUCTION", "%s art honesty" % sid)
		_SmokeAssert.ok(sd.has("cameraProfile"), "%s camera" % sid)
		_SmokeAssert.ok(sd.has("lightingProfile"), "%s lighting" % sid)
		_SmokeAssert.ok(sd.has("performanceTier"), "%s perf" % sid)
		_SmokeAssert.ok(sd.has("a11y"), "%s a11y" % sid)
		_SmokeAssert.ok(sd.has("audioBed"), "%s audioBed" % sid)
		_SmokeAssert.ok(sd.has("blastZones") and sd.has("spawnPoints"), "%s spawn/blast" % sid)

	# Procedural builder present + themed.
	_SmokeAssert.ok(FileAccess.file_exists("res://scripts/battle/stage_procedural_builder.gd"), "stage builder")
	var themes: Dictionary = _StageBuilder.THEMES
	for sid in COMPETITIVE:
		_SmokeAssert.ok(themes.has(sid), "theme for %s" % sid)

	# Modes wired.
	var router := FileAccess.open("res://scripts/core/SceneRouter.gd", FileAccess.READ).get_as_text()
	for key in ["team", "challenges", "online_hub", "tournament", "online_private", "arcade", "tutorial", "hazards"]:
		_SmokeAssert.ok(router.contains('"%s"' % key), "router %s" % key)
	var mode := FileAccess.open("res://scripts/menus/mode_select_scene.gd", FileAccess.READ).get_as_text()
	for hook in ["_on_team_pressed", "_on_challenges_pressed", "_on_online_pressed", "_on_tournament_pressed"]:
		_SmokeAssert.ok(mode.contains(hook), "mode select %s" % hook)
	for scene in [
		"res://scenes/menus/TeamScene.tscn",
		"res://scenes/menus/ChallengesScene.tscn",
		"res://scenes/menus/OnlineHubScene.tscn",
		"res://scenes/menus/TournamentScene.tscn",
	]:
		_SmokeAssert.ok(ResourceLoader.exists(scene), "scene %s" % scene)

	var gs = _gs()
	_SmokeAssert.ok(gs != null, "GameState")
	if gs != null:
		gs.begin_team_mode()
		_SmokeAssert.ok(bool(gs.team_mode) and str(gs.mode) == "team", "team mode")
		gs.begin_challenge(0)
		_SmokeAssert.ok(str(gs.mode) == "challenges" and str(gs.challenge_id) != "", "challenge mode")
		gs.begin_online_queue("unranked")
		_SmokeAssert.ok(str(gs.online_queue) == "unranked", "online unranked")

	var mm: Dictionary = _OnlineMM.digital_self_test()
	_SmokeAssert.ok(bool(mm.get("ok", false)), "online mm architecture")
	_SmokeAssert.ok(bool(mm.get("public_deploy", true)) == false, "no public deploy")
	var tr: Dictionary = _TournamentRooms.digital_self_test()
	_SmokeAssert.ok(bool(tr.get("ok", false)), "tournament rooms")

	# Move-graph uniqueness evidence from node builder.
	_SmokeAssert.ok(FileAccess.file_exists(root.path_join("playtest-evidence/move_graph_uniqueness.json")), "move graph evidence")

	return _SmokeAssert.passed()
