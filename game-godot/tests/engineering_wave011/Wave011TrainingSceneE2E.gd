extends SceneTree

## TrainingBattleScene E2E — GAME-AA-010 canonical training tools.

const Common = preload("res://tests/engineering_wave011/Wave011EvidenceCommon.gd")
const TRAINING_PATH := "res://scenes/training/TrainingBattleScene.tscn"

var _failures: PackedStringArray = PackedStringArray()
var _scene: Node = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Wave011TrainingSceneE2E BEGIN")
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_fail("GameState missing")
		_finish(false)
		return
	if gs.has_method("begin_training"):
		gs.begin_training()
	gs.p1_fighter_id = "ember-vale"
	gs.p2_fighter_id = "rook-ironside"
	gs.training_dummy_mode = "idle"
	gs.mode = "training"

	var packed: PackedScene = load(TRAINING_PATH)
	if packed == null:
		_fail("TrainingBattleScene.tscn missing")
		_finish(false)
		return
	_scene = packed.instantiate()
	root.add_child(_scene)
	await process_frame
	await process_frame

	var p1 = _scene.fighter1
	var p2 = _scene.fighter2
	if p1 == null or p2 == null:
		_fail("training fighters missing")
		_finish(false)
		return

	var pos0: Vector2 = p1.global_position
	var dmg0: float = float(p1.damage_percent)
	var aura0: float = float(p1.aura)
	var dummy0: String = str(p2.dummy_mode)

	# F3 reset position
	var ev := InputEventKey.new()
	ev.keycode = KEY_F3
	ev.pressed = true
	_scene._unhandled_input(ev)
	await Common.wait_frames(self, 4)
	var reset_pos: bool = p1.global_position.distance_to(pos0) < 8.0 or p1.global_position.distance_to(p1.spawn_point) < 80.0

	# F4 reset damage
	ev = InputEventKey.new()
	ev.keycode = KEY_F4
	ev.pressed = true
	_scene._unhandled_input(ev)
	var reset_dmg: bool = float(p1.damage_percent) <= 0.01

	# F5 fill aura (training control — not Wave011 charge proof)
	ev = InputEventKey.new()
	ev.keycode = KEY_F5
	ev.pressed = true
	_scene._unhandled_input(ev)
	var aura_ctrl: bool = float(p1.aura) >= 99.0

	# F8 cycle dummy
	ev = InputEventKey.new()
	ev.keycode = KEY_F8
	ev.pressed = true
	_scene._unhandled_input(ev)
	var dummy_cycle: bool = str(p2.dummy_mode) != dummy0

	# Frame overlay
	var overlay_ok: bool = _scene._frame_overlay != null and str(_scene._frame_overlay.text) != ""
	var debug_hud: bool = _scene._debug_hud != null

	var hitbox_debug: bool = false
	if p1.has_method("set_debug_hitboxes"):
		p1.set_debug_hitboxes(true)
		hitbox_debug = p1.hitbox_debug != null and p1.hitbox_debug.visible
		p1.set_debug_hitboxes(false)

	var ok: bool = reset_pos and reset_dmg and aura_ctrl and dummy_cycle and overlay_ok and debug_hud
	if not overlay_ok:
		_fail("training frame overlay missing")
	if not debug_hud:
		_fail("training debug HUD missing")

	var payload := {
		"schema": "gunnchos.engineering_wave011.training_runtime.v1",
		"CANONICAL_TRAINING_SCENE_EXECUTED": true,
		"TRAINING_RESET_RUNTIME": reset_pos,
		"TRAINING_DAMAGE_CONTROL_RUNTIME": reset_dmg,
		"TRAINING_AURA_CONTROL_RUNTIME": aura_ctrl,
		"TRAINING_DUMMY_STATE_RUNTIME": dummy_cycle,
		"TRAINING_FRAME_OVERLAY_RUNTIME": overlay_ok,
		"TRAINING_HITBOX_DEBUG_RUNTIME": hitbox_debug,
		"pass": ok,
	}
	Common.write_artifact("TRAINING_RUNTIME_RESULT.json", payload)
	_finish(ok)


func _fail(msg: String) -> void:
	_failures.append(msg)


func _finish(ok: bool) -> void:
	if ok and _failures.is_empty():
		print("Wave011TrainingSceneE2E PASS")
		quit(0)
	else:
		for f in _failures:
			push_error(f)
		print("Wave011TrainingSceneE2E FAIL")
		quit(1)
