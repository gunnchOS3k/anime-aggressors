extends Resource
class_name FighterStats

@export var fighter_id: String = "ember-vale":
	set(value):
		fighter_id = value
		_apply_roster_data()

@export var display_name: String = "Ember Vale"
@export var element: String = "fire"
@export var size: Vector2 = Vector2.ONE
@export var movement_modifiers: Dictionary = {"run": 1.0, "dash": 1.0, "air": 1.0, "jump": 1.0}
@export var weight: float = 1.0
@export var damage_modifiers: Dictionary = {"dealt": 1.0, "taken": 1.0}
@export var aura_color: Color = Color.WHITE

func _init(initial_id: String = "ember-vale") -> void:
	fighter_id = initial_id
	_apply_roster_data()

func _apply_roster_data() -> void:
	var data := FighterRoster.get_fighter(fighter_id)
	if data.is_empty():
		data = FighterRoster.get_default_fighter()
		fighter_id = data.get("id", "ember-vale")

	display_name = data.get("name", display_name)
	element = data.get("element", element)
	size = data.get("size", size)
	movement_modifiers = data.get("movement_modifiers", movement_modifiers).duplicate(true)
	weight = data.get("weight", weight)
	damage_modifiers = data.get("damage_modifiers", damage_modifiers).duplicate(true)
	aura_color = data.get("aura_color", aura_color)

func get_movement_modifier(key: String, default_value: float = 1.0) -> float:
	return float(movement_modifiers.get(key, default_value))

func get_damage_modifier(key: String, default_value: float = 1.0) -> float:
	return float(damage_modifiers.get(key, default_value))
