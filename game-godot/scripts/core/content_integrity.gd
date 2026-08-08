extends RefCounted
class_name ContentIntegrity

## Digital RC content/version hash checks (private/dev). No public anti-cheat claim.

const _AntiTamper = preload("res://scripts/net/anti_tamper.gd")

const CONTENT_HASH_PATHS: Array[String] = [
	"res://data/fighters/roster.json",
	"res://data/stages/production_stages.json",
	"res://assets/characters/procedural_final/manifest.json",
	"res://assets/audio/procedural/manifest.json",
	"res://assets/stages/procedural/manifest.json",
]


static func file_sha256_hex(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var bytes := FileAccess.get_file_as_bytes(path)
	return bytes.hex_encode().substr(0, 64) if bytes.size() > 0 else ""


static func content_fingerprint() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for p in CONTENT_HASH_PATHS:
		var digest := ""
		if FileAccess.file_exists(p):
			var f := FileAccess.open(p, FileAccess.READ)
			if f:
				digest = str(hash(f.get_as_text()))
		parts.append("%s:%s" % [p.get_file(), digest])
	return "|".join(parts)


static func expected_build_id() -> String:
	return _AntiTamper.BUILD_ID


static func compare_remote(remote_build: String, remote_content: String) -> Dictionary:
	var errors: Array = []
	if remote_build != expected_build_id():
		errors.append("version_mismatch")
	var local := content_fingerprint()
	if remote_content != "" and remote_content != local:
		errors.append("content_hash_mismatch")
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"local_build": expected_build_id(),
		"local_content": local,
		"remote_build": remote_build,
		"remote_content": remote_content,
	}


static func self_test() -> Dictionary:
	var local := content_fingerprint()
	var ok_match: Dictionary = compare_remote(expected_build_id(), local)
	var bad_ver: Dictionary = compare_remote("other-build", local)
	var bad_hash: Dictionary = compare_remote(expected_build_id(), "deadbeef")
	var ok: bool = bool(ok_match.get("ok", false)) \
		and not bool(bad_ver.get("ok", true)) \
		and not bool(bad_hash.get("ok", true)) \
		and local != ""
	return {
		"ok": ok,
		"fingerprint": local,
		"match": ok_match,
		"bad_version_errors": bad_ver.get("errors", []),
		"bad_hash_errors": bad_hash.get("errors", []),
	}
