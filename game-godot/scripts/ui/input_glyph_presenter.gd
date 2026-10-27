extends RefCounted
## Presentation only: resolve notation from the live InputMap. Never bind an
## action, grant a move or replace Fighter's input/cancel/form authority.

const DEVICE_TOUCH := "touch"
const DEVICE_GAMEPAD := "gamepad"
const DEVICE_KEYBOARD := "keyboard"

const CMD_GLYPHS := {
	"attack_neutral": {"dir": "", "btn": "ATK", "seq": ["ATK"]},
	"attack_forward": {"dir": "→", "btn": "ATK", "seq": ["→", "ATK"]},
	"attack_up": {"dir": "↑", "btn": "ATK", "seq": ["↑", "ATK"]},
	"attack_down": {"dir": "↓", "btn": "ATK", "seq": ["↓", "ATK"]},
	# Fighter resolves a full-strength grounded direction, not a double tap.
	"attack_dash": {"dir": "FULL →", "btn": "ATK", "seq": ["FULL →", "ATK"]},
	"special_neutral": {"dir": "", "btn": "SPC", "seq": ["SPC"]},
	"special_forward": {"dir": "→", "btn": "SPC", "seq": ["→", "SPC"]},
	"special_up": {"dir": "↑", "btn": "SPC", "seq": ["↑", "SPC"]},
	"special_down": {"dir": "↓", "btn": "SPC", "seq": ["↓", "SPC"]},
	"aerial_neutral": {"dir": "AIR", "btn": "ATK", "seq": ["AIR", "ATK"]},
	"aerial_forward": {"dir": "AIR→", "btn": "ATK", "seq": ["AIR", "→", "ATK"]},
	"aerial_back": {"dir": "AIR←", "btn": "ATK", "seq": ["AIR", "←", "ATK"]},
	"aerial_up": {"dir": "AIR↑", "btn": "ATK", "seq": ["AIR", "↑", "ATK"]},
	"aerial_down": {"dir": "AIR↓", "btn": "ATK", "seq": ["AIR", "↓", "ATK"]},
	"grab": {"dir": "", "btn": "GRB", "seq": ["GRB"]},
	# Grab acquires a target; a fresh Attack while holding it releases a throw.
	"throw_forward": {"dir": "TARGET HELD →", "btn": "ATK", "seq": ["TARGET HELD", "→", "ATK"]},
	"throw_back": {"dir": "TARGET HELD ←", "btn": "ATK", "seq": ["TARGET HELD", "←", "ATK"]},
	"throw_up": {"dir": "TARGET HELD ↑", "btn": "ATK", "seq": ["TARGET HELD", "↑", "ATK"]},
	"throw_down": {"dir": "TARGET HELD ↓", "btn": "ATK", "seq": ["TARGET HELD", "↓", "ATK"]},
	"shield": {"dir": "", "btn": "SHD", "seq": ["HOLD", "SHD"]},
	"dodge": {"dir": "", "btn": "DODGE", "seq": ["DODGE"]},
	"jump": {"dir": "", "btn": "JMP", "seq": ["JMP"]},
}
const TOKEN_ACTIONS := {"ATK":"attack", "SPC":"special", "GRB":"grab", "SHD":"shield", "DODGE":"dodge", "JMP":"jump"}
const TOUCH_LABELS := {"attack":"ATK●", "special":"SPC●", "grab":"GRB●", "shield":"SHD●", "dodge":"DODGE●", "jump":"JMP●"}


static func detect_device() -> String:
	if DisplayServer.is_touchscreen_available():
		return DEVICE_TOUCH
	if not Input.get_connected_joypads().is_empty():
		return DEVICE_GAMEPAD
	return DEVICE_KEYBOARD


static func glyphs_for_command(input_command: String, device: String = "", slot: int = 1) -> Dictionary:
	if device.is_empty(): device = detect_device()
	# Chords mirror the existing Fighter readers. They are not extra actions.
	if input_command in ["attack_heavy", "aura_charge", "aura_burst", "shield_special_attack"]:
		return _chord_glyphs(input_command, device, slot)
	# Runtime manifests use attack_air_*, while the presentation vocabulary uses
	# aerial_*. This aliases notation only; it never remaps gameplay input.
	var glyph_command := input_command
	if input_command.begins_with("attack_air_"):
		glyph_command = "aerial_" + input_command.trim_prefix("attack_air_")
	var base: Dictionary = CMD_GLYPHS.get(glyph_command, {
		"dir": "", "btn": input_command.to_upper(), "seq": [input_command],
	}).duplicate(true)
	var compact := _compact(base, device, slot)
	var advanced := _advanced(base, device, slot)
	if input_command == "attack_dash":
		advanced += " · grounded: full-strength forward + Attack"
	elif input_command.begins_with("throw_"):
		advanced += " · while actually holding a target, choose direction and press Attack"
	return {"device":device, "input_command":input_command, "compact":compact,
		"advanced":advanced, "tokens":base.get("seq", [])}


static func _chord_glyphs(command: String, device: String, slot: int) -> Dictionary:
	var attack := "[%s]" % action_label("attack", device, slot)
	var special := "[%s]" % action_label("special", device, slot)
	var shield := "[%s]" % action_label("shield", device, slot)
	var compact := ""
	var advanced := ""
	var tokens: Array = []
	match command:
		"attack_heavy":
			compact = "%s + %s · ground, aura <100%%" % [attack, special]
			advanced = "Press %s + %s together on the ground, below full aura. Release Shield." % [attack, special]
			tokens = ["ATK", "+", "SPC", "GROUND", "AURA<100%"]
		"aura_charge":
			compact = "HOLD %s + %s together" % [shield, special]
			advanced = "From an action-ready neutral state, press and hold %s + %s together to charge. Release the charge inputs before a fresh transform chord." % [shield, special]
			if device == DEVICE_TOUCH:
				# The existing dedicated touch control synthesizes these same actions.
				compact = "HOLD [AURA●] or " + compact
				advanced = "Hold [AURA●], or " + advanced
			tokens = ["HOLD", "SHD", "+", "SPC"]
		"aura_burst":
			compact = "%s @100%% aura" % attack
			advanced = "At full aura, press %s. Uses the existing burst rules; Party state keeps its own action ownership." % attack
			tokens = ["ATK", "AURA@100%"]
		"shield_special_attack":
			compact = "TAP %s + %s + %s together · Tier 3 (75+%%)" % [shield, special, attack]
			advanced = "At Tier 3 (at least 75 aura), from an action-ready neutral state, press %s + %s + %s together with fresh Special and Attack presses. Release the charge inputs before this chord. Existing form, action and mode eligibility still apply." % [shield, special, attack]
			tokens = ["HOLD", "SHD", "+", "FRESH SPC", "+", "FRESH ATK", "TIER3"]
	return {"device":device, "input_command":command, "compact":compact,
		"advanced":advanced, "tokens":tokens}


static func _compact(base: Dictionary, device: String, slot: int) -> String:
	var direction := str(base.get("dir", ""))
	var button := _token_label(str(base.get("btn", "")), device, slot)
	return "[%s]" % button if direction.is_empty() else "%s + [%s]" % [direction, button]


static func _advanced(base: Dictionary, device: String, slot: int) -> String:
	var parts := PackedStringArray()
	for value in base.get("seq", []):
		var token := str(value)
		parts.append("[%s]" % _token_label(token, device, slot) if TOKEN_ACTIONS.has(token) else token)
	return " ".join(parts)


static func _token_label(token: String, device: String, slot: int) -> String:
	return action_label(str(TOKEN_ACTIONS[token]), device, slot) if TOKEN_ACTIONS.has(token) else token


static func action_label(action: String, device: String, slot: int = 1) -> String:
	if device == DEVICE_TOUCH:
		return str(TOUCH_LABELS.get(action, action.to_upper()))
	var mapped := "p%d_%s" % [slot, action]
	var labels := PackedStringArray()
	if InputMap.has_action(mapped):
		for event in InputMap.action_get_events(mapped):
			var label := ""
			if device == DEVICE_GAMEPAD:
				if event is InputEventJoypadButton:
					label = _joy_button_label(event.button_index)
				elif event is InputEventJoypadMotion:
					if event.axis == JOY_AXIS_TRIGGER_LEFT: label = "LT/L2"
					elif event.axis == JOY_AXIS_TRIGGER_RIGHT: label = "RT/R2"
					else: label = "Axis %d %s" % [event.axis, "+" if event.axis_value > 0.0 else "−"]
			elif event is InputEventKey:
				var code: int = int(event.physical_keycode) if event.physical_keycode != 0 else int(event.keycode)
				if code > 0:
					label = OS.get_keycode_string(code)
					var modifiers := PackedStringArray()
					if event.ctrl_pressed: modifiers.append("Ctrl")
					if event.alt_pressed: modifiers.append("Alt")
					if event.shift_pressed: modifiers.append("Shift")
					if event.meta_pressed: modifiers.append("Meta")
					if not modifiers.is_empty(): label = "+".join(modifiers) + "+" + label
			if not label.is_empty() and not labels.has(label): labels.append(label)
	# Missing bindings are reported honestly rather than inventing a default key.
	return " / ".join(labels) if not labels.is_empty() else action.to_upper() + " (unbound)"


static func _joy_button_label(button: int) -> String:
	match button:
		JOY_BUTTON_A: return "A/✕"
		JOY_BUTTON_B: return "B/○"
		JOY_BUTTON_X: return "X/□"
		JOY_BUTTON_Y: return "Y/△"
		JOY_BUTTON_LEFT_SHOULDER: return "LB/L1"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB/R1"
		JOY_BUTTON_LEFT_STICK: return "L3"
		JOY_BUTTON_RIGHT_STICK: return "R3"
		JOY_BUTTON_BACK: return "Back"
		JOY_BUTTON_START: return "Start"
		JOY_BUTTON_GUIDE: return "Guide"
		JOY_BUTTON_DPAD_UP: return "D-pad ↑"
		JOY_BUTTON_DPAD_DOWN: return "D-pad ↓"
		JOY_BUTTON_DPAD_LEFT: return "D-pad ←"
		JOY_BUTTON_DPAD_RIGHT: return "D-pad →"
		_: return "Button %d" % button


static func enrich_entry(entry: Dictionary, device: String = "") -> Dictionary:
	var out := entry.duplicate(true)
	var command := str(out.get("input_command", ""))
	if command.is_empty():
		out["input_glyphs"] = {"device":device, "compact":"—", "advanced":"LAB / UNBOUND", "tokens":[]}
	else:
		out["input_glyphs"] = glyphs_for_command(command, device)
	return out
