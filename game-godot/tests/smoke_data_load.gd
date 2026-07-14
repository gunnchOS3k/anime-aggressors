extends RefCounted
class_name SmokeDataLoad
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _SmokeAssert = preload("res://tests/smoke_assert.gd")

const FIGHTERS: Array[String] = [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

## Canonical IDs from data/moves/move_schema.json required_move_ids.
## Smoke must match the production schema (jab_1…, throw_forward…), not legacy aliases.
const REQUIRED_MOVE_IDS: Array[String] = [
	"jab_1",
	"jab_2",
	"jab_finisher",
	"forward_tilt",
	"up_tilt",
	"down_tilt",
	"dash_attack",
	"heavy_attack",
	"neutral_air",
	"forward_air",
	"up_air",
	"down_air",
	"neutral_special_projectile",
	"side_special",
	"up_special_recovery",
	"down_special",
	"grab",
	"throw_forward",
	"throw_back",
	"throw_up",
	"throw_down",
	"aura_charge",
	"aura_burst",
]

static func run() -> bool:
	var roster := _DataLoader.roster_ids()
	_SmokeAssert.ok(roster.size() >= 7, "roster should list 7 fighters, got %d" % roster.size())
	for id in FIGHTERS:
		_SmokeAssert.ok(roster.has(id), "roster missing %s" % id)
		var fighter := _DataLoader.load_fighter(id)
		_SmokeAssert.ok(not fighter.is_empty(), "fighter JSON empty: %s" % id)
		_SmokeAssert.ok(fighter.has("displayName"), "fighter missing displayName: %s" % id)
		var moves := _DataLoader.load_moves(id)
		_SmokeAssert.ok(not moves.is_empty(), "move manifest empty: %s" % id)
		var move_list: Array = moves.get("moves", [])
		_SmokeAssert.ok(move_list.size() >= REQUIRED_MOVE_IDS.size(), "move manifest too small for %s" % id)
		var by_id: Dictionary = {}
		for m in move_list:
			by_id[String(m.get("move_id", ""))] = m
		for required in REQUIRED_MOVE_IDS:
			_SmokeAssert.ok(by_id.has(required), "%s missing move %s" % [id, required])
			if not by_id.has(required):
				continue
			var move: Dictionary = by_id[required]
			_SmokeAssert.ok(move.has("training_display_name"), "%s/%s missing training_display_name" % [id, required])
			if String(required).begins_with("throw_"):
				_SmokeAssert.ok(move.get("move_type", "") == "throw", "%s/%s move_type should be throw" % [id, required])
				_SmokeAssert.ok(move.has("throw"), "%s/%s missing throw block" % [id, required])
			elif required == "grab":
				_SmokeAssert.ok(move.get("move_type", "") == "grab" or move.has("hitboxes"), "%s grab missing shape" % id)
			elif required.begins_with("jab_") or required.ends_with("_tilt") or required.ends_with("_air") or required in ["dash_attack", "heavy_attack"]:
				var boxes: Array = move.get("hitboxes", [])
				_SmokeAssert.ok(boxes.size() > 0, "%s/%s missing hitboxes" % [id, required])
	return _SmokeAssert.passed()
