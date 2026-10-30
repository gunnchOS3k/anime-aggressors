extends SceneTree
## Six Trials playable-experience lifecycle — instructions, live prep, win/loss,
## retry, mode exit. Not HUD-only registry. SIMULATION ≠ REAL_PLAYER. Not V1.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Journey = preload("res://scripts/trials/trial_playable_journey.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")

var failures: Array = []
var checks := 0
var evidence: Dictionary = {}


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	var gs = root.get_node_or_null("GameState")
	check(gs != null, "gamestate")
	if gs == null:
		_finish()
		return

	var modes: Array = Bridge.LIVE_SHARED_COMBAT_MODES.duplicate()
	check(modes.size() == 6, "six_live_modes")
	var catalog_live: Array = Authority.load_catalog().get("live_shared_combat_modes", [])
	check(catalog_live.size() == 6, "catalog_lists_six_live")
	for mid in modes:
		check(mid in catalog_live, "catalog_live:" + str(mid))

	var per_mode: Dictionary = {}
	for mid in modes:
		var mid_s := str(mid)
		check(Journey.is_playable_experience(mid_s), "playable:" + mid_s)
		var instr := Journey.first_play_instructions(mid_s)
		check(instr.length() > 40, "instructions:" + mid_s)
		check(Journey.win_condition(mid_s).length() > 10, "win:" + mid_s)
		check(Journey.loss_condition(mid_s).length() > 10, "loss:" + mid_s)
		check(Journey.retry_policy(mid_s).length() > 10, "retry:" + mid_s)

		var blurb: Dictionary = Journey.select_blurb(mid_s, 2)
		check(bool(blurb.get("live_shared_combat", false)), "blurb_live:" + mid_s)
		check(str(blurb.get("first_play_instructions", "")) == instr, "blurb_instr:" + mid_s)

		## Live shared combat prep (CPU fill — not invented human seats).
		var seats := 2
		if mid_s == "resonance_trial" or mid_s == "riftline_defense" or mid_s == "echoes_gauntlet":
			seats = 1
		var prep: Dictionary = Journey.run_ordinary_live_prep(mid_s, seats, Unbound.PRESET_COLOSSUS)
		check(bool(prep.get("ok", false)), "live_prep:" + mid_s)
		check(Bridge.supports_live_shared_combat(mid_s), "bridge_live:" + mid_s)

		## Ordinary-input ownership pulse while live.
		if InputMap.has_action("p1_attack") == false:
			InputMap.add_action("p1_attack")
		Input.action_press("p1_attack")
		await physics_frame
		await physics_frame
		Input.action_release("p1_attack")
		Bridge.notify_live_hit(9.0, 1, 0 if mid_s == "riftline_defense" else -1)

		## Simulation playable burst → win/loss evaluation + retry contract.
		var played: Dictionary = Journey.run_simulation_play(mid_s, 40 + checks, seats, Unbound.PRESET_COLOSSUS)
		check(bool(played.get("ok", false)), "sim_play:" + mid_s)
		check(str(played.get("result_kind", "")) == "SIMULATION", "sim_kind:" + mid_s)
		var outcome: Dictionary = played.get("outcome", {}) as Dictionary
		check(str(outcome.get("outcome", "")) in ["win", "loss", "incomplete"], "outcome_enum:" + mid_s)
		check(bool(outcome.get("retry_allowed", false)), "retry_allowed:" + mid_s)
		check(str(outcome.get("exit_returns_to", "")) == "trials", "exit_trials:" + mid_s)
		## Incomplete is allowed for short smoke on some modes; win preferred when phase results.
		var state: Dictionary = played.get("state", {}) as Dictionary
		if str(state.get("phase", "")) == "results" or str(state.get("phase", "")) == "save":
			check(str(outcome.get("outcome", "")) != "incomplete", "resolved_outcome:" + mid_s)

		## Mode exit restores standard modes (clears trial modifiers).
		var exited: Dictionary = Journey.exit_to_trials_menu(gs)
		check(bool(exited.get("ok", false)), "exit_ok:" + mid_s)
		check(not bool(gs.feeds_trial_ranked_mmr), "exit_never_ranked:" + mid_s)

		per_mode[mid_s] = {
			"instructions_len": instr.length(),
			"live_prep_ok": bool(prep.get("ok", false)),
			"sim_outcome": outcome.get("outcome", ""),
			"result_kind": "SIMULATION",
			"playable_experience": true,
		}

	## Catalog journey contract present.
	var contract: Dictionary = Authority.load_catalog().get("journey_contract", {})
	check(contract.get("requires", []) is Array and (contract.get("requires", []) as Array).size() >= 4, "journey_contract")
	check(not bool(Authority.load_catalog().get("HUMAN_ART_APPROVED", true)), "human_art_false")
	check(not bool(Authority.load_catalog().get("V1_0_0_RELEASE_AUTHORIZED", true)), "v1_false")

	evidence = {"modes": per_mode, "six": modes}
	_finish()


func _finish() -> void:
	var result := {
		"PASS": failures.is_empty(),
		"checks": checks,
		"failures": failures,
		"evidence": evidence,
		"scope": "Six Trials playable journey lifecycle: instructions, live shared combat prep, win/loss/retry/exit. Not device/V1/HUMAN_ART.",
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"req_id": "AA-RTM-004",
	}
	print("TRIALS_PLAYABLE_JOURNEY_LIFECYCLE ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	var out_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):
			out_dir = arg.trim_prefix("--ordinary-output=")
	if not out_dir.is_empty():
		var f := FileAccess.open(out_dir.path_join("TRIALS_PLAYABLE_JOURNEY_LIFECYCLE.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
	quit(0 if failures.is_empty() else 1)
