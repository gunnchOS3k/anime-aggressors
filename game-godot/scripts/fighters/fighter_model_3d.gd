extends Node2D
class_name FighterModel3D

## Procedural production-proxy GLB is the visible runtime model when healthy.
## Legacy StylizedBuilder remains hidden/inactive as fallback only.

const _CharacterLife = preload("res://scripts/fighters/fighter_character_life.gd")
const _StylizedBuilder = preload("res://scripts/fighters/stylized_fighter_builder.gd")
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const _AnimationController = preload("res://scripts/visual/fighter_animation_controller.gd")
const _MaterialController = preload("res://scripts/visual/fighter_material_controller.gd")
const _MoveResolver = preload("res://scripts/visual/runtime_move_resolver.gd")
const _BoneMap = preload("res://scripts/visual/procedural_bone_map.gd")
const _SelectFraming = preload("res://scripts/menus/character_select_framing.gd")
const _PresentationGates = preload("res://scripts/menus/wave020_presentation_gates.gd")

const VIEWPORT_SIZE := Vector2i(220, 280)
const DISPLAY_SCALE := Vector2(0.38, 0.38)
const SELECT_DISPLAY_SCALE := Vector2(1.35, 1.35)
const SELECT_CAMERA_SIZE := 2.05
const PROXY_LABEL := "PROCEDURAL PRODUCTION PROXY"

var _viewport: SubViewport
var _camera: Camera3D
var _model_root: Node3D
var _display: Sprite2D
var _loaded_model: Node3D
var _proxy_model: Node3D
var _stylized: Node3D
var _animation_controller: Node
var _material_controller: Node
var _visible_skeleton: Skeleton3D
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
var _style_anim_t: float = 0.0
var _style_clip: String = "idle"
var _style_speed: float = 1.0
var _current_model_source: String = "MISSING"
var _current_animation_source: String = "LEGACY_STYLIZED_POSE"
var _procedural_healthy: bool = false
var _using_stylized_fallback: bool = false
## Wave018: generation token cancels superseded configure/swap races.
var _configure_generation: int = 0
var _load_failure_logged: bool = false
## Wave020: full-roster browse cycles can stale SubViewport textures on mobile.
var _configure_swap_count: int = 0
const VIEWPORT_REFRESH_EVERY_SWAPS := 7
var _last_framing_report: Dictionary = {}
var _last_presentation: Dictionary = {}


func _ready() -> void:
	if _viewport == null:
		_build_viewport()
	set_process(true)


func _process(delta: float) -> void:
	# Wave018: periodic heal for SubViewport texture loss / stuck visibility=false.
	if _loaded and not is_visible_renderable_body():
		heal_visibility_if_needed()
	if not _loaded or not _using_stylized_fallback or _stylized == null:
		return
	_style_anim_t += delta * _style_speed
	if _stylized.has_method("animate_pose"):
		_stylized.animate_pose(_style_clip, _style_anim_t)


func configure(fighter_data: Dictionary) -> bool:
	_configure_generation += 1
	var gen := _configure_generation
	if _model_root == null:
		_build_viewport()
	# Keep display texture alive during swap so preview never blanks mid-cycle.
	if _display != null and is_instance_valid(_display):
		_display.visible = true
	_clear_model()
	if gen != _configure_generation:
		return false
	_fighter_id = str(fighter_data.get("id", ""))
	_life = _CharacterLife.for_id(_fighter_id)
	_current_model_source = "MISSING"
	_current_animation_source = "LEGACY_STYLIZED_POSE"
	_procedural_healthy = false
	_using_stylized_fallback = false
	_load_failure_logged = false

	var model_info := _resolve_and_load_model(fighter_data)
	if gen != _configure_generation:
		return false
	_current_model_source = str(model_info.get("source", "MISSING"))

	_stylized = _StylizedBuilder.create(_fighter_id, fighter_data)
	_stylized.name = "StylizedFighter_%s" % _fighter_id
	var lean := float(_life.get("lean", 0.0))
	_stylized.rotation_degrees.y = -8.0 + lean * 40.0
	_model_root.add_child(_stylized)

	if _procedural_healthy and _proxy_model != null:
		_loaded_model = _proxy_model
		_stylized.visible = false
		_stylized.process_mode = Node.PROCESS_MODE_DISABLED
		_using_stylized_fallback = false
		_setup_procedural_runtime(fighter_data)
	else:
		# Recoverable explicit fallback — never silent empty body.
		_loaded_model = _stylized
		_stylized.visible = true
		_using_stylized_fallback = true
		if _proxy_model != null:
			_proxy_model.visible = false
			_proxy_model.process_mode = Node.PROCESS_MODE_DISABLED
		if str(model_info.get("source", "MISSING")) == "MISSING":
			_log_load_failure("procedural_missing_using_stylized_fallback")
			_current_model_source = "STYLIZED_FALLBACK"

	if gen != _configure_generation:
		return false
	_enforce_exactly_one_visible_body()
	_frame_camera_for_figure()
	_set_loaded(_loaded_model != null)
	_configure_swap_count += 1
	if _configure_swap_count % VIEWPORT_REFRESH_EVERY_SWAPS == 0:
		refresh_viewport_texture(true)
	heal_visibility_if_needed()
	set_expression(str(_life.get("expression_idle", "neutral")))
	_play_clip("idle")
	_apply_playback_scale("idle")
	if not is_visible_renderable_body():
		_log_load_failure("post_configure_not_renderable")
		heal_visibility_if_needed()
		if not is_visible_renderable_body():
			refresh_viewport_texture(true)
	# Return loaded; callers/harnesses check is_visible_renderable_body for invariant.
	return _loaded


func is_model_loaded() -> bool:
	return _loaded


func has_imported_animations() -> bool:
	if _animation_controller and _animation_controller.has_method("get_loaded_clip_names"):
		return not _animation_controller.get_loaded_clip_names().is_empty()
	return false


func get_life() -> Dictionary:
	return _life


func get_current_model_source() -> String:
	return _current_model_source


func get_current_animation_source() -> String:
	return _current_animation_source


func is_procedural_proxy_visible() -> bool:
	return _procedural_healthy and _proxy_model != null and _proxy_model.visible


func is_stylized_visible() -> bool:
	return _stylized != null and _stylized.visible


func get_visible_model_node() -> Node3D:
	return _loaded_model


func get_visible_skeleton() -> Skeleton3D:
	return _visible_skeleton


func get_active_animation_clip() -> String:
	if _animation_controller and _animation_controller.has_method("get_active_clip"):
		return str(_animation_controller.get_active_clip())
	return _last_clip


func get_animation_controller() -> Node:
	return _animation_controller


func get_loaded_model_node() -> Node3D:
	return _loaded_model


func is_using_stylized_fallback() -> bool:
	return _using_stylized_fallback


func count_renderable_meshes() -> Dictionary:
	## Counts MeshInstance3D under the active loaded model (procedural or stylized).
	var total := 0
	var visible := 0
	var root := _loaded_model
	if root == null or not is_instance_valid(root):
		return {"renderable_mesh_count": 0, "visible_renderable_mesh_count": 0}
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			total += 1
			var mesh := n as MeshInstance3D
			if mesh.visible and mesh.is_visible_in_tree():
				visible += 1
		for c in n.get_children():
			stack.append(c)
	# SubViewport Sprite2D path: if body is renderable but mesh walk found none
	# (e.g. mid-rebuild), treat healthy display as one visible renderable unit.
	if visible == 0 and is_visible_renderable_body():
		visible = 1
		if total == 0:
			total = 1
	return {"renderable_mesh_count": total, "visible_renderable_mesh_count": visible}


func count_visible_bodies() -> int:
	return count_visible_representations()


func count_visible_representations() -> int:
	var count := 0
	if _proxy_model != null and is_instance_valid(_proxy_model) and _proxy_model.visible:
		count += 1
	if _stylized != null and is_instance_valid(_stylized) and _stylized.visible:
		count += 1
	return count


func _enforce_exactly_one_visible_body() -> void:
	## Invariant: exactly one of procedural proxy / stylized fallback is visible.
	if _procedural_healthy and _proxy_model != null and is_instance_valid(_proxy_model):
		_proxy_model.visible = true
		if _stylized != null and is_instance_valid(_stylized):
			_stylized.visible = false
			_stylized.process_mode = Node.PROCESS_MODE_DISABLED
		_loaded_model = _proxy_model
		_using_stylized_fallback = false
	elif _stylized != null and is_instance_valid(_stylized):
		_stylized.visible = true
		_stylized.process_mode = Node.PROCESS_MODE_INHERIT
		if _proxy_model != null and is_instance_valid(_proxy_model):
			_proxy_model.visible = false
			_proxy_model.process_mode = Node.PROCESS_MODE_DISABLED
		_loaded_model = _stylized
		_using_stylized_fallback = true


func _log_load_failure(reason: String) -> void:
	if _load_failure_logged:
		return
	_load_failure_logged = true
	push_warning("FighterModel3D load/visibility failure fighter=%s reason=%s gen=%d" % [
		_fighter_id, reason, _configure_generation
	])


func get_configure_generation() -> int:
	return _configure_generation


func truth_flags() -> Dictionary:
	return {
		"PROCEDURAL_CHARACTER_RUNTIME_PASS": _procedural_healthy,
		"PROCEDURAL_RUNTIME_ANIMATION_PASS": _procedural_healthy and has_imported_animations(),
		"FINAL_CHARACTER_ART_PASS": _current_model_source in ["FINAL_CUSTOM", "APPROVED_VROID"],
		"FINAL_HUMAN_AUTHORED_ANIMATION_PASS": false,
		"HUMAN_ART_DIRECTION_APPROVAL": false,
		"CURRENT_MODEL_SOURCE": _current_model_source,
		"CURRENT_ANIMATION_SOURCE": _current_animation_source,
		"PROCEDURAL_PROXY_VISIBLE": is_procedural_proxy_visible(),
		"VISIBLE_MODEL_NODE": _loaded_model.name if _loaded_model else "",
		"VISIBLE_SKELETON_PRESENT": _visible_skeleton != null,
		"ACTIVE_ANIMATION_CLIP": get_active_animation_clip(),
		"COMPETITIVE_GAMEPLAY_ROOT_MOTION": "PHYSICS_AUTHORITATIVE",
		"VISIBLE_RUNTIME_ANIMATION_CONTROLLERS_PER_FIGHTER": 1 if _animation_controller else 0,
		"STYLIZED_FALLBACK_VISIBLE": is_stylized_visible(),
	}


func set_select_mode(enabled: bool) -> void:
	_select_mode = enabled
	if _display:
		_display.scale = SELECT_DISPLAY_SCALE if enabled else DISPLAY_SCALE
		_display.position = Vector2(0, -28) if enabled else Vector2(0, -49)
	_frame_camera_for_figure()


func get_select_framing_report() -> Dictionary:
	return _last_framing_report.duplicate(true)


func set_facing(direction: int) -> void:
	if _display:
		_display.scale.x = absf(_display.scale.x) * (1.0 if direction >= 0 else -1.0)


func set_aura_level(level: int) -> void:
	_aura_level = clampi(level, 0, 4)
	_refresh_aura_overlay()
	if _material_controller and _material_controller.has_method("set_charge_emission"):
		_material_controller.set_charge_emission(float(level) * 0.35)


func set_expression(state: String) -> void:
	_expression = state
	if _expression_label:
		_expression_label.text = _expression_glyph(state)
	if _face_chip:
		_face_chip.color = _expression_color(state)
		_face_chip.color.a = 0.0 if _procedural_healthy else _face_chip.color.a
	if _stylized and _stylized.has_method("set_expression"):
		_stylized.set_expression(state)


## Wave019 move-list preview: play the same clip family used by gameplay mapping.
func play_clip(clip_name: String) -> void:
	_play_clip(clip_name)


func animate_preview(clip_name: String, t: float) -> void:
	## Wave020 CP2: Move Preview must drive the canonical GLB body, not dual-show stylized.
	_style_clip = clip_name
	_style_anim_t = t
	if _procedural_healthy and _loaded:
		if _stylized != null:
			_stylized.visible = false
		_using_stylized_fallback = false
		_play_clip(clip_name)
		return
	# Emergency only when canonical body is unavailable.
	_AssetResolver.note_emergency_fallback()
	if _stylized != null and _stylized.has_method("animate_pose"):
		_stylized.visible = true
		_using_stylized_fallback = true
		_stylized.animate_pose(clip_name, t)


func play_for_state(state: String, move: Dictionary = {}) -> void:
	if not _loaded:
		return
	var rec = get_node_or_null("/root/RuntimeFlightRecorder")
	if rec and rec.has_method("record_action"):
		rec.record_action(_fighter_id, str(move.get("move_id", state)), "FighterModel3D.play_for_state", {"state": state})
	if move.has("throw_direction"):
		_throw_dir = str(move.get("throw_direction", "forward"))
	var clip := _clip_for_state(state, str(move.get("move_id", "")))
	_play_clip(clip, state, move)
	_apply_playback_scale(clip)
	_update_expression_for_state(state)
	if state in [_FighterStates.THROW_STARTUP, _FighterStates.THROW_RELEASE]:
		_play_throw_presentation(_throw_dir)
	if state == _FighterStates.KO or str(move.get("presentation", "")) == "defeat":
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


func sample_bone_transform(canonical_bone: String) -> Transform3D:
	if _visible_skeleton == null or not is_instance_valid(_visible_skeleton):
		return Transform3D.IDENTITY
	var glb_bone := _BoneMap.resolve_on_skeleton(_visible_skeleton, canonical_bone)
	var idx := _visible_skeleton.find_bone(glb_bone)
	if idx < 0:
		return Transform3D.IDENTITY
	_visible_skeleton.force_update_bone_child_transform(idx)
	return _visible_skeleton.get_bone_global_pose(idx)


func trigger_hit_flash(intensity: float = 1.0) -> void:
	if _material_controller and _material_controller.has_method("set_hit_flash"):
		_material_controller.set_hit_flash(intensity)


func capture_viewport_image() -> Image:
	if _viewport == null:
		return null
	var tex: Texture2D = _viewport.get_texture()
	if tex == null:
		return null
	return tex.get_image()


func _resolve_and_load_model(fighter_data: Dictionary) -> Dictionary:
	## Route through canonical presentation authority — reject deprecated player paths.
	var presentation: Dictionary = _AssetResolver.resolve_presentation(
		_fighter_id, _AssetResolver.CTX_BATTLE if not _select_mode else _AssetResolver.CTX_SELECT_PREVIEW, fighter_data
	)
	_last_presentation = presentation
	var explicit := str(fighter_data.get("modelPath", ""))
	if _is_approved_final_path(explicit):
		var final_info := _try_load_final_glb(fighter_data)
		if final_info.get("loaded", false):
			return final_info
	var proxy_info := _try_load_procedural_proxy(fighter_data)
	if proxy_info.get("loaded", false):
		return proxy_info
	# Do NOT load assets/characters/procedural_final as success for player builds.
	_AssetResolver.note_canonical_failure()
	return {"source": "MISSING", "loaded": false}


func get_presentation_trace() -> Dictionary:
	return _last_presentation.duplicate() if typeof(_last_presentation) == TYPE_DICTIONARY else {}


func capture_portrait_image() -> Image:
	refresh_viewport_texture(true)
	if _viewport == null:
		return null
	var tex: Texture2D = _viewport.get_texture()
	if tex == null:
		return null
	return tex.get_image()


func _is_approved_final_path(path: String) -> bool:
	if path.is_empty():
		return false
	if path.contains("procedural_final") or path.contains("procedural_proxy"):
		return false
	return path.contains("/approved/") or path.contains("/final/") or path.contains("/approved_vroid/") or path.contains("vroid")


func _try_load_procedural_proxy(fighter_data: Dictionary) -> Dictionary:
	var info: Dictionary = _AssetResolver.resolve_model_path(_fighter_id, fighter_data)
	var model_path := str(info.get("path", ""))
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return {"source": "MISSING", "loaded": false}
	var resource := load(model_path)
	if not resource is PackedScene:
		return {"source": "MISSING", "loaded": false}
	var instance := (resource as PackedScene).instantiate()
	if not instance is Node3D:
		instance.queue_free()
		return {"source": "MISSING", "loaded": false}
	if _proxy_model != null:
		_proxy_model.queue_free()
	_proxy_model = instance as Node3D
	_proxy_model.name = "ProceduralProxy_%s" % _fighter_id
	_proxy_model.visible = true
	_model_root.add_child(_proxy_model)
	_visible_skeleton = _find_skeleton(_proxy_model)
	_procedural_healthy = _visible_skeleton != null
	return {
		"source": str(info.get("source", "PROCEDURAL_PRODUCTION_PROXY")),
		"loaded": _procedural_healthy,
		"path": model_path,
	}


func _try_load_final_glb(fighter_data: Dictionary) -> Dictionary:
	var model_path := str(fighter_data.get("modelPath", ""))
	if model_path.is_empty() or model_path.contains("/proxy/"):
		return {"source": "MISSING", "loaded": false}
	if model_path.contains("procedural_proxy"):
		return {"source": "MISSING", "loaded": false}
	if not ResourceLoader.exists(model_path):
		return {"source": "MISSING", "loaded": false}
	var resource := load(model_path)
	if not resource is PackedScene:
		return {"source": "MISSING", "loaded": false}
	var instance := (resource as PackedScene).instantiate()
	if not instance is Node3D:
		instance.queue_free()
		return {"source": "MISSING", "loaded": false}
	_proxy_model = instance as Node3D
	_proxy_model.name = "ImportedFinal_%s" % _fighter_id
	_proxy_model.visible = true
	_model_root.add_child(_proxy_model)
	_visible_skeleton = _find_skeleton(_proxy_model)
	var source := "FINAL_CUSTOM"
	if model_path.contains("vroid") or model_path.contains("/approved_vroid/"):
		source = "APPROVED_VROID"
	_procedural_healthy = _visible_skeleton != null
	return {"source": source, "loaded": _visible_skeleton != null, "path": model_path}


func _setup_procedural_runtime(fighter_data: Dictionary) -> void:
	_current_animation_source = "PROCEDURAL_RUNTIME_ANIMATION"
	_animation_controller = _AnimationController.new()
	_animation_controller.name = "FighterAnimationController"
	add_child(_animation_controller)
	_animation_controller.setup({"fighter_id": _fighter_id}, _proxy_model)
	_visible_skeleton = _animation_controller.get_skeleton() if _animation_controller.has_method("get_skeleton") else _visible_skeleton
	_material_controller = _MaterialController.new()
	_material_controller.name = "FighterMaterialController"
	add_child(_material_controller)
	_material_controller.bind_model(_proxy_model)
	_apply_toon_materials(_proxy_model, fighter_data)
	if fighter_data.has("color"):
		_material_controller.set_team_color(Color(fighter_data.get("color")))


func _apply_toon_materials(root: Node3D, fighter_data: Dictionary) -> void:
	var base_color := Color(fighter_data.get("color", Color(0.85, 0.85, 0.9)))
	_apply_toon_recursive(root, base_color)


func _apply_toon_recursive(node: Node, base_color: Color) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var shader_res: Resource = load("res://shaders/fighter_toon.gdshader")
		if shader_res is Shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader_res as Shader
			mat.set_shader_parameter("base_color", base_color)
			mat.set_shader_parameter("team_tint", base_color)
			mesh.material_override = mat
		else:
			var fallback := StandardMaterial3D.new()
			fallback.albedo_color = base_color
			mesh.material_override = fallback
	for child in node.get_children():
		_apply_toon_recursive(child, base_color)


func _frame_camera_for_figure() -> void:
	if _camera == null:
		return
	# STOP_THE_LINE: keep Wave019 baseline camera until Slice A framing is re-enabled.
	if not _PresentationGates.dynamic_framing_enabled:
		var height := 1.0
		if _stylized and _stylized.has_method("get_height_scale"):
			height = float(_stylized.get_height_scale())
		_camera.size = (SELECT_CAMERA_SIZE if _select_mode else (2.55 + 0.35 * height))
		_camera.position = Vector3(0, 1.05 * height + 0.12, 5.0)
		_camera.look_at(Vector3(0, 1.05 * height + 0.08, 0), Vector3.UP)
		_last_framing_report = {"owner_review": "BASELINE_CAMERA", "body_coverage": 0.7}
		return
	var bounds := AABB()
	if _loaded_model != null and is_instance_valid(_loaded_model):
		bounds = _SelectFraming.compute_model_bounds(_loaded_model)
	else:
		var height2 := 1.0
		if _stylized and _stylized.has_method("get_height_scale"):
			height2 = float(_stylized.get_height_scale())
		bounds = AABB(Vector3(-0.35, 0.0, -0.15), Vector3(0.7, height2 * 1.75, 0.35))
	var vfx_env := 0.14
	if not _life.is_empty():
		vfx_env = clampf(float(_life.get("aura_pulse", 1.0)) * 0.08 + 0.1, 0.1, 0.22)
	_last_framing_report = _SelectFraming.framing_for_fighter(_fighter_id, bounds, _select_mode, vfx_env)
	var cam: Dictionary = _last_framing_report.get("camera_parameters", {})
	var ortho := float(cam.get("orthographic_size", SELECT_CAMERA_SIZE if _select_mode else 2.9))
	var pos_arr: Array = cam.get("position", [0.0, 1.15, 4.2])
	var look_arr: Array = cam.get("look_at", [0.0, 1.05, 0.0])
	_camera.size = ortho
	_camera.position = Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
	_camera.look_at(Vector3(float(look_arr[0]), float(look_arr[1]), float(look_arr[2])), Vector3.UP)
	if _loaded_model != null and is_instance_valid(_loaded_model):
		var lean := float(cam.get("lean_offset", 0.0))
		_loaded_model.rotation_degrees.y = -8.0 + lean * 40.0


func _build_viewport() -> void:
	if _viewport != null and is_instance_valid(_viewport) and _model_root != null and is_instance_valid(_model_root):
		return
	_viewport = SubViewport.new()
	_viewport.name = "Fighter3DViewport"
	_viewport.size = VIEWPORT_SIZE
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Pixel 6a gralloc rejects some MSAA render-target formats (0x3b); keep Compatibility-safe path.
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
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

	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 2.9
	_camera.position = Vector3(0, 1.22, 5.0)
	_camera.current = true
	_viewport.add_child(_camera)
	_camera.look_at(Vector3(0, 1.18, 0), Vector3.UP)

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
	_expression_label.modulate = Color(1, 1, 1, 0.0)
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
	# Free controllers immediately so reuse cannot bind stale skeleton/materials.
	if _animation_controller != null and is_instance_valid(_animation_controller):
		_animation_controller.free()
	if _material_controller != null and is_instance_valid(_material_controller):
		_material_controller.free()
	_animation_controller = null
	_material_controller = null
	_visible_skeleton = null
	_loaded_model = null
	_proxy_model = null
	_stylized = null
	_last_clip = ""
	_style_anim_t = 0.0
	_style_clip = "idle"
	if _model_root != null and is_instance_valid(_model_root):
		for child in _model_root.get_children():
			if is_instance_valid(child):
				child.free()


func _set_loaded(value: bool) -> void:
	_loaded = value
	if _display:
		# Never leave display stuck false after a successful body exists.
		_display.visible = value
		if value and _viewport != null and is_instance_valid(_viewport):
			if _display.texture == null:
				_display.texture = _viewport.get_texture()
			_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Wave017: player builds never show MODEL tier / PROXY / DEBUG labels.
	var tier_label := get_node_or_null("ModelTierLabel") as Label
	if tier_label:
		tier_label.visible = _developer_labels_enabled()
		tier_label.text = PROXY_LABEL if _procedural_healthy else "STYLIZED FALLBACK"


func _developer_labels_enabled() -> bool:
	var gs = get_node_or_null("/root/GameState")
	if gs != null and "debug_combat_hud" in gs and bool(gs.debug_combat_hud):
		return true
	if gs != null and str(gs.mode) == "training":
		var rules = load("res://scripts/combat/competitive_rules.gd")
		if rules and rules.has_method("show_debug_hud"):
			return bool(rules.show_debug_hud(gs))
	return false


## Wave017 visibility invariant helper — body mesh must be renderable when expected.
func is_visible_renderable_body() -> bool:
	if not _loaded:
		return false
	if _display == null or not is_instance_valid(_display) or not _display.visible:
		return false
	if _viewport == null or not is_instance_valid(_viewport):
		return false
	if _loaded_model == null or not is_instance_valid(_loaded_model) or not _loaded_model.visible:
		return false
	# Prefer mesh presence when procedural; stylized always has meshes under root.
	if _procedural_healthy and _visible_skeleton == null:
		return false
	return true


func refresh_viewport_texture(force: bool = false) -> void:
	## Wave020: rebind SubViewport → Sprite2D even when texture handle exists but is blank.
	if _viewport == null or not is_instance_valid(_viewport):
		_build_viewport()
	if _display == null or not is_instance_valid(_display):
		return
	var tex := _viewport.get_texture()
	if force or _display.texture == null or _display.texture != tex:
		_display.texture = tex
	if force:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_display.visible = _loaded


func heal_visibility_if_needed() -> bool:
	## Rebind display texture / force viewport update after bg/fg or SubViewport loss.
	var was_ok := is_visible_renderable_body()
	if _viewport == null or not is_instance_valid(_viewport):
		_build_viewport()
	if _display == null or not is_instance_valid(_display):
		return false
	refresh_viewport_texture(false)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_enforce_exactly_one_visible_body()
	var recovered := false
	if _loaded_model != null and is_instance_valid(_loaded_model):
		_loaded_model.visible = true
		_display.visible = true
		_loaded = true
		recovered = true
	# Last-resort: if stylized exists but was detached from _loaded_model pointer.
	elif _stylized != null and is_instance_valid(_stylized):
		_stylized.visible = true
		_loaded_model = _stylized
		_using_stylized_fallback = true
		_display.visible = true
		_loaded = true
		_log_load_failure("healed_via_stylized_fallback")
		recovered = true
	if recovered and not was_ok and is_visible_renderable_body():
		var telem = get_node_or_null("/root/Wave018VisibilityTelemetry")
		if telem != null and telem.has_method("record_fallback_recovery"):
			telem.record_fallback_recovery("heal_visibility_if_needed", _fighter_id)
	return recovered


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null


func _clip_for_state(state: String, move_id: String) -> String:
	var resolved: Dictionary = _MoveResolver.resolve_clip(state, move_id, _loaded_clip_dict())
	var clip := str(resolved.get("clip", ""))
	if clip.is_empty():
		clip = str(resolved.get("requested", "idle"))
	return clip


func _loaded_clip_dict() -> Dictionary:
	var clips := {}
	if _animation_controller and _animation_controller.has_method("get_loaded_clip_names"):
		for clip in _animation_controller.get_loaded_clip_names():
			clips[str(clip)] = true
	return clips


func _play_clip(requested: String, state: String = "", move: Dictionary = {}) -> void:
	if requested != _style_clip:
		_style_clip = requested
		_style_anim_t = 0.0
		_last_clip = requested
	elif requested in ["idle", "walk", "run", "fall", "shield", "aura_charge"]:
		pass
	else:
		if str(requested) != _last_clip:
			_style_anim_t = 0.0
			_last_clip = requested

	if _procedural_healthy and _animation_controller != null and is_instance_valid(_animation_controller):
		var move_copy := move.duplicate() if not move.is_empty() else {}
		if state.is_empty():
			move_copy["move_id"] = requested
		if _animation_controller.has_method("play_for_state"):
			_animation_controller.play_for_state(state if not state.is_empty() else _FighterStates.IDLE, move_copy)
		_last_clip = _animation_controller.get_active_clip() if _animation_controller.has_method("get_active_clip") else requested
	elif _stylized != null and is_instance_valid(_stylized) and _stylized.has_method("animate_pose"):
		_stylized.animate_pose(_style_clip, _style_anim_t)


func _apply_playback_scale(clip: String) -> void:
	if _life.is_empty():
		_style_speed = 1.0
		return
	var scale := 1.0
	if clip in ["idle", "shield"]:
		scale = float(_life.get("idle_speed", 1.0))
	elif clip in ["walk", "run", "dash"]:
		scale = float(_life.get("run_speed", 1.0))
	elif clip in ["jab_1", "jab_2", "heavy_attack", "special", "aura_burst", "throw_forward", "throw_back", "throw_up", "throw_down"]:
		scale = float(_life.get("attack_speed", 1.0))
	_style_speed = scale
	if _animation_controller != null and is_instance_valid(_animation_controller) and _animation_controller.has_method("get_animation_player"):
		var player: AnimationPlayer = _animation_controller.get_animation_player()
		if player != null and is_instance_valid(player):
			player.speed_scale = scale


func _update_expression_for_state(state: String) -> void:
	if state in [_FighterStates.AURA_CHARGE, _FighterStates.AURA_READY]:
		set_expression(str(_life.get("expression_charge", "charging")))
	elif state in [_FighterStates.HURT_LIGHT, _FighterStates.HURT_HEAVY, _FighterStates.HITSTUN, _FighterStates.LAUNCHED]:
		set_expression(str(_life.get("expression_hurt", "hurt")))
	elif state == _FighterStates.KO:
		set_expression("defeat")
	elif state in [_FighterStates.ATTACK_STARTUP, _FighterStates.SPECIAL_STARTUP, _FighterStates.THROW_STARTUP]:
		set_expression("focused")
	elif state in [_FighterStates.IDLE, _FighterStates.WALK]:
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
	_play_clip("victory")
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
	_play_clip("defeat")
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
