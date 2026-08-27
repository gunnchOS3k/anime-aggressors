extends Control

const _PresentationContext = preload("res://scripts/visual/presentation_context.gd")

@onready var p1_label: Label = %P1Label
@onready var p2_label: Label = %P2Label
@onready var stage_label: Label = %StageLabel

func _ready() -> void:
	# Wave017: portraits + stage preview accents; unobtrusive CPU; no developer footer.
	var p1: Dictionary = GameState.load_fighter(GameState.p1_fighter_id)
	var p2: Dictionary = GameState.load_fighter(GameState.p2_fighter_id)
	var stage: Dictionary = GameState.load_stage(GameState.stage_id)
	_spawn_portrait(p1, true)
	_spawn_portrait(p2, false)
	if p1_label:
		p1_label.text = p1.get("displayName", "P1")
		p1_label.add_theme_color_override("font_color", Color(p1.get("color", Color(1, 0.45, 0.2))))
	if p2_label:
		var cpu_tag := ""
		if GameState.p2_is_cpu:
			cpu_tag = "  · CPU"
		p2_label.text = str(p2.get("displayName", "P2")) + cpu_tag
		p2_label.add_theme_color_override("font_color", Color(p2.get("color", Color(0.4, 0.65, 1.0))))
		p2_label.modulate.a = 0.9
	if stage_label:
		var stage_name: String = str(stage.get("displayName", GameState.stage_id))
		if GameState.arcade_active or GameState.mode == "arcade":
			stage_name = "Arcade %d/%d — %s" % [
				GameState.arcade_index + 1,
				GameState.ARCADE_LADDER.size(),
				stage_name,
			]
		stage_label.text = stage_name
	# Wave021 versus ceremony: staggered portrait entrance + element clash hold.
	modulate.a = 0.0
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(self, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	for child in get_children():
		if str(child.name).begins_with("Portrait_"):
			child.modulate.a = 0.0
			child.scale = Vector2(0.92, 0.92)
			var side := -1.0 if str(child.name).ends_with("P1") else 1.0
			fade.tween_property(child, "modulate:a", 1.0, 0.45).set_delay(0.12 if side < 0 else 0.22)
			fade.tween_property(child, "scale", Vector2.ONE, 0.5).set_delay(0.12 if side < 0 else 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await get_tree().create_timer(2.2).timeout
	SceneRouter.go("battle")


func _spawn_portrait(fighter_data: Dictionary, left: bool) -> void:
	var model_script = load("res://scripts/fighters/fighter_model_3d.gd")
	if model_script == null:
		return
	var portrait = model_script.new()
	portrait.name = "Portrait_%s" % ("P1" if left else "P2")
	add_child(portrait)
	portrait.position = Vector2(180 if left else 900, 320)
	if portrait.has_method("set_presentation_context"):
		portrait.set_presentation_context(_PresentationContext.CTX_VERSUS)
	elif portrait.has_method("set_select_mode"):
		portrait.set_select_mode(true)
	if portrait.has_method("configure"):
		portrait.configure(fighter_data)
	if portrait.has_method("set_select_mode") and not portrait.has_method("set_presentation_context"):
		portrait.set_select_mode(true)
	if portrait.has_method("play_lock_in"):
		portrait.play_lock_in()
