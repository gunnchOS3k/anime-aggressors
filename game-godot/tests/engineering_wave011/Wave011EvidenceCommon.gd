extends RefCounted
class_name Wave011EvidenceCommon

## Shared Wave011 evidence helpers — restage is TEST PRECONDITION only.

const ART_DIR := "res://artifacts/engineering_wave011"
const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const ROSTER := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

static var restage_count: int = 0
static var battle_sessions_spawned: int = 0
static var session_state_leaks: int = 0
static var active_battle = null


static func write_artifact(filename: String, payload: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ART_DIR))
	var f := FileAccess.open(ART_DIR.path_join(filename), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


static func release_slot(slot: int) -> void:
	for suffix in ["left", "right", "up", "down", "jump", "attack", "special", "shield", "grab", "dodge"]:
		var action := "p%d_%s" % [slot, suffix]
		if InputMap.has_action(action):
			Input.action_release(action)


static func release_p1() -> void:
	release_slot(1)


static func release_p2() -> void:
	release_slot(2)


static func restage_on_platform(p1, p2, gap: float) -> void:
	## TEST PRECONDITION — not gameplay proof.
	restage_count += 1
	var floor_y: float = float(p1.spawn_point.y)
	if p2.is_on_floor() and not p1.is_on_floor():
		floor_y = p2.global_position.y
	elif p1.is_on_floor():
		floor_y = p1.global_position.y
	var cx: float = float(p1.platform_center_x)
	p1.global_position = Vector2(cx - gap * 0.5, floor_y)
	p2.global_position = Vector2(cx + gap * 0.5, floor_y)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1


static func wait_frames(tree: SceneTree, n: int) -> void:
	for i in n:
		await tree.physics_frame


static func teardown_active_battle(tree: SceneTree) -> void:
	release_p1()
	release_p2()
	if active_battle != null and is_instance_valid(active_battle):
		active_battle.queue_free()
		active_battle = null
	for i in 8:
		await tree.physics_frame


static func spawn_fresh_battle(
	tree: SceneTree,
	p1_fighter_id: String,
	p2_fighter_id: String = "rook-ironside"
) -> Dictionary:
	release_p1()
	release_p2()
	await teardown_active_battle(tree)
	var gs = tree.root.get_node_or_null("/root/GameState")
	if gs == null:
		return {"ok": false, "error": "GameState autoload missing"}
	gs.begin_local_versus(false)
	gs.p1_fighter_id = p1_fighter_id
	gs.p2_fighter_id = p2_fighter_id
	gs.p1_is_cpu = false
	gs.p2_is_cpu = false
	gs.battle_eval_mode = false
	gs.debug_combat_hud = false
	gs.mode = "versus"
	var packed: PackedScene = load(BATTLE_PATH)
	if packed == null:
		return {"ok": false, "error": "BattleScene.tscn failed to load"}
	var scene = packed.instantiate()
	tree.root.add_child(scene)
	battle_sessions_spawned += 1
	active_battle = scene
	await tree.process_frame
	await tree.process_frame
	if bool(gs.battle_eval_mode):
		session_state_leaks += 1
		return {"ok": false, "error": "battle_eval_mode must remain false"}
	if scene.get_node_or_null("ProductionGateHarness") != null:
		session_state_leaks += 1
		return {"ok": false, "error": "ProductionGateHarness present"}
	var ready := false
	var start := Time.get_ticks_msec() / 1000.0
	while Time.get_ticks_msec() / 1000.0 - start < 14.0:
		await tree.physics_frame
		if scene.fighter1 != null and bool(scene.fighter1.controls_enabled):
			ready = true
			break
	if not ready:
		return {"ok": false, "error": "countdown did not enable controls"}
	var p1 = scene.fighter1
	var p2 = scene.fighter2
	if p1 == null or p2 == null:
		return {"ok": false, "error": "BattleScene missing fighters"}
	for f in [p1, p2]:
		f.dummy_mode = "idle"
		f.is_cpu = false
		f.controls_enabled = true
	return {
		"ok": true,
		"scene": scene,
		"p1": p1,
		"p2": p2,
		"gs": gs,
	}


static func provenance_flags() -> Dictionary:
	return {
		"TEST_PRECONDITION_RESTAGE": true,
		"RESTAGE_COUNT": restage_count,
		"RESTAGE_USED_AS_GAMEPLAY_PROOF": false,
		"INPUT_INTENT_COUNTED_AS_SUCCESS": false,
		"battle_eval_mode": false,
		"production_gate_harness_used_as_proof": false,
		"aura_assign_used_as_charge_proof": false,
		"ROSTER_PROOF_USES_CANONICAL_BATTLE_BOOTSTRAP": true,
		"BATTLE_SESSIONS_SPAWNED": battle_sessions_spawned,
		"SESSION_STATE_LEAKS": session_state_leaks,
	}
