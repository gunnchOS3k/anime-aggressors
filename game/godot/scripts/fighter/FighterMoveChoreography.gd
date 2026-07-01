extends RefCounted
class_name FighterMoveChoreography

static func frame_data_for_attack(move_kind: String, fighter_id: String = "") -> MoveFrameData:
	return MoveChoreography.get_move(move_kind, fighter_id)

static func hit_socket_for_state(state: int, fighter_id: String = "") -> String:
	var move_id := "neutral_attack"
	match state:
		FighterStateMachine.State.ATTACK_ACTIVE:
			move_id = "neutral_attack"
		FighterStateMachine.State.SPECIAL_ACTIVE:
			move_id = "neutral_special"
		_:
			return "right_fist"
	var data := MoveChoreography.get_move(move_id, fighter_id)
	return String(data.hit_socket if data.hit_socket != "" else "right_fist")
