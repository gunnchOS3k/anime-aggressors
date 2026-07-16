extends Resource
## Presentation-only identity. Combat stats stay in fighter JSON + GameState.
## Runtime consumers: title, select, battle model, HUD, results.

@export var fighter_id: String = ""
@export var display_name: String = ""
@export var personality_traits: PackedStringArray = PackedStringArray()
@export var combat_fantasy: String = ""
@export var posture_style: String = "balanced"
@export var movement_style: String = "sharp"
@export var selection_line: String = ""
@export var select_archetype: String = "Balanced"
@export var power_identity: String = "Aura"
@export var primary_color: Color = Color(1, 0.4, 0.2)
@export var accent_color: Color = Color(1, 0.8, 0.3)
@export var animation_speed_scale: float = 1.0
@export var idle_speed: float = 1.0
@export var run_speed: float = 1.0
@export var attack_speed: float = 1.0
@export var lean: float = 0.0
@export var aura_shape: String = "orb"
@export var aura_pulse: float = 1.0
@export var expression_idle: String = "neutral"
@export var victory_pose: String = "proud_fist"
@export var defeat_pose: String = "kneel_guard"
@export var throw_style: String = "blast"
@export var silhouette_kind: String = "athlete" ## gauntlet|tank|spark|wind|frost|orbit|cloak


static func from_life_dict(fighter_id: String, life: Dictionary, fighter_data: Dictionary = {}) -> Resource:
	var p = new()
	p.fighter_id = fighter_id
	p.display_name = str(life.get("display", fighter_data.get("displayName", fighter_id)))
	var traits: PackedStringArray = PackedStringArray()
	for t in life.get("personality", []):
		traits.append(str(t))
	p.personality_traits = traits
	p.combat_fantasy = str(life.get("fantasy", ""))
	p.selection_line = str(life.get("line", "Ready."))
	p.select_archetype = str(life.get("select_archetype", "Balanced"))
	p.power_identity = str(life.get("power_id", "Aura"))
	p.idle_speed = float(life.get("idle_speed", 1.0))
	p.run_speed = float(life.get("run_speed", 1.0))
	p.attack_speed = float(life.get("attack_speed", 1.0))
	p.animation_speed_scale = p.idle_speed
	p.lean = float(life.get("lean", 0.0))
	p.aura_shape = str(life.get("aura_shape", "orb"))
	p.aura_pulse = float(life.get("aura_pulse", 1.0))
	p.expression_idle = str(life.get("expression_idle", "neutral"))
	p.victory_pose = str(life.get("victory_pose", "proud_fist"))
	p.defeat_pose = str(life.get("defeat_pose", "kneel_guard"))
	p.throw_style = str(life.get("throw_style", "blast"))
	if fighter_data.has("color"):
		p.primary_color = Color(fighter_data.get("color"))
	if fighter_data.has("auraColor"):
		p.accent_color = Color(fighter_data.get("auraColor"))
	p.silhouette_kind = _kind_for(fighter_id)
	p.posture_style = _posture_for(fighter_id)
	p.movement_style = str(life.get("movement", life.get("rhythm", "sharp")))
	return p


static func _kind_for(fighter_id: String) -> String:
	match fighter_id:
		"ember-vale":
			return "gauntlet"
		"rook-ironside":
			return "tank"
		"juno-spark":
			return "spark"
		"kaia-windrow":
			return "wind"
		"nix-calder":
			return "frost"
		"orion-vell":
			return "orbit"
		"vesper-nyx":
			return "cloak"
		_:
			return "athlete"


static func _posture_for(fighter_id: String) -> String:
	match fighter_id:
		"ember-vale":
			return "forward"
		"rook-ironside":
			return "grounded"
		"juno-spark":
			return "asymmetric"
		"kaia-windrow":
			return "elevated"
		"nix-calder":
			return "upright"
		"orion-vell":
			return "composed"
		"vesper-nyx":
			return "deceptive"
		_:
			return "balanced"
