extends RefCounted

const Bank = preload("res://scripts/audio/procedural_audio_bank.gd")

static func play_event(fighter_id: String, event: String, host: Node) -> Dictionary:
	return Bank.play("res://assets/audio/collectible_v1/%s/%s.wav" % [fighter_id, event], host, -6.0)

static func impact_event(move: Dictionary) -> String:
	var id := str(move.get("move_id", ""))
	var tier := str(move.get("feedback", {}).get("tier", "light"))
	if id == "aura_burst" or tier == "super":
		return "super_impact"
	if str(move.get("input_command", "")).begins_with("special") or str(move.get("move_type", "")) == "projectile":
		return "special"
	return "heavy" if tier in ["heavy", "aura"] else "light"
