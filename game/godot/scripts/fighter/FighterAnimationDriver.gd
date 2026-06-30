extends Node
class_name FighterAnimationDriver

@export var blend_speed: float = 12.0
@export var use_animation_player: bool = true
@export var animation_player_path: NodePath
@export var visual_rig_path: NodePath
@export var state_machine_path: NodePath
@export var animation_library: FighterAnimationLibrary

var animation_player: AnimationPlayer
var visual_rig: Node2D
var state_machine: FighterStateMachine
var local_time: float = 0.0
var current_animation: StringName = &"idle"

func _ready() -> void:
	animation_player = get_node_or_null(animation_player_path)
	visual_rig = get_node_or_null(visual_rig_path)
	state_machine = get_node_or_null(state_machine_path)
	if state_machine == null:
		state_machine = get_parent().get_node_or_null("FighterStateMachine")
	if animation_library == null:
		animation_library = FighterAnimationLibrary.new()

func _process(delta: float) -> void:
	if state_machine == null:
		return

	var next_animation := FighterAnimationState.from_state(state_machine.current_state)
	if next_animation != current_animation:
		current_animation = next_animation
		local_time = 0.0
	else:
		local_time += delta

	if use_animation_player and animation_player != null and animation_player.has_animation(current_animation):
		if animation_player.current_animation != current_animation:
			animation_player.play(current_animation)
		return

	if visual_rig != null and animation_library != null:
		var pose := animation_library.sample_pose(current_animation, local_time)
		visual_rig.apply_pose(pose, clampf(blend_speed * delta, 0.0, 1.0))
