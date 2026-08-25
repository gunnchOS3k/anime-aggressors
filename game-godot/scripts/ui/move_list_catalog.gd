extends RefCounted
## Canonical Move List / Command Guide catalog.
## Generated from gameplay move JSON + clip alias map + signature names.
## Never maintain a hand-written drift list of playable inputs.

const MOVE_DIR := "res://data/moves/"
const ALIAS_PATH := "res://data/runtime/move_clip_alias_map.json"
const SIG_NAMES_PATH := "res://data/runtime/signature_move_names.json"
const META_PATH := "res://data/runtime/move_list_meta.json"
const DISPLAY_PATH := "res://data/runtime/move_display_names.json"

## Signature lanes that exist as design/lab concepts but are NOT normal-match input-bound.
const LAB_SIGNATURE_LANES := [
	"signature_lane_control",
	"signature_lane_confirm",
	"signature_lane_launch",
	"signature_lane_counter",
	"signature_lane_finisher",
]

## Normal-match signature access (21 = 7 fighters × 3):
## aura_burst → burst, side_special → feint, down_special → trap
const PLAYABLE_SIGNATURE_PROXY := {
	"aura_burst": "signature_lane_burst",
	"side_special": "signature_lane_feint",
	"down_special": "signature_lane_trap",
}

const CATEGORY_ORDER := [
	"MOVEMENT",
	"NORMAL ATTACKS",
	"TILTS / DIRECTIONAL ATTACKS",
	"AERIALS",
	"HEAVY / SMASH ATTACKS",
	"SPECIALS",
	"AURA / CHARGE",
	"GRAB",
	"THROWS",
	"DEFENSE",
	"RECOVERY",
	"SIGNATURE TECHNIQUES",
	"CONTEXT / ADVANCED TECHNIQUES",
]


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func roster_ids() -> PackedStringArray:
	return PackedStringArray([
		"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
		"nix-calder", "orion-vell", "vesper-nyx",
	])


static func build_fighter_catalog(fighter_id: String) -> Dictionary:
	var moves_path := MOVE_DIR + fighter_id + ".json"
	var moves_doc := load_json(moves_path)
	var alias := load_json(ALIAS_PATH)
	var sig_names: Dictionary = load_json(SIG_NAMES_PATH).get(fighter_id, {})
	var meta_all := load_json(META_PATH)
	var meta: Dictionary = meta_all.get(fighter_id, {})
	var display_all := load_json(DISPLAY_PATH)
	var display_map: Dictionary = display_all.get(fighter_id, {})
	var clip_map: Dictionary = alias.get("move_id_to_clip", {})

	var entries: Array = []
	for raw in moves_doc.get("moves", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var move: Dictionary = raw
		var move_id := str(move.get("move_id", ""))
		if move_id.is_empty():
			continue
		var entry := _entry_from_move(fighter_id, move, clip_map, sig_names, display_map, meta)
		entries.append(entry)

	# Lab signatures: reference only, never playable in default list.
	for lane in LAB_SIGNATURE_LANES:
		var lab := {
			"fighter_id": fighter_id,
			"move_id": lane,
			"display_name": str(sig_names.get(lane, lane)),
			"input_command": "",
			"input_glyphs": {},
			"category": "CONTEXT / ADVANCED TECHNIQUES",
			"move_type": "signature_lab",
			"grounded_air": "both",
			"aura_requirement": "lab",
			"damage_role": "concept",
			"tactical_purpose": "Concept / lab technique — not currently bound to normal match input.",
			"playable": false,
			"reachability": "LAB_ONLY",
			"animation_clip": str(clip_map.get(lane, lane)),
			"signature_lane": lane,
			"startup_frames": null,
			"active_frames": null,
			"recovery_frames": null,
			"short_description": "CONCEPT / LAB TECHNIQUE — NOT CURRENTLY BOUND TO NORMAL MATCH INPUT",
			"is_core": false,
		}
		entries.append(lab)

	var categories: Dictionary = {}
	for e in entries:
		if not bool(e.get("playable", false)) and str(e.get("reachability", "")) != "LAB_ONLY":
			continue
		# Default player list excludes LAB_ONLY unless advanced reference requested.
		var cat := str(e.get("category", "SPECIALS"))
		if not categories.has(cat):
			categories[cat] = []
		(categories[cat] as Array).append(e)

	return {
		"fighter_id": fighter_id,
		"schema": "wave019_move_list_catalog_v1",
		"beginner": meta.get("beginner", {}),
		"core_move_ids": meta.get("core_moves", []),
		"entries": entries,
		"categories": categories,
		"playable_count": _count_playable(entries),
		"lab_count": LAB_SIGNATURE_LANES.size(),
	}


static func _count_playable(entries: Array) -> int:
	var n := 0
	for e in entries:
		if bool(e.get("playable", false)):
			n += 1
	return n


static func _entry_from_move(
	fighter_id: String,
	move: Dictionary,
	clip_map: Dictionary,
	sig_names: Dictionary,
	display_map: Dictionary,
	meta: Dictionary
) -> Dictionary:
	var move_id := str(move.get("move_id", ""))
	var input_command := str(move.get("input_command", ""))
	var clip := str(clip_map.get(move_id, move_id))
	var sig_lane := str(PLAYABLE_SIGNATURE_PROXY.get(move_id, ""))
	var display := str(display_map.get(move_id, ""))
	if display.is_empty() and not sig_lane.is_empty():
		display = str(sig_names.get(sig_lane, ""))
	if display.is_empty():
		display = str(move.get("training_display_name", move_id))
	var category := _category_for(move_id, move)
	var playable := true
	var reachability := "NORMAL_MATCH"
	var tactical := str(meta.get("move_tactics", {}).get(move_id, ""))
	if tactical.is_empty():
		tactical = _default_tactic(fighter_id, move_id, move)
	var short_desc := str(meta.get("move_descriptions", {}).get(move_id, ""))
	if short_desc.is_empty():
		short_desc = _default_description(fighter_id, move_id, display, move)
	var core_ids: Array = meta.get("core_moves", [])
	return {
		"fighter_id": fighter_id,
		"move_id": move_id,
		"display_name": display,
		"input_command": input_command,
		"input_glyphs": {},  # filled by InputGlyphPresenter
		"category": category,
		"move_type": str(move.get("move_type", "")),
		"grounded_air": str(move.get("grounded_air", "grounded")),
		"aura_requirement": _aura_requirement(move_id, move),
		"damage_role": _damage_role(move),
		"tactical_purpose": tactical,
		"playable": playable,
		"reachability": reachability,
		"animation_clip": clip,
		"signature_lane": sig_lane,
		"startup_frames": move.get("startup_frames", null),
		"active_frames": move.get("active_frames", null),
		"recovery_frames": move.get("recovery_frames", null),
		"damage": move.get("damage", null),
		"short_description": short_desc,
		"is_core": core_ids.has(move_id),
		"element_effect": move.get("element_effect", {}),
	}


static func _category_for(move_id: String, move: Dictionary) -> String:
	match move_id:
		"jab_1", "jab_2", "jab_finisher":
			return "NORMAL ATTACKS"
		"forward_tilt", "up_tilt", "down_tilt":
			return "TILTS / DIRECTIONAL ATTACKS"
		"neutral_air", "forward_air", "back_air", "up_air", "down_air":
			return "AERIALS"
		"dash_attack", "heavy_attack":
			return "HEAVY / SMASH ATTACKS"
		"neutral_special_projectile", "side_special", "down_special":
			return "SPECIALS"
		"aura_charge", "aura_burst":
			return "AURA / CHARGE"
		"grab":
			return "GRAB"
		"throw_forward", "throw_back", "throw_up", "throw_down":
			return "THROWS"
		"up_special_recovery", "recovery":
			return "RECOVERY"
		"dodge", "air_dodge", "shield":
			return "DEFENSE"
		_:
			if str(move.get("move_type", "")) == "movement":
				return "MOVEMENT"
			if move_id.begins_with("signature_lane_"):
				return "SIGNATURE TECHNIQUES"
			return "SPECIALS"


static func _aura_requirement(move_id: String, move: Dictionary) -> String:
	if move_id == "aura_burst":
		return "full_aura"
	if move_id == "aura_charge":
		return "hold_charge"
	if move.has("aura_scaling"):
		return "scales_with_aura"
	return "none"


static func _damage_role(move: Dictionary) -> String:
	var dmg := float(move.get("damage", 0.0))
	if dmg <= 0.0:
		return "utility"
	if dmg < 5.0:
		return "poke"
	if dmg < 12.0:
		return "confirm"
	return "finisher_pressure"


static func _default_tactic(fighter_id: String, move_id: String, _move: Dictionary) -> String:
	var fantasy := {
		"ember-vale": "Ignition-oriented pressure and explosive release.",
		"rook-ironside": "Slow, armored commitment that converts positioning into heavy impact.",
		"juno-spark": "Fast electrical attacks built around acceleration and rapid confirms.",
		"kaia-windrow": "Air-control tools that manipulate spacing with sweeping wind pressure.",
		"nix-calder": "Precise frost control that shapes safe and unsafe areas of the stage.",
		"orion-vell": "Vector and gravity manipulation that redirects movement and positioning.",
		"vesper-nyx": "Void/phase techniques that punish prediction and conventional spacing.",
	}
	var base := str(fantasy.get(fighter_id, "Fighter-specific tactical tool."))
	match move_id:
		"jab_1", "jab_2":
			return "Primary neutral poke — " + base
		"forward_tilt":
			return "Space control / approach check — " + base
		"neutral_special_projectile":
			return "Projectile / power tool — " + base
		"side_special":
			return "Signature approach / mix tool — " + base
		"down_special":
			return "Signature trap / control tool — " + base
		"aura_burst":
			return "Signature burst when aura is ready — " + base
		"up_special_recovery":
			return "Recovery / return-to-stage tool."
		"grab":
			return "Break shields and start throw mix."
		_:
			return base


static func _default_description(fighter_id: String, move_id: String, display: String, move: Dictionary) -> String:
	var el := str(move.get("element_effect", {}).get("type", ""))
	if not el.is_empty():
		return "%s — %s-flavored %s tool." % [display, el, str(move.get("move_type", "combat"))]
	return "%s — %s technique for %s." % [display, str(move.get("move_type", "combat")), fighter_id]


static func playable_entries(catalog: Dictionary) -> Array:
	var out: Array = []
	for e in catalog.get("entries", []):
		if bool(e.get("playable", false)):
			out.append(e)
	return out


static func lab_entries(catalog: Dictionary) -> Array:
	var out: Array = []
	for e in catalog.get("entries", []):
		if str(e.get("reachability", "")) == "LAB_ONLY":
			out.append(e)
	return out
