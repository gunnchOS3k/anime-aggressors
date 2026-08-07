extends Node

## Autoload: applies G2-C6 device-role matrix (layout / input / fx) at runtime.
## Roles: student_14_5, handheld_hybrid, ds_xl_coder, edge_io_rings

signal role_changed(role_id: String)
signal accessibility_changed()

const MATRIX_PATH := "res://data/device/device_role_matrix.json"
const ROLE_IDS: Array[String] = [
	"student_14_5",
	"handheld_hybrid",
	"ds_xl_coder",
	"edge_io_rings",
]

var active_role: String = "student_14_5"
var matrix: Dictionary = {}
var reduce_motion: bool = false
var larger_ui: bool = false
var ui_scale: float = 1.0
var fx_profile: String = "reduced_classroom"
var layout_profile: String = "landscape"
var input_profile: String = "keyboard_mouse"
var touch_overlay_preferred: bool = false
var debug_hud_default: bool = false

func _ready() -> void:
	_load_matrix()
	var env_role := OS.get_environment("AA_DEVICE_ROLE")
	if env_role != "" and env_role in ROLE_IDS:
		set_role(env_role)
	else:
		set_role(active_role)
	_sync_project_settings()

func _load_matrix() -> void:
	if not FileAccess.file_exists(MATRIX_PATH):
		push_warning("DeviceRoleRuntime: missing %s" % MATRIX_PATH)
		matrix = {"device_roles": {}}
		return
	var f := FileAccess.open(MATRIX_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		matrix = parsed
	else:
		matrix = {"device_roles": {}}

func roles() -> Array[String]:
	return ROLE_IDS.duplicate()

func role_profile(role_id: String = "") -> Dictionary:
	var id := role_id if role_id != "" else active_role
	var roles: Dictionary = matrix.get("device_roles", {})
	if roles.has(id):
		return roles[id]
	return {}

func set_role(role_id: String) -> void:
	if role_id not in ROLE_IDS:
		push_warning("DeviceRoleRuntime: unknown role %s" % role_id)
		return
	active_role = role_id
	var p: Dictionary = role_profile(role_id)
	input_profile = str(p.get("input", "keyboard_mouse"))
	layout_profile = str(p.get("layout", "landscape"))
	fx_profile = str(p.get("fx", "full"))
	touch_overlay_preferred = bool(p.get("touch_overlay", false))
	debug_hud_default = bool(p.get("debug_hud_default", false))
	ui_scale = float(p.get("ui_scale", 1.0))
	# Classroom / peripheral defaults lean reduce-motion; user override wins if set.
	if not ProjectSettings.has_setting("anime_aggressors/accessibility/reduce_motion_user"):
		reduce_motion = bool(p.get("reduce_motion", false)) or fx_profile in ["reduced_classroom", "none"]
	else:
		reduce_motion = bool(ProjectSettings.get_setting("anime_aggressors/accessibility/reduce_motion_user"))
	if larger_ui:
		ui_scale = maxf(ui_scale, 1.25)
	_sync_project_settings()
	_apply_touch_preference()
	role_changed.emit(active_role)
	accessibility_changed.emit()

func cycle_role() -> String:
	var idx := ROLE_IDS.find(active_role)
	idx = (idx + 1) % ROLE_IDS.size()
	set_role(ROLE_IDS[idx])
	return active_role

func set_reduce_motion(on: bool) -> void:
	reduce_motion = on
	ProjectSettings.set_setting("anime_aggressors/accessibility/reduce_motion_user", on)
	_sync_project_settings()
	accessibility_changed.emit()

func set_larger_ui(on: bool) -> void:
	larger_ui = on
	ProjectSettings.set_setting("anime_aggressors/accessibility/larger_ui", on)
	if on:
		ui_scale = maxf(ui_scale, 1.25)
	else:
		ui_scale = float(role_profile().get("ui_scale", 1.0))
	accessibility_changed.emit()

func fx_allows_camera_shake() -> bool:
	if reduce_motion:
		return false
	return fx_profile in ["full", "debug"]

func fx_allows_hit_sparks() -> bool:
	if reduce_motion:
		return false
	return fx_profile != "none"

func fx_intensity() -> float:
	match fx_profile:
		"none":
			return 0.0
		"reduced_classroom":
			return 0.35
		"debug":
			return 0.7
		_:
			return 1.0

func apply_to_battle_hud(root: Node) -> void:
	## HUD root is a CanvasLayer in BattleScene (not a CanvasItem).
	if root == null:
		return
	var scale_v := Vector2(ui_scale, ui_scale) if larger_ui or ui_scale > 1.01 else Vector2.ONE
	if root is CanvasLayer:
		(root as CanvasLayer).scale = scale_v
	elif root is CanvasItem:
		(root as CanvasItem).scale = scale_v

func apply_layout_hint(camera: Camera2D) -> void:
	if camera == null:
		return
	match layout_profile:
		"handheld":
			camera.zoom = Vector2(1.35, 1.35)
		"dual_screen_code_arena":
			camera.zoom = Vector2(1.05, 1.05)
		"peripheral_only":
			camera.zoom = Vector2(1.2, 1.2)
		_:
			camera.zoom = Vector2(1.2, 1.2)

func summary() -> Dictionary:
	return {
		"role": active_role,
		"input": input_profile,
		"layout": layout_profile,
		"fx": fx_profile,
		"reduce_motion": reduce_motion,
		"larger_ui": larger_ui,
		"ui_scale": ui_scale,
		"touch_overlay": touch_overlay_preferred,
		"debug_hud_default": debug_hud_default,
	}

func _sync_project_settings() -> void:
	ProjectSettings.set_setting("rendering/accessibility/reduce_motion", reduce_motion)
	ProjectSettings.set_setting("anime_aggressors/device_role", active_role)
	ProjectSettings.set_setting("anime_aggressors/fx_profile", fx_profile)

func _apply_touch_preference() -> void:
	var tim = get_node_or_null("/root/TouchInputManager")
	if tim == null:
		return
	if touch_overlay_preferred and tim.has_method("set_touch_mode"):
		# Force-on for handheld hybrid when API exists; otherwise leave auto.
		if tim.has_method("force_show"):
			tim.force_show(true)
	elif layout_profile == "peripheral_only" and tim.has_method("force_show"):
		tim.force_show(false)
