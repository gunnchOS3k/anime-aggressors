extends RefCounted
class_name ReplayStore

## Input-log replay record + verify for private matches.

const _AntiTamper = preload("res://scripts/net/anti_tamper.gd")
const REPLAY_VERSION := 1
## One private-match record. write_json already stores JSON.stringify(record).
const DEFAULT_PATH := "user://aa_private_match_replay.json"


static func story_checkpoint_token(cursor: String, stocks: int, damage_percent: float) -> String:
	return "%s|%d|%.3f" % [cursor, stocks, damage_percent]


static func story_fields_from_checkpoint(checkpoint: Dictionary) -> Dictionary:
	## Stores the restored cursor with that fight's stocks and damage. It does not advance the route.
	var combat: Variant = checkpoint.get("combat", {})
	if not combat is Dictionary:
		combat = {}
	var stocks_v: Variant = combat.get("stocks", checkpoint.get("stocks", null))
	var damage_v: Variant = combat.get("damage_percent", checkpoint.get("damage_percent", null))
	if stocks_v is bool or damage_v is bool:
		return {}
	if not (stocks_v is int or stocks_v is float) or not (damage_v is int or damage_v is float):
		return {}
	if stocks_v is float and not is_equal_approx(float(stocks_v), floorf(float(stocks_v))):
		return {}
	if float(stocks_v) < 0.0 or float(damage_v) < 0.0:
		return {}
	return {
		"cursor": str(checkpoint.get("cursor", "")),
		"stocks": int(stocks_v),
		"damage_percent": float(damage_v),
	}


static func create_record(match_meta: Dictionary, frames: Array, story_checkpoint: Dictionary = {}) -> Dictionary:
	## frames: [{frame, p0:Dict, p1:Dict, checksum:String}]
	var rec := {
		"replay_version": REPLAY_VERSION,
		"build": _AntiTamper.BUILD_ID,
		"meta": match_meta.duplicate(true),
		"frames": frames.duplicate(true),
		"frame_count": frames.size(),
	}
	rec["integrity"] = _AntiTamper.hash_payload({
		"v": REPLAY_VERSION,
		"n": frames.size(),
		"seed": match_meta.get("seed", 0),
		"roster": str(match_meta.get("roster", [])),
	})
	var fields := story_fields_from_checkpoint(story_checkpoint)
	if not fields.is_empty():
		rec["story_checkpoint"] = fields
		rec["story_integrity"] = story_checkpoint_token(str(fields["cursor"]), int(fields["stocks"]), float(fields["damage_percent"]))
	return rec


static func verify_record(rec: Dictionary) -> Dictionary:
	var errors: Array = []
	if int(rec.get("replay_version", -1)) != REPLAY_VERSION:
		errors.append("bad_replay_version")
	if str(rec.get("build", "")) != _AntiTamper.BUILD_ID:
		errors.append("build_mismatch")
	var frames: Array = rec.get("frames", [])
	if frames.is_empty():
		errors.append("empty_frames")
	var expected: String = _AntiTamper.hash_payload({
		"v": REPLAY_VERSION,
		"n": frames.size(),
		"seed": rec.get("meta", {}).get("seed", 0),
		"roster": str(rec.get("meta", {}).get("roster", [])),
	})
	if str(rec.get("integrity", "")) != expected:
		errors.append("integrity_fail")
	if rec.has("story_checkpoint") or rec.has("story_integrity"):
		var story_v: Variant = rec.get("story_checkpoint", {})
		if typeof(story_v) != TYPE_DICTIONARY:
			errors.append("story_integrity_fail")
		else:
			var story: Dictionary = story_v
			var story_token := story_checkpoint_token(str(story.get("cursor", "")), int(story.get("stocks", -1)), float(story.get("damage_percent", -1.0)))
			if story_token != str(rec.get("story_integrity", "")):
				errors.append("story_integrity_fail")
	# Monotonic frames
	var prev := -1
	for f in frames:
		var fr: int = int(f.get("frame", -1))
		if fr <= prev:
			errors.append("non_monotonic")
			break
		prev = fr
	return {"ok": errors.is_empty(), "errors": errors, "frame_count": frames.size()}


static func replay_checksum_chain(rec: Dictionary) -> Dictionary:
	## Recompute checksums from stored inputs; compare to recorded.
	var frames: Array = rec.get("frames", [])
	var mismatches := 0
	var checked := 0
	for f in frames:
		var inputs: Array = [f.get("p0", {}), f.get("p1", {})]
		var parts: PackedStringArray = PackedStringArray()
		parts.append("f=%d" % int(f.get("frame", 0)))
		for i in range(inputs.size()):
			var b: Dictionary = inputs[i]
			var keys: Array = b.keys()
			keys.sort()
			for k in keys:
				parts.append("%d.%s=%s" % [i, str(k), str(b[k])])
		var recomputed: String = str(hash("|".join(parts)))
		checked += 1
		if str(f.get("checksum", "")) != "" and str(f.get("checksum")) != recomputed:
			mismatches += 1
	return {
		"ok": mismatches == 0 and checked > 0,
		"checked": checked,
		"mismatches": mismatches,
	}


static func write_json(rec: Dictionary, path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(rec, "\t"))
	f.close()
	return true


static func read_json(path: String) -> Dictionary:
	## Load the JSON write_json stored and check verify_record plus the frame checksum chain.
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {
			"ok": false,
			"error": "open_failed",
			"path": path,
			"record": {},
			"verify": {"ok": false, "errors": ["open_failed"]},
			"chain": {"ok": false, "checked": 0, "mismatches": 0},
		}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {
			"ok": false,
			"error": "not_record",
			"path": path,
			"record": {},
			"verify": {"ok": false, "errors": ["not_record"]},
			"chain": {"ok": false, "checked": 0, "mismatches": 0},
		}
	var rec: Dictionary = _restore_record_types(parsed)
	var verify: Dictionary = verify_record(rec)
	var chain: Dictionary = replay_checksum_chain(rec)
	return {
		"ok": bool(verify.get("ok", false)) and bool(chain.get("ok", false)),
		"path": path,
		"record": rec,
		"verify": verify,
		"chain": chain,
	}


static func _restore_record_types(rec: Dictionary) -> Dictionary:
	## JSON.parse_string returns numbers as floats. create_record hashed the integer seed.
	var out: Dictionary = rec.duplicate(true)
	out["replay_version"] = int(out.get("replay_version", -1))
	out["frame_count"] = int(out.get("frame_count", 0))
	var meta_v: Variant = out.get("meta", {})
	if typeof(meta_v) == TYPE_DICTIONARY:
		var meta: Dictionary = meta_v
		if meta.has("seed"):
			meta["seed"] = int(meta.get("seed", 0))
		out["meta"] = meta
	var frames_v: Variant = out.get("frames", [])
	if typeof(frames_v) == TYPE_ARRAY:
		var frames: Array = frames_v
		for item in frames:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			item["frame"] = int(item.get("frame", -1))
		out["frames"] = frames
	var story_saved: Variant = out.get("story_checkpoint", {})
	if typeof(story_saved) == TYPE_DICTIONARY and not (story_saved as Dictionary).is_empty():
		var story: Dictionary = story_saved
		story["stocks"] = int(story.get("stocks", -1))
		story["damage_percent"] = float(story.get("damage_percent", -1.0))
		story["cursor"] = str(story.get("cursor", ""))
		out["story_checkpoint"] = story
	return out


static func self_test() -> Dictionary:
	var frames: Array = []
	for i in range(12):
		frames.append({
			"frame": i,
			"p0": {"attack": i % 3 == 0},
			"p1": {"shield": i % 4 == 0},
			"checksum": "",
		})
	# Fill checksums using same scheme as replay_checksum_chain
	for f in frames:
		var inputs: Array = [f.get("p0", {}), f.get("p1", {})]
		var parts: PackedStringArray = PackedStringArray()
		parts.append("f=%d" % int(f.get("frame", 0)))
		for i in range(inputs.size()):
			var b: Dictionary = inputs[i]
			var keys: Array = b.keys()
			keys.sort()
			for k in keys:
				parts.append("%d.%s=%s" % [i, str(k), str(b[k])])
		f["checksum"] = str(hash("|".join(parts)))
	var rec := create_record({"seed": 9, "roster": ["ember-vale", "rook-ironside"], "stage": "skyline-arena"}, frames)
	var v := verify_record(rec)
	var chain := replay_checksum_chain(rec)
	var ok: bool = bool(v.get("ok", false)) and bool(chain.get("ok", false))
	return {"ok": ok, "verify": v, "chain": chain, "frame_count": frames.size()}
