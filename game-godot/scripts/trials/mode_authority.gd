extends RefCounted
class_name TrialsModeAuthority
## Shared mode-authority interface for Trials of Convergence.
## 60 Hz deterministic sims. Does not fork BattleScene fighter combat ownership.
## HUMAN_ART_APPROVED / RC2 / V1 / SHIPPING_ROLLBACK stay false.

const TICK_HZ := 60
const CATALOG_PATH := "res://data/trials/trials_catalog.json"

const JOURNEY_SELECT := "select"
const JOURNEY_SETUP := "setup"
const JOURNEY_PLAY := "play"
const JOURNEY_RESULTS := "results"
const JOURNEY_SAVE := "save"


static func load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		return {}
	var f = FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func mode_entry(mode_id: String) -> Dictionary:
	var cat: Dictionary = load_catalog()
	for m in cat.get("modes", []):
		if typeof(m) != TYPE_DICTIONARY:
			continue
		if str(m.get("id", "")) == mode_id:
			return m
		for legacy in m.get("legacy_ids", []):
			if str(legacy) == mode_id:
				return m
	return {}


static func all_mode_ids() -> Array:
	var out: Array = []
	for m in load_catalog().get("modes", []):
		if typeof(m) == TYPE_DICTIONARY:
			out.append(str(m.get("id", "")))
	return out


static func feeds_ranked_mmr(mode_id: String) -> bool:
	var e: Dictionary = mode_entry(mode_id)
	return bool(e.get("feeds_ranked_mmr", false))


static func player_count_truth(mode_id: String) -> Dictionary:
	var e: Dictionary = mode_entry(mode_id)
	var pc: Dictionary = e.get("player_counts", {})
	return {
		"min": int(pc.get("min", 1)),
		"max": int(pc.get("max", 1)),
		"honest_note": str(pc.get("honest_note", "")),
	}


static func shipping_flags_false() -> Dictionary:
	return {
		"HUMAN_ART_APPROVED": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
	}


static func empty_save_payload(mode_id: String, seed: int, result: Dictionary) -> Dictionary:
	## Local trial record only — never ranked MMR / never commercial claim.
	return {
		"mode_id": mode_id,
		"seed": seed,
		"tick_hz": TICK_HZ,
		"result": result,
		"feeds_ranked_mmr": false,
		"earned_story_progress": false,
		"shipping": shipping_flags_false(),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
	}


static func mulberry32(seed: int) -> Callable:
	## Deterministic PRNG — no Math.random / no OS entropy in sims.
	var state: Array = [seed & 0xFFFFFFFF]
	return func() -> float:
		state[0] = (int(state[0]) + 0x6D2B79F5) & 0xFFFFFFFF
		var t: int = int(state[0])
		t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF
		t = (t ^ (t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF))) & 0xFFFFFFFF
		return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0


static func hash_parts(seed: int, parts: Array) -> String:
	var h: int = seed
	for p in parts:
		var v: int = 0
		if typeof(p) == TYPE_STRING:
			for i in range(str(p).length()):
				v = (v * 31 + str(p).unicode_at(i)) & 0x7FFFFFFF
		elif typeof(p) == TYPE_FLOAT:
			v = int(round(float(p) * 1000.0))
		else:
			v = int(p)
		h = (h * 31 + v) & 0x7FFFFFFF
	return "%08x" % (h & 0xFFFFFFFF)
