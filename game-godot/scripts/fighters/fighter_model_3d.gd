extends Node2D
class_name FighterModel3D

## Animated GLB presentation inside deterministic 2D combat. The transparent
## SubViewport keeps physics in CharacterBody2D while rendering a real 3D rig.

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


func _ready() -> void:
	_build_viewport()


func configure(fighter_data: Dictionary) -> bool:
	_clear_model()
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
	_loaded_model.name = "ImportedFighter_%s" % str(fighter_data.get("id", "unknown"))
	_loaded_model.rotation_degrees.y = -8.0
	_model_root.add_child(_loaded_model)
	_animation_player = _find_animation_player(_loaded_model)
	_set_loaded(true)
	_play_clip("idle")
	return true


func is_model_loaded() -> bool:
	return _loaded


func has_imported_animations() -> bool:
	return _animation_player != null and not _animation_player.get_animation_list().is_empty()


func set_facing(direction: int) -> void:
	if _display:
		_display.scale.x = absf(_display.scale.x) * (1.0 if direction >= 0 else -1.0)


func play_for_state(state: String, move: Dictionary = {}) -> void:
	if _loaded:
		_play_clip(_clip_for_state(state, str(move.get("move_id", ""))))


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
		tier_label.visible = value


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
		return
	var animation := _animation_player.get_animation(clip)
	if animation:
		var should_loop := requested in ["idle", "walk", "run", "fall", "shield", "aura_charge"]
		animation.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	_animation_player.play(clip, 0.08)
	_last_clip = str(clip)


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
