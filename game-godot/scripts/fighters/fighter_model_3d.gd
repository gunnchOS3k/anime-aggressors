extends Node2D
class_name FighterModel3D

## Animated GLB presentation inside deterministic 2D combat. The transparent
## SubViewport keeps physics in CharacterBody2D while rendering a real 3D rig.
## Character-life layer adds per-fighter timing, expression, aura language,
## directional throw body acting, and victory/defeat presentation.

const _CharacterLife = preload("res://scripts/fighters/fighter_character_life.gd")

const VIEWPORT_SIZE := Vector2i(220, 280)
const DISPLAY_SCALE := Vector2(0.38, 0.38)
const PROXY_LABEL := "ORIGINAL 3D PROXY"

var _viewport: SubViewport
var _model_root: Node3D
var _display: Sprite2D
var _animation_player: AnimationPlayer
var _loaded_model: Node3D
var _loaded := false
var _last_clip := ""
var _fighter_id: String = ""
var _life: Dictionary = {}
var _expression_label: Label
var _aura_overlay: ColorRect
var _face_chip: ColorRect
var _presentation_tween: Tween
var _throw_dir: String = "forward"
var _expression: String = "neutral"
var _aura_level: int = 0
var _select_mode: bool = false


func _ready() -> void:
	_build_viewport()


func configure(fighter_data: Dictionary) -> bool:
	_clear_model()
	_fighter_id = str(fighter_data.get("id", ""))
	_life = _CharacterLife.for_id(_fighter_id)
	var model_path := str(fighter_data.get("modelPath", ""))
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		_set_loaded(false)
		return false
	var resource := load(model_path)
	if not resource is PackedScene:
		push_warning("Fighter model is not a PackedScene: %s" % model_path)
		_set_loaded(false)
		return false
	var instance := (resource as PackedScene).instantiate()
	if not instance is Node3D:
		instance.queue_free()
		push_warning("Fighter model root must be Node3D: %s" % model_path)
		_set_loaded(false)
		return false
	_loaded_model = instance as Node3D
	_loaded_model.name = "ImportedFighter_%s" % _fighter_id
	_loaded_model.rotation_degrees.y = -8.0 + float(_life.get("lean", 0.0)) * 40.0
	_model_root.add_child(_loaded_model)
	_animation_player = _find_animation_player(_loaded_model)
	_set_loaded(true)
	set_expression(str(_life.get("expression_idle", "neutral")))
	_play_clip("idle")
	_apply_playback_scale("idle")
	return true


func is_model_loaded() -> bool:
	return _loaded


func has_imported_animations() -> bool:
	return _animation_player != null and not _animation_player.get_animation_list().is_empty()


func get_life() -> Dictionary:
	return _life


func set_select_mode(enabled: bool) -> void:
	_select_mode = enabled


func set_facing(direction: int) -> void:
	if _display:
		_display.scale.x = absf(_display.scale.x) * (1.0 if direction >= 0 else -1.0)


func set_aura_level(level: int) -> void:
	_aura_level = clampi(level, 0, 4)
	_refresh_aura_overlay()


func set_expression(state: String) -> void:
	_expression = state
	if _expression_label:
		_expression_label.text = _expression_glyph(state)
	if _face_chip:
		_face_chip.color = _expression_color(state)


func play_for_state(state: String, move: Dictionary = {}) -> void:
	if not _loaded:
		return
	if move.has("throw_direction"):
		_throw_dir = str(move.get("throw_direction", "forward"))
	var clip := _clip_for_state(state, str(move.get("move_id", "")))
	_play_clip(clip)
	_apply_playback_scale(clip)
	_update_expression_for_state(state)
	if state in [FighterStates.THROW_STARTUP, FighterStates.THROW_RELEASE]:
		_play_throw_presentation(_throw_dir)
	if state == FighterStates.KO or str(move.get("presentation", "")) == "defeat":
		_play_defeat_presentation()
	if str(move.get("presentation", "")) == "victory":
		_play_victory_presentation()


func play_selection_focus() -> void:
	if not _loaded:
		return
	set_expression("confident")
	_play_clip("idle")
	_apply_playback_scale("idle")
	if _loaded_model:
		if _presentation_tween:
			_presentation_tween.kill()
		_presentation_tween = create_tween()
		_presentation_tween.tween_property(_loaded_model, "rotation_degrees:y", 12.0, 0.25)
		_presentation_tween.tween_property(_loaded_model, "rotation_degrees:y", -8.0, 0.35)


func play_lock_in() -> void:
	set_expression("confident")
	_play_victory_presentation()


func play_victory_presentation() -> void:
	_play_victory_presentation()


func play_defeat_presentation() -> void:
	_play_defeat_presentation()


func _build_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "Fighter3DViewport"
	_viewport.size = VIEWPORT_SIZE
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)

	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.78, 0.92)
	environment.ambient_light_energy = 1.15
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	_viewport.add_child(environment_node)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-38, -28, 0)
	key_light.light_color = Color(1.0, 0.87, 0.72)
	key_light.light_energy = 1.8
	_viewport.add_child(key_light)
	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(20, 150, 0)
	rim_light.light_color = Color(0.45, 0.66, 1.0)
	rim_light.light_energy = 1.15
	_viewport.add_child(rim_light)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.72
	camera.position = Vector3(0, 1.18, 5.0)
	camera.current = true
	_viewport.add_child(camera)
	camera.look_at(Vector3(0, 1.18, 0), Vector3.UP)

	_model_root = Node3D.new()
	_model_root.name = "ModelRoot"
	_viewport.add_child(_model_root)
	_display = Sprite2D.new()
	_display.name = "ModelDisplay"
	_display.texture = _viewport.get_texture()
	_display.position = Vector2(0, -49)
	_display.scale = DISPLAY_SCALE
	_display.visible = false
	add_child(_display)

	_aura_overlay = ColorRect.new()
	_aura_overlay.name = "AuraIdentity"
	_aura_overlay.size = Vector2(70, 90)
	_aura_overlay.position = Vector2(-35, -95)
	_aura_overlay.color = Color(1, 1, 1, 0)
	_aura_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_aura_overlay)

	_face_chip = ColorRect.new()
	_face_chip.name = "FaceChip"
	_face_chip.size = Vector2(18, 10)
	_face_chip.position = Vector2(-9, -78)
	_face_chip.color = Color(1, 0.92, 0.86, 0.0)
	_face_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face_chip)

	_expression_label = Label.new()
	_expression_label.name = "ExpressionMark"
	_expression_label.position = Vector2(-8, -82)
	_expression_label.add_theme_font_size_override("font_size", 10)
	_expression_label.modulate = Color(1, 1, 1, 0.9)
	_expression_label.text = ""
	add_child(_expression_label)

	var proxy_label := Label.new()
	proxy_label.name = "ModelTierLabel"
	proxy_label.text = PROXY_LABEL
	proxy_label.position = Vector2(-47, -86)
	proxy_label.add_theme_font_size_override("font_size", 8)
	proxy_label.modulate = Color(0.78, 0.9, 1.0, 0.82)
	proxy_label.visible = false
	add_child(proxy_label)


func _clear_model() -> void:
	_animation_player = null
	_loaded_model = null
	_last_clip = ""
	if _model_root:
		for child in _model_root.get_children():
			child.free()


func _set_loaded(value: bool) -> void:
	_loaded = value
	if _display:
		_display.visible = value
	var tier_label := get_node_or_null("ModelTierLabel") as Label
	if tier_label:
		tier_label.visible = false


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null


func _clip_for_state(state: String, move_id: String) -> String:
	if (
		state
		in [
			FighterStates.ATTACK_STARTUP, FighterStates.ATTACK_ACTIVE, FighterStates.ATTACK_RECOVERY
		]
	):
		if move_id in ["jab_1", "jab_2", "heavy_attack"]:
			return move_id
		return "heavy_attack" if "heavy" in move_id else "jab_1"
	if (
		state
		in [
			FighterStates.SPECIAL_STARTUP,
			FighterStates.SPECIAL_ACTIVE,
			FighterStates.SPECIAL_RECOVERY
		]
	):
		return "special"
	if state in [FighterStates.THROW_STARTUP, FighterStates.THROW_RELEASE]:
		# Prefer directional throw clip when authored; fall back to acting layer.
		var dir_clip := "throw_%s" % _throw_dir
		if _animation_player and _animation_player.has_animation(dir_clip):
			return dir_clip
		return "throw_forward"
	match state:
		FighterStates.WALK:
			return "walk"
		FighterStates.RUN:
			return "run"
		FighterStates.DASH, FighterStates.DODGE_START, FighterStates.DODGE_ACTIVE:
			return "dash"
		FighterStates.JUMP, FighterStates.JUMP_SQUAT, FighterStates.DOUBLE_JUMP:
			return "jump"
		FighterStates.FALL, FighterStates.FAST_FALL, FighterStates.TUMBLE:
			return "fall"
		FighterStates.LAND:
			return "land"
		FighterStates.SHIELD_START, FighterStates.SHIELD_HOLD, FighterStates.SHIELD_STUN:
			return "shield"
		FighterStates.GRAB_STARTUP, FighterStates.GRAB_ACTIVE, FighterStates.GRAB_HOLD:
			return "jab_1"
		FighterStates.AURA_CHARGE, FighterStates.AURA_READY:
			return "aura_charge"
		FighterStates.AURA_BURST_STARTUP, FighterStates.AURA_BURST_ACTIVE, FighterStates.AURA_BURST_RECOVERY:
			return "aura_burst"
		FighterStates.HURT_LIGHT:
			return "hurt_light"
		FighterStates.HURT_HEAVY, FighterStates.HITSTUN:
			return "hurt_heavy"
		FighterStates.LAUNCHED:
			return "launched"
		FighterStates.KO:
			return "ko"
		_:
			return "idle"


func _play_clip(requested: String) -> void:
	if _animation_player == null:
		return
	var clip := _resolve_animation_name(requested)
	if clip.is_empty() or str(clip) == _last_clip:
		_apply_playback_scale(requested)
		return
	var animation := _animation_player.get_animation(clip)
	if animation:
		var should_loop := requested in ["idle", "walk", "run", "fall", "shield", "aura_charge"]
		animation.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	_animation_player.play(clip, 0.08)
	_last_clip = str(clip)


func _apply_playback_scale(clip: String) -> void:
	if _animation_player == null or _life.is_empty():
		return
	var scale := 1.0
	if clip in ["idle", "shield"]:
		scale = float(_life.get("idle_speed", 1.0))
	elif clip in ["walk", "run", "dash"]:
		scale = float(_life.get("run_speed", 1.0))
	elif clip in ["jab_1", "jab_2", "heavy_attack", "special", "aura_burst", "throw_forward", "throw_back", "throw_up", "throw_down"]:
		scale = float(_life.get("attack_speed", 1.0))
	_animation_player.speed_scale = scale


func _resolve_animation_name(requested: String) -> StringName:
	if _animation_player.has_animation(requested):
		return StringName(requested)
	for candidate in _animation_player.get_animation_list():
		var candidate_text := str(candidate)
		if (
			candidate_text.ends_with("/" + requested)
			or candidate_text.ends_with("|" + requested)
			or candidate_text.ends_with("_" + requested)
		):
			return candidate
	return StringName()


func _update_expression_for_state(state: String) -> void:
	if state in [FighterStates.AURA_CHARGE, FighterStates.AURA_READY]:
		set_expression(str(_life.get("expression_charge", "charging")))
	elif state in [FighterStates.HURT_LIGHT, FighterStates.HURT_HEAVY, FighterStates.HITSTUN, FighterStates.LAUNCHED]:
		set_expression(str(_life.get("expression_hurt", "hurt")))
	elif state == FighterStates.KO:
		set_expression("defeat")
	elif state in [FighterStates.ATTACK_STARTUP, FighterStates.SPECIAL_STARTUP, FighterStates.THROW_STARTUP]:
		set_expression("focused")
	elif state in [FighterStates.IDLE, FighterStates.WALK]:
		set_expression(str(_life.get("expression_idle", "neutral")))


func _refresh_aura_overlay() -> void:
	if _aura_overlay == null:
		return
	if _aura_level <= 0:
		_aura_overlay.color.a = 0.0
		return
	var shape := str(_life.get("aura_shape", "orb"))
	var pulse := float(_life.get("aura_pulse", 1.0))
	var alpha := clampf(0.12 + float(_aura_level) * 0.1 * pulse, 0.12, 0.55)
	match shape:
		"tongues":
			_aura_overlay.color = Color(1.0, 0.35, 0.1, alpha)
		"rings":
			_aura_overlay.color = Color(0.55, 0.6, 0.7, alpha)
		"arcs":
			_aura_overlay.color = Color(0.95, 0.9, 0.2, alpha)
		"ribbons":
			_aura_overlay.color = Color(0.55, 0.85, 1.0, alpha)
		"crystals":
			_aura_overlay.color = Color(0.7, 0.9, 1.0, alpha)
		"orbit":
			_aura_overlay.color = Color(0.7, 0.55, 1.0, alpha)
		"smoke":
			_aura_overlay.color = Color(0.35, 0.2, 0.55, alpha)
		_:
			_aura_overlay.color = Color(1, 1, 1, alpha)
	# Distinct shape language via aspect — not recolor-only.
	match shape:
		"rings":
			_aura_overlay.size = Vector2(78, 78)
			_aura_overlay.position = Vector2(-39, -90)
		"arcs":
			_aura_overlay.size = Vector2(54, 96)
			_aura_overlay.position = Vector2(-27, -98)
		"ribbons":
			_aura_overlay.size = Vector2(40, 110)
			_aura_overlay.position = Vector2(-20, -108)
		"crystals":
			_aura_overlay.size = Vector2(48, 88)
			_aura_overlay.position = Vector2(-24, -95)
		"orbit":
			_aura_overlay.size = Vector2(88, 66)
			_aura_overlay.position = Vector2(-44, -86)
		"smoke":
			_aura_overlay.size = Vector2(72, 100)
			_aura_overlay.position = Vector2(-36, -100)
		_:
			_aura_overlay.size = Vector2(70, 90)
			_aura_overlay.position = Vector2(-35, -95)


func _play_throw_presentation(direction: String) -> void:
	if _loaded_model == null:
		return
	if _presentation_tween:
		_presentation_tween.kill()
	_presentation_tween = create_tween()
	var style := str(_life.get("throw_style", "blast"))
	var start_rot := _loaded_model.rotation_degrees
	var start_pos := _loaded_model.position
	match direction:
		"back":
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:y", start_rot.y + 70.0, 0.12)
			_presentation_tween.tween_property(_loaded_model, "position:z", start_pos.z - 0.15, 0.1)
		"up":
			_presentation_tween.tween_property(_loaded_model, "position:y", start_pos.y + 0.28, 0.12)
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:x", start_rot.x - 18.0, 0.12)
		"down":
			_presentation_tween.tween_property(_loaded_model, "position:y", start_pos.y - 0.2, 0.1)
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:x", start_rot.x + 22.0, 0.1)
		_:
			var yaw := 25.0 if style != "pin" else 12.0
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:y", start_rot.y - yaw, 0.1)
			_presentation_tween.tween_property(_loaded_model, "position:z", start_pos.z + 0.2, 0.1)
	_presentation_tween.tween_property(_loaded_model, "rotation_degrees", start_rot, 0.18)
	_presentation_tween.parallel().tween_property(_loaded_model, "position", start_pos, 0.18)


func _play_victory_presentation() -> void:
	set_expression("victory")
	if _loaded_model == null:
		return
	if _presentation_tween:
		_presentation_tween.kill()
	_presentation_tween = create_tween()
	var pose := str(_life.get("victory_pose", "proud_fist"))
	match pose:
		"fist_heart":
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:x", -8.0, 0.18)
			_presentation_tween.tween_property(_loaded_model, "position:y", 0.04, 0.18)
		"snap_spin":
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:y", 360.0, 0.35)
			_presentation_tween.tween_property(_loaded_model, "position:y", 0.16, 0.2)
		"lifted_arms":
			_presentation_tween.tween_property(_loaded_model, "position:y", 0.22, 0.2)
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:x", -12.0, 0.2)
		"subtle_nod":
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:x", 10.0, 0.15)
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:x", 0.0, 0.2)
		"arms_open":
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:y", 28.0, 0.22)
			_presentation_tween.tween_property(_loaded_model, "position:y", 0.1, 0.22)
		"smirk":
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:y", -22.0, 0.2)
			_presentation_tween.tween_property(_loaded_model, "position:z", 0.08, 0.2)
		_:
			_presentation_tween.tween_property(_loaded_model, "position:y", 0.12, 0.15)
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:y", 18.0, 0.2)
			_presentation_tween.tween_property(_loaded_model, "position:y", 0.0, 0.2)


func _play_defeat_presentation() -> void:
	set_expression("defeat")
	if _loaded_model == null:
		return
	if _presentation_tween:
		_presentation_tween.kill()
	_presentation_tween = create_tween()
	var pose := str(_life.get("defeat_pose", "kneel_guard"))
	match pose:
		"kneel_upright", "compose", "kneel_compose":
			_presentation_tween.tween_property(_loaded_model, "position:y", -0.12, 0.28)
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:x", 12.0, 0.28)
		"hips_annoyed":
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:z", 8.0, 0.2)
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:y", -15.0, 0.2)
		"soft_kneel":
			_presentation_tween.tween_property(_loaded_model, "position:y", -0.1, 0.3)
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:x", 16.0, 0.3)
		"fade_kneel":
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:y", 35.0, 0.3)
			_presentation_tween.tween_property(_loaded_model, "position:y", -0.1, 0.3)
		_:
			_presentation_tween.tween_property(_loaded_model, "rotation_degrees:x", 18.0, 0.25)
			_presentation_tween.tween_property(_loaded_model, "position:y", -0.08, 0.2)


func _expression_glyph(state: String) -> String:
	match state:
		"confident":
			return "∶)"
		"focused":
			return "⋯"
		"surprised":
			return "∶o"
		"strained", "charging":
			return "∶>"
		"hurt":
			return "∶("
		"victory":
			return "★"
		"defeat":
			return "…"
		_:
			return "∶|"


func _expression_color(state: String) -> Color:
	match state:
		"confident", "victory":
			return Color(1.0, 0.85, 0.35, 0.85)
		"focused", "charging":
			return Color(0.55, 0.85, 1.0, 0.8)
		"hurt", "strained":
			return Color(1.0, 0.45, 0.45, 0.85)
		"defeat":
			return Color(0.7, 0.7, 0.75, 0.7)
		_:
			return Color(1.0, 0.92, 0.86, 0.55)
