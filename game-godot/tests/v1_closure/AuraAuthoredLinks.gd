extends SceneTree
const Data = preload("res://scripts/data/data_loader.gd")
const Scaler = preload("res://scripts/combat/aura_scaler.gd")
const Identity = preload("res://scripts/combat/aura_identity.gd")
const Runner = preload("res://scripts/combat/move_runner.gd")
var output := ""
var failures: Array = []
var rows: Array = []
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
func run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output = arg.get_slice("=", 1)
	var runner = Runner.new(); root.add_child(runner)
	var body := Node2D.new(); root.add_child(body)
	for fid in preload("res://scripts/visual/spectral_feedback_renderer.gd").IDS:
		for move in Data.load_moves(fid).moves:
			var explicit: Array = move.get("cancel_windows", []).filter(func(w): return w.has("to") and w.get("requires", "") == "hit_confirm")
			for amount in [0, 25, 50, 75, 99, 100]:
				var scaled := Identity.apply_to_scaled_move(Scaler.apply_to_move(move, amount), fid, amount, "")
				var tier: Dictionary = move.get("aura_scaling", {}).get("super_ready" if amount == 100 else "level_" + str(Scaler.aura_level(amount)), {})
				for route in explicit:
					var expected: Dictionary = route.duplicate(true)
					if tier.has("cancel_windows"):
						for window in tier.cancel_windows:
							if not window.has("to") and not window.has("action"):
								expected.start = window.start; expected.end = window.end; break
					var label: String = fid + ":" + move.move_id + ":" + str(amount) + ":" + str(route.to)
					var matches: Array = scaled.get("cancel_windows", []).filter(func(w): return w.get("to", "") == route.to)
					check(matches.has(expected), label + ":tier_bounds_keep_authored_identity")
					if matches.is_empty(): continue
					runner.start_move(scaled, body)
					while runner.active and runner.total_frame < int(expected.start): runner.tick_sim_frame()
					check(not runner.can_cancel_to(route.to), label + ":whiff_rejected")
					for result in ["shield", "armor"]:
						runner.record_confirmed_contact({"confirmed_contact": true, "contact_result": result, "contact_owner": "melee", "attack_activation_id": runner.activation_id})
						check(not runner.can_cancel_to(route.to), label + ":" + result + "_rejected")
					for owner in ["projectile", "throw"]:
						runner.record_confirmed_contact({"confirmed_contact": true, "contact_result": "hit", "contact_owner": owner, "attack_activation_id": runner.activation_id})
						check(not runner.can_cancel_to(route.to), label + ":" + owner + "_rejected")
					runner.record_confirmed_contact({"confirmed_contact": true, "contact_result": "hit", "contact_owner": "melee", "attack_activation_id": runner.activation_id})
					check(runner.can_cancel_to(route.to), label + ":declared_link_available")
					check(not runner.can_cancel_to("not_authored"), label + ":unauthored_rejected")
					while runner.active and runner.total_frame <= int(expected.end): runner.tick_sim_frame()
					check(not runner.can_cancel_to(route.to), label + ":expiry_preserved")
					runner.cancel()
					rows.append({"fighter": fid, "move": move.move_id, "aura": amount, "window": expected, "scope": "resolved policy fixture; not a guaranteed combo or public 100-aura Attack route"})
				if explicit.is_empty():
					check(scaled.get("cancel_windows", []).filter(func(w): return w.has("to")).is_empty(), fid + ":" + move.move_id + ":no_invented_target")
	var f = FileAccess.open(output.path_join("aura_authored_links.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS": failures.is_empty(), "rows": rows, "failures": failures, "policy": "existing tier frame bounds plus existing explicit route identity; no catalog execution or blanket cancels"}, "  ")); f.close()
	print("AURA_AUTHORED_LINKS ", "PASS" if failures.is_empty() else "FAIL", " cases=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
