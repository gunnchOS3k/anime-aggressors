extends RefCounted
## Reusable input glyph presentation for touch / gamepad / keyboard.

const DEVICE_TOUCH := "touch"
const DEVICE_GAMEPAD := "gamepad"
const DEVICE_KEYBOARD := "keyboard"

const CMD_GLYPHS := {
	"attack_neutral": {"dir": "", "btn": "ATK", "seq": ["ATK"]},
	"attack_forward": {"dir": "→", "btn": "ATK", "seq": ["→", "ATK"]},
	"attack_up": {"dir": "↑", "btn": "ATK", "seq": ["↑", "ATK"]},
	"attack_down": {"dir": "↓", "btn": "ATK", "seq": ["↓", "ATK"]},
	"attack_dash": {"dir": "→→", "btn": "ATK", "seq": ["→→", "ATK"]},
	"attack_heavy": {"dir": "", "btn": "HVY", "seq": ["HVY"]},
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
	"throw_forward": {"dir": "→", "btn": "GRB", "seq": ["GRB", "→"]},
	"throw_back": {"dir": "←", "btn": "GRB", "seq": ["GRB", "←"]},
	"throw_up": {"dir": "↑", "btn": "GRB", "seq": ["GRB", "↑"]},
	"throw_down": {"dir": "↓", "btn": "GRB", "seq": ["GRB", "↓"]},
	"aura_charge": {"dir": "", "btn": "AURA", "seq": ["HOLD AURA"]},
	"aura_burst": {"dir": "", "btn": "AURA", "seq": ["AURA@100%"]},
	"dodge": {"dir": "", "btn": "DODGE", "seq": ["DODGE"]},
	"jump": {"dir": "", "btn": "JMP", "seq": ["JMP"]},
}


static func detect_device() -> String:
	if DisplayServer.is_touchscreen_available():
		return DEVICE_TOUCH
	if not Input.get_connected_joypads().is_empty():
		return DEVICE_GAMEPAD
	return DEVICE_KEYBOARD


static func glyphs_for_command(input_command: String, device: String = "") -> Dictionary:
	if device.is_empty():
		device = detect_device()
	var base: Dictionary = CMD_GLYPHS.get(input_command, {
		"dir": "",
		"btn": input_command.to_upper(),
		"seq": [input_command],
	}).duplicate(true)
	var compact := _compact(base, device)
	var advanced := _advanced(base, device)
	return {
		"device": device,
		"input_command": input_command,
		"compact": compact,
		"advanced": advanced,
		"tokens": base.get("seq", []),
	}


static func _compact(base: Dictionary, device: String) -> String:
	var dir := str(base.get("dir", ""))
	var btn := _btn_label(str(base.get("btn", "")), device)
	if dir.is_empty():
		return "[%s]" % btn
	if dir.begins_with("AIR"):
		return "%s + [%s]" % [dir, btn]
	return "%s + [%s]" % [dir, btn]


static func _advanced(base: Dictionary, device: String) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for t in base.get("seq", []):
		var token := str(t)
		if token in ["ATK", "SPC", "HVY", "GRB", "AURA", "DODGE", "JMP", "HOLD AURA", "AURA@100%"]:
			parts.append("[%s]" % _btn_label(token, device))
		else:
			parts.append(token)
	return " ".join(parts)


static func _btn_label(btn: String, device: String) -> String:
	match device:
		DEVICE_TOUCH:
			match btn:
				"ATK":
					return "ATK●"
				"SPC":
					return "SPC●"
				"HVY":
					return "HVY●"
				"GRB":
					return "GRB●"
				"AURA", "HOLD AURA", "AURA@100%":
					return btn.replace("AURA", "AURA●")
				"DODGE":
					return "DODGE●"
				"JMP":
					return "JMP●"
				_:
					return btn
		DEVICE_GAMEPAD:
			match btn:
				"ATK":
					return "X/□"
				"SPC":
					return "Y/△"
				"HVY":
					return "RB"
				"GRB":
					return "LB"
				"AURA", "HOLD AURA", "AURA@100%":
					return "RT/" + btn
				"DODGE":
					return "B/○"
				"JMP":
					return "A/✕"
				_:
					return btn
		_:
			match btn:
				"ATK":
					return "J"
				"SPC":
					return "K"
				"HVY":
					return "L"
				"GRB":
					return ";"
				"AURA", "HOLD AURA", "AURA@100%":
					return "I/" + btn
				"DODGE":
					return "Shift"
				"JMP":
					return "W/Space"
				_:
					return btn


static func enrich_entry(entry: Dictionary, device: String = "") -> Dictionary:
	var out := entry.duplicate(true)
	var cmd := str(out.get("input_command", ""))
	if cmd.is_empty():
		out["input_glyphs"] = {"device": device, "compact": "—", "advanced": "LAB / UNBOUND", "tokens": []}
	else:
		out["input_glyphs"] = glyphs_for_command(cmd, device)
	return out
