extends RefCounted
class_name FighterMoveChoreography

static func frame_data_for_attack(move_kind: String) -> MoveFrameData:
	return MoveChoreography.get_move(move_kind if MoveChoreography.MOVES.has(move_kind) else "neutral_attack")

static func hit_socket_for_state(state: int) -> String:
	match state:
		FighterStateMachine.State.ATTACK_ACTIVE:
			return "right_fist"
		FighterStateMachine.State.SPECIAL_ACTIVE:
			return "weapon_tip"
		_:
			return "right_fist"
