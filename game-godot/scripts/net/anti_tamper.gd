extends RefCounted
class_name AntiTamper

## Private-netplay anti-tamper validation (checksums, version, payload integrity).
## Loopback/private only — not a public anti-cheat product claim.

const _OnlineProtocol = preload("res://scripts/net/online_protocol.gd")

const BUILD_ID := "anime-digital-rc-private-1"
const TOKEN_HINT := "ANIME_DIGITAL_RC_READY"


static func build_fingerprint() -> String:
	return "%s|proto=%d|build=%s" % [BUILD_ID, _OnlineProtocol.PROTOCOL_VERSION, Engine.get_version_info().get("string", "godot")]


static func hash_payload(payload: Dictionary) -> String:
	## Stable deterministic hash over sorted keys (not crypto-grade; integrity check).
	var keys: Array = payload.keys()
	keys.sort()
	var parts: PackedStringArray = PackedStringArray()
	for k in keys:
		parts.append("%s=%s" % [str(k), str(payload[k])])
	return str(hash("|".join(parts)))


static func sign_envelope(msg: Dictionary) -> Dictionary:
	var out: Dictionary = msg.duplicate(true)
	var payload: Dictionary = out.get("payload", {})
	out["build"] = BUILD_ID
	out["proto"] = _OnlineProtocol.PROTOCOL_VERSION
	out["integrity"] = hash_payload(payload if typeof(payload) == TYPE_DICTIONARY else {})
	return out


static func validate_envelope(msg: Dictionary, expect_build: bool = true) -> Dictionary:
	var errors: Array = []
	var base: Dictionary = _OnlineProtocol.validate(msg)
	if not bool(base.get("ok", false)):
		for e in base.get("errors", []):
			errors.append(e)
	if expect_build:
		if str(msg.get("build", "")) != BUILD_ID:
			errors.append("build_mismatch")
		if int(msg.get("proto", -1)) != _OnlineProtocol.PROTOCOL_VERSION:
			errors.append("proto_mismatch")
	var payload: Dictionary = msg.get("payload", {})
	if typeof(payload) == TYPE_DICTIONARY and msg.has("integrity"):
		var expected: String = hash_payload(payload)
		if str(msg.get("integrity", "")) != expected:
			errors.append("integrity_fail")
	if str(msg.get("type", "")) == _OnlineProtocol.MSG_INPUT:
		var buttons = payload.get("buttons", {})
		if typeof(buttons) != TYPE_DICTIONARY:
			errors.append("buttons_type")
		else:
			for k in buttons.keys():
				var v = buttons[k]
				var t := typeof(v)
				if t != TYPE_BOOL and t != TYPE_INT and t != TYPE_FLOAT:
					errors.append("buttons_tamper_%s" % str(k))
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"build": BUILD_ID,
		"fingerprint": build_fingerprint(),
	}


static func version_compatible(remote_proto: int, remote_build: String) -> bool:
	if remote_proto != _OnlineProtocol.PROTOCOL_VERSION:
		return false
	return remote_build.begins_with("anime-digital-rc-private") or remote_build.begins_with("anime-alpha-private")


static func self_test() -> Dictionary:
	var good := sign_envelope(_OnlineProtocol.encode_input(3, 0, {"attack": true, "left": false}))
	var v_ok: Dictionary = validate_envelope(good)
	var bad := good.duplicate(true)
	bad["payload"] = {"frame": 3, "player_id": 0, "buttons": {"attack": true, "hack": "x"}}
	var v_bad: Dictionary = validate_envelope(bad)
	var compat: bool = version_compatible(_OnlineProtocol.PROTOCOL_VERSION, BUILD_ID)
	var incompat: bool = version_compatible(0, BUILD_ID) or version_compatible(_OnlineProtocol.PROTOCOL_VERSION, "other")
	var ok: bool = bool(v_ok.get("ok", false)) and not bool(v_bad.get("ok", true)) and compat and not incompat
	return {
		"ok": ok,
		"good": v_ok,
		"bad_errors": v_bad.get("errors", []),
		"fingerprint": build_fingerprint(),
		"token_hint": TOKEN_HINT,
	}
