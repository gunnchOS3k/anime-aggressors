extends RefCounted

const Bank = preload("res://scripts/audio/procedural_audio_bank.gd")

static func play_event(fighter_id: String, event: String, host: Node) -> Dictionary:
	var original := Bank.play("res://assets/audio/collectible_v1/%s/%s.wav" % [fighter_id, event], host, -6.0)
	var layer_event: String = {"heavy":"heavy","super_impact":"signature","special":"projectile_impact"}.get(event,"")
	if not str(layer_event).is_empty():
		original["elemental_layer"] = preload("res://scripts/audio/elemental_performance.gd").one_shot(fighter_id,layer_event,host)
	return original

static func impact_event(move: Dictionary) -> String:
	var id := str(move.get("move_id", ""))
	var tier := str(move.get("feedback", {}).get("tier", "light"))
	if id == "aura_burst" or tier == "super":
		return "super_impact"
	if str(move.get("input_command", "")).begins_with("special") or str(move.get("move_type", "")) == "projectile":
		return "special"
	return "heavy" if tier in ["heavy", "aura"] else "light"
