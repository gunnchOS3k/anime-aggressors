extends RefCounted
## Held control state, not move/damage authority. Owned by one ENet guest seat.
const BUTTONS := ["up", "down", "jump", "attack", "special", "shield", "grab", "dodge", "taunt"]
var buttons: Dictionary = {}
var horizontal := 0.0
var _pressed: Dictionary = {}

func clear() -> void:
	buttons.clear()
	_pressed.clear()
	horizontal = 0.0

func begin_frame() -> void:
	_pressed.clear()

func just_pressed(key: String) -> bool:
	return bool(_pressed.get(key, false))

func apply(packet: Dictionary) -> void:
	for key in BUTTONS:
		if bool(packet.buttons[key]) and not held(key): _pressed[key] = true
	buttons = packet.buttons.duplicate()
	horizontal = float(packet.axis)

func held(key: String) -> bool:
	return bool(buttons.get(key, false))

func axis() -> float:
	return horizontal

func release(key: String) -> void:
	buttons[key] = false
	_pressed.erase(key)

static func valid(packet: Dictionary) -> bool:
	if packet.size() != 5 or not packet.has_all(["kind", "epoch", "seq", "axis", "buttons"]): return false
	if packet.kind != "input" or typeof(packet.epoch) != TYPE_INT or typeof(packet.seq) != TYPE_INT: return false
	if packet.seq < 0 or packet.seq > 2147483647: return false
	if typeof(packet.axis) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(packet.axis)) or absf(float(packet.axis)) > 1.0: return false
	if typeof(packet.buttons) != TYPE_DICTIONARY or packet.buttons.size() != BUTTONS.size(): return false
	for key in BUTTONS:
		if not packet.buttons.has(key) or typeof(packet.buttons[key]) != TYPE_BOOL: return false
	return true

static func local_packet(epoch: int, seq: int) -> Dictionary:
	var state: Dictionary = {}
	for key in BUTTONS: state[key] = Input.is_action_pressed("p1_" + key)
	return {"kind":"input", "epoch":epoch, "seq":seq,
		"axis":Input.get_action_strength("p1_right") - Input.get_action_strength("p1_left"), "buttons":state}
