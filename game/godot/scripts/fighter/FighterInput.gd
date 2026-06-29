extends Node
class_name FighterInput

enum PlayerSlot { P1, P2 }

const ACTIONS := ["left", "right", "up", "jump", "attack", "special", "shield", "aura"]

const INPUT_LAYOUTS := {
	PlayerSlot.P1: {
		"left": [KEY_A],
		"right": [KEY_D],
		"up": [KEY_W],
		"jump": [KEY_W, KEY_SPACE],
		"attack": [KEY_J],
		"special": [KEY_K],
		"shield": [KEY_L],
		"aura": [KEY_F]
	},
	PlayerSlot.P2: {
		"left": [KEY_LEFT],
		"right": [KEY_RIGHT],
		"up": [KEY_UP],
		"jump": [KEY_UP, KEY_KP_8],
		"attack": [KEY_KP_1],
		"special": [KEY_KP_2],
		"shield": [KEY_KP_3],
		"aura": [KEY_KP_0]
	}
}

@export var player_slot: PlayerSlot = PlayerSlot.P1
@export var deadzone: float = 0.15

func _ready() -> void:
	_register_actions()

func _register_actions() -> void:
	var layout: Dictionary = INPUT_LAYOUTS.get(player_slot, {})
	for action_name in ACTIONS:
		var action := _action(action_name)
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, deadzone)
		for keycode in layout.get(action_name, []):
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			event.keycode = keycode
			InputMap.action_add_event(action, event)

func get_move_axis() -> float:
	return Input.get_action_strength(_action("right")) - Input.get_action_strength(_action("left"))

func is_jump_pressed() -> bool:
	return Input.is_action_pressed(_action("jump"))

func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed(_action("jump"))

func is_attack_just_pressed() -> bool:
	return Input.is_action_just_pressed(_action("attack"))

func is_special_just_pressed() -> bool:
	return Input.is_action_just_pressed(_action("special"))

func is_shield_pressed() -> bool:
	return Input.is_action_pressed(_action("shield"))

func is_aura_pressed() -> bool:
	return Input.is_action_pressed(_action("aura"))

func _action(base_action: String) -> StringName:
	return StringName("p%s_%s" % [player_slot + 1, base_action])
