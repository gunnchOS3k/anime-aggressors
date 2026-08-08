extends RefCounted
class_name SmokeDeviceA11yTelemetry

## Headless G2-C6 a11y + MatchTelemetry contracts (device-role reduce-motion / larger UI).
## Instantiates runtimes via preload so `-s` mode does not depend on autoload globals.

const _SmokeAssert = preload("res://tests/smoke_assert.gd")
const _DeviceRoleRuntime = preload("res://scripts/core/DeviceRoleRuntime.gd")
const _MatchTelemetry = preload("res://scripts/core/MatchTelemetry.gd")


static func run() -> bool:
	_SmokeAssert.reset()
	var tree := Engine.get_main_loop() as SceneTree
	_SmokeAssert.ok(tree != null, "SceneTree missing")
	if tree == null:
		return _SmokeAssert.passed()

	var roles: Node = _DeviceRoleRuntime.new()
	var telem: Node = _MatchTelemetry.new()
	tree.root.add_child(roles)
	tree.root.add_child(telem)

	# Device-role matrix + quartet.
	_SmokeAssert.ok(roles.has_method("roles"), "DeviceRoleRuntime.roles missing")
	var role_ids: Array = roles.roles()
	for role_id in ["student_14_5", "handheld_hybrid", "ds_xl_coder", "edge_io_rings"]:
		_SmokeAssert.ok(role_id in role_ids, "role list missing %s" % role_id)
		roles.set_role(role_id)
		_SmokeAssert.ok(roles.active_role == role_id, "active_role not %s" % role_id)

	# Accessibility: classroom role defaults lean reduce-motion; user override works.
	roles.set_role("student_14_5")
	_SmokeAssert.ok(roles.reduce_motion == true, "student_14_5 should default reduce_motion")
	roles.set_reduce_motion(false)
	_SmokeAssert.ok(roles.reduce_motion == false, "set_reduce_motion(false) should stick")
	_SmokeAssert.ok(not roles.fx_allows_camera_shake(), "reduce_motion false still gated by fx profile")
	roles.set_reduce_motion(true)
	_SmokeAssert.ok(not roles.fx_allows_camera_shake(), "reduce_motion blocks camera shake")
	_SmokeAssert.ok(not roles.fx_allows_hit_sparks(), "reduce_motion blocks hit sparks")

	roles.set_larger_ui(true)
	_SmokeAssert.ok(roles.ui_scale >= 1.25, "larger_ui should lift ui_scale")
	roles.set_larger_ui(false)

	# Peripheral / ring role FX is none.
	roles.set_role("edge_io_rings")
	_SmokeAssert.ok(str(roles.fx_profile) == "none", "edge_io_rings fx should be none")
	_SmokeAssert.ok(roles.fx_intensity() == 0.0, "edge_io_rings intensity zero")

	# Telemetry ring buffer: match_start → hit → ko → stock_loss → match_end.
	telem.start_match({
		"p1": "ember-vale",
		"p2": "rook-ironside",
		"stage": "training_yard",
		"stocks": 3,
		"timer": 99,
		"device_role": roles.active_role,
	})
	_SmokeAssert.ok(telem.count_of("match_start") == 1, "match_start recorded")
	telem.record_hit({"move_id": "jab_1", "damage": 3.0, "blocked": false, "hitstop_frames": 2})
	telem.record_ko("rook-ironside", 2)
	telem.record_stock_loss("rook-ironside", 2)
	telem.record_match_end(1)
	_SmokeAssert.ok(telem.count_of("hit") == 1, "hit recorded")
	_SmokeAssert.ok(telem.count_of("ko") == 1, "ko recorded")
	_SmokeAssert.ok(telem.count_of("stock_loss") == 1, "stock_loss recorded")
	_SmokeAssert.ok(telem.count_of("match_end") == 1, "match_end recorded")
	var recent: Array = telem.recent(8)
	_SmokeAssert.ok(recent.size() >= 5, "telemetry recent buffer populated")
	var start_evt: Dictionary = recent[0]
	_SmokeAssert.ok(str(start_evt.get("kind", "")) == "match_start", "first recent is match_start")
	var payload: Dictionary = start_evt.get("payload", {})
	_SmokeAssert.ok(str(payload.get("device_role", "")) == "edge_io_rings", "telemetry carries device_role")

	roles.queue_free()
	telem.queue_free()
	return _SmokeAssert.passed()
