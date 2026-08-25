extends SceneTree

## Wave018 — select-to-battle visibility campaign.
## >=100 launches; every fighter as player and opponent multiple times.

const BATTLE_PATH := "res://scenes/battle/BattleScene.tscn"
const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const OUT_PATHS := [
	"res://../artifacts/engineering_wave018/SELECT_TO_BATTLE_VISIBILITY_RESULT.json",
	"../artifacts/engineering_wave018/SELECT_TO_BATTLE_VISIBILITY_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("/root/GameState")
	if gs == null:
		_finish({"ok": false, "error": "GameState missing"}, 1)
		return
	var packed: PackedScene = load(BATTLE_PATH)
	if packed == null:
		_finish({"ok": false, "error": "BattleScene missing"}, 1)
		return

	var launches := 0
	var ghosts := 0
	var as_player: Dictionary = {}
	var as_opponent: Dictionary = {}
	var modes_covered: Dictionary = {}
	var failures: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 18019

	# Ensure each fighter is P1 and P2 at least 3 times, then pad to >=100
	for round_i in 3:
		for p1 in FIGHTERS:
			for p2 in FIGHTERS:
				if p1 == p2:
					continue
				if launches >= 100 and round_i > 0:
					break
				var mode := _mode_for(launches)
				modes_covered[mode] = true
				var ok: bool = await _launch(gs, packed, p1, p2, mode, failures)
				launches += 1
				as_player[p1] = int(as_player.get(p1, 0)) + 1
				as_opponent[p2] = int(as_opponent.get(p2, 0)) + 1
				if not ok:
					ghosts += 1
			if launches >= 120:
				break
		if launches >= 120:
			break

	while launches < 100:
		var p1b: String = FIGHTERS[rng.randi_range(0, FIGHTERS.size() - 1)]
		var p2b: String = FIGHTERS[rng.randi_range(0, FIGHTERS.size() - 1)]
		if p1b == p2b:
			p2b = FIGHTERS[(FIGHTERS.find(p1b) + 1) % FIGHTERS.size()]
		var mode2 := _mode_for(launches)
		modes_covered[mode2] = true
		var ok2: bool = await _launch(gs, packed, p1b, p2b, mode2, failures)
		launches += 1
		as_player[p1b] = int(as_player.get(p1b, 0)) + 1
		as_opponent[p2b] = int(as_opponent.get(p2b, 0)) + 1
		if not ok2:
			ghosts += 1

	var every_as_player := true
	var every_as_opp := true
	for f in FIGHTERS:
		if int(as_player.get(f, 0)) < 2:
			every_as_player = false
		if int(as_opponent.get(f, 0)) < 2:
			every_as_opp = false

	var payload := {
		"ok": ghosts == 0 and launches >= 100 and every_as_player and every_as_opp,
		"SELECT_TO_BATTLE_LAUNCHES": launches,
		"SELECT_TO_BATTLE_GHOST_OCCURRENCES": ghosts,
		"as_player_counts": as_player,
		"as_opponent_counts": as_opponent,
		"modes_covered": modes_covered.keys(),
		"failures_sample": failures.slice(0, mini(24, failures.size())),
	}
	_finish(payload, 0 if payload["ok"] else 1)


func _mode_for(i: int) -> String:
	match i % 6:
		0:
			return "versus"
		1:
			return "direct"
		2:
			return "next_bout"
		3:
			return "home"
		4:
			return "rematch"
		_:
			return "arcade"


func _launch(gs, packed: PackedScene, p1: String, p2: String, mode: String, failures: Array) -> bool:
	gs.begin_local_versus(false)
	gs.p1_fighter_id = p1
	gs.p2_fighter_id = p2
	gs.p1_is_cpu = true
	gs.p2_is_cpu = true
	gs.stage_id = "ember-courtyard"
	gs.stocks = 3
	gs.set_meta("wave018_entry_mode", mode)
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	for _i in range(36):
		await process_frame
	var ok := true
	for f in [scene.fighter1, scene.fighter2]:
		if f == null:
			ok = false
			failures.append("%s:fighter_null" % mode)
			continue
		if f.has_method("ensure_visible_presentation"):
			f.ensure_visible_presentation()
		var inv: Dictionary = f.assert_visible_body_invariant() if f.has_method("assert_visible_body_invariant") else {"PASS": false}
		if not bool(inv.get("PASS", false)):
			ok = false
			failures.append("%s:%s:ghost" % [mode, str(f.fighter_id)])
		if bool(inv.get("VISIBLE_BODY_ZERO", false)):
			ok = false
	scene.queue_free()
	for _j in range(4):
		await process_frame
	return ok


func _finish(payload: Dictionary, code: int) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t"))
			f.close()
			break
	print(JSON.stringify(payload))
	quit(code)
