extends Node
class_name FighterAnimationTreeDriver

## Drives AnimationPlayer + AnimationTree state machine travel for combat locomotion.

@export var animation_player_path: NodePath
@export var state_machine_path: NodePath
@export var visual_rig_path: NodePath

var animation_player: AnimationPlayer
var state_machine: FighterStateMachine
var visual_rig: FighterRig3D
var animation_library: FighterAnimationLibrary
var tree_time: float = 0.0
var current_state_name: StringName = &"idle"

const TREE_STATES := [
	"idle", "walk", "run", "dash",
	"jump_start", "jump_rise", "double_jump", "fall", "fast_fall", "land",
	"neutral_attack_startup", "neutral_attack_active", "neutral_attack_recovery",
	"side_attack_startup", "side_attack_active", "side_attack_recovery",
	"up_attack_startup", "up_attack_active", "up_attack_recovery",
	"down_attack_startup", "down_attack_active", "down_attack_recovery",
	"neutral_special", "side_special", "up_special", "down_special",
	"aura_charge", "hitstun_light", "hitstun_heavy", "launch_tumble",
	"shield", "dodge", "grab", "throw", "victory", "defeat",
]

func _ready() -> void:
	animation_player = get_node_or_null(animation_player_path)
	state_machine = get_node_or_null(state_machine_path)
	visual_rig = get_node_or_null(visual_rig_path)
	animation_library = FighterAnimationLibrary.new()
	_ensure_animation_player_states()

func _process(delta: float) -> void:
	if state_machine == null or visual_rig == null:
		return
	var mapped := FighterAnimationState.from_state(state_machine.current_state)
	if mapped != current_state_name:
		current_state_name = mapped
		tree_time = 0.0
		if animation_player != null and animation_player.has_animation(current_state_name):
			animation_player.play(current_state_name)
	else:
		tree_time += delta
	var pose := animation_library.sample_pose(current_state_name, tree_time)
	visual_rig.apply_pose(pose, clampf(12.0 * delta, 0.0, 1.0))

func _ensure_animation_player_states() -> void:
	if animation_player == null:
		return
	for state_name in TREE_STATES:
		if animation_player.has_animation(state_name):
			continue
		var anim := Animation.new()
		anim.length = 0.35
		anim.loop_mode = Animation.LOOP_LINEAR if state_name in ["idle", "walk", "run", "aura_charge"] else Animation.LOOP_NONE
		animation_player.add_animation(state_name, anim)
