extends RefCounted
class_name SmokeDataLoad

const FIGHTERS: Array[String] = [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

static func run() -> bool:
	var roster := DataLoader.roster_ids()
	SmokeAssert.ok(roster.size() >= 7, "roster should list 7 fighters, got %d" % roster.size())
	for id in FIGHTERS:
		SmokeAssert.ok(roster.has(id), "roster missing %s" % id)
		var fighter := DataLoader.load_fighter(id)
		SmokeAssert.ok(not fighter.is_empty(), "fighter JSON empty: %s" % id)
		SmokeAssert.ok(fighter.has("displayName"), "fighter missing displayName: %s" % id)
		var moves := DataLoader.load_moves(id)
		SmokeAssert.ok(not moves.is_empty(), "move manifest empty: %s" % id)
		var move_list: Array = moves.get("moves", [])
		SmokeAssert.ok(move_list.size() >= 10, "move manifest too small for %s" % id)
		for required in ["jab", "grab", "throw", "aura_burst"]:
			var found := false
			for m in move_list:
				if m.get("move_id", "") == required:
					found = true
					break
			SmokeAssert.ok(found, "%s missing move %s" % [id, required])
	return SmokeAssert.passed()
