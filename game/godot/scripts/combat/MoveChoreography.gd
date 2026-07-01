extends RefCounted
class_name MoveChoreography

## Aggregates JSON move catalog + legacy base moves. Every move includes hit_socket.

static func get_move(move_id: String, fighter_id: String = "") -> MoveFrameData:
	var from_catalog: Dictionary = {}
	if not fighter_id.is_empty():
		from_catalog = MoveCatalog.get_move(fighter_id, move_id)
	if from_catalog.is_empty():
		from_catalog = MoveCatalog.get_move_for_any(move_id)
	if not from_catalog.is_empty():
		return MoveFrameData.new(from_catalog)
	return MoveFrameData.new(_base_move(move_id))

static func get_choreography(move_id: String, fighter_id: String = "") -> MoveChoreographyData:
	var from_catalog: Dictionary = {}
	if not fighter_id.is_empty():
		from_catalog = MoveCatalog.get_move(fighter_id, move_id)
	if from_catalog.is_empty():
		from_catalog = MoveCatalog.get_move_for_any(move_id)
	if not from_catalog.is_empty():
		return MoveChoreographyData.new(from_catalog)
	return MoveChoreographyData.new(_base_move(move_id))

static func _base_move(move_id: String) -> Dictionary:
	return {
		"move_id": move_id,
		"animation_name": move_id,
		"startup": 4,
		"active": 3,
		"recovery": 10,
		"hit_socket": "right_fist",
		"hitbox_socket": "right_fist",
		"vfx_socket": "right_fist",
		"hurtbox_profile": "standard",
		"hitstop_frames": 4,
		"damage": 6.0,
		"base_knockback": 7.0,
		"knockback_growth": 0.12,
		"launch_angle_degrees": 35.0,
	}
