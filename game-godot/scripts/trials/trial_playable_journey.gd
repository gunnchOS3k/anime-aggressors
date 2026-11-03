extends RefCounted
class_name TrialPlayableJourney
## Playable-experience helpers for Trials of Convergence journeys.
## SELECT instructions → SETUP → PLAY (live shared combat or honest SIMULATION) →
## RESULTS (win/loss) → RETRY / SAVE / EXIT. Never ranked MMR / HUMAN_ART / V1.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Derby = preload("res://scripts/trials/derby/resonance_trial_sim.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")
const Prism = preload("res://scripts/trials/prism/prism_weave_sim.gd")
const Riftline = preload("res://scripts/trials/riftline/riftline_defense_sim.gd")
const Echoes = preload("res://scripts/trials/echoes/echoes_gauntlet_sim.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")


static func first_play_instructions(mode_id: String) -> String:
	var e: Dictionary = Authority.mode_entry(mode_id)
	return str(e.get("first_play_instructions", ""))


static func win_condition(mode_id: String) -> String:
	return str(Authority.mode_entry(mode_id).get("win_condition", ""))


static func loss_condition(mode_id: String) -> String:
	return str(Authority.mode_entry(mode_id).get("loss_condition", ""))


static func retry_policy(mode_id: String) -> String:
	return str(Authority.mode_entry(mode_id).get("retry_policy", ""))


static func is_playable_experience(mode_id: String) -> bool:
	var e: Dictionary = Authority.mode_entry(mode_id)
	return bool(e.get("playable_experience", false)) and Bridge.supports_live_shared_combat(mode_id)


static func select_blurb(mode_id: String, seat_count: int = 2) -> Dictionary:
	var e: Dictionary = Authority.mode_entry(mode_id)
	var pc: Dictionary = Authority.player_count_truth(mode_id)
	return {
		"mode_id": mode_id,
		"display_name": str(e.get("display_name", mode_id)),
		"subtitle": str(e.get("subtitle", "")),
		"first_play_instructions": first_play_instructions(mode_id),
		"win_condition": win_condition(mode_id),
		"loss_condition": loss_condition(mode_id),
		"retry_policy": retry_policy(mode_id),
		"players": pc,
		"seat_count": seat_count,
		"live_shared_combat": Bridge.supports_live_shared_combat(mode_id),
		"playable_experience": is_playable_experience(mode_id),
		"feeds_ranked_mmr": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
	}


static func evaluate_outcome(mode_id: String, state: Dictionary) -> Dictionary:
	## Honest win/loss/abort from mode state. SIMULATION vs REAL_PLAYER is separate.
	var phase := str(state.get("phase", ""))
	var result_kind := str(state.get("result_kind", "SIMULATION"))
	if result_kind != "REAL_PLAYER":
		result_kind = "SIMULATION"
	var outcome := "incomplete"
	var detail := ""
	match mode_id:
		"resonance_trial":
			if phase == "results" and int(state.get("score", 0)) > 0:
				outcome = "win"
				detail = "score=%d grade=%s" % [int(state.get("score", 0)), str(state.get("grade", ""))]
			elif phase == "results":
				outcome = "loss"
				detail = "no_score"
			else:
				outcome = "incomplete"
		"fractured_accord":
			var wt := str(state.get("winning_team", ""))
			if wt != "":
				outcome = "win"
				detail = "winning_team=%s" % wt
			elif phase == "results" or str(state.get("room_win_reason", "")) != "":
				outcome = "loss" if wt == "" else "win"
				detail = str(state.get("room_win_reason", "room_resolved"))
			elif bool(state.get("game_won", false)) or str(state.get("game_result", "")) != "":
				outcome = "win"
				detail = str(state.get("game_result", "game_won"))
			else:
				outcome = "incomplete"
		"prism_weave":
			if phase == "results":
				var slot := int(state.get("winner_slot", -1))
				outcome = "win" if slot == 0 or slot == 1 else "loss"
				detail = "winner_slot=%d" % slot
			else:
				outcome = "incomplete"
		"riftline_defense":
			if phase == "results" or bool(state.get("cleared", false)):
				outcome = "win" if int(state.get("lives", 1)) > 0 or bool(state.get("cleared", false)) else "loss"
				detail = "score=%d wave=%d" % [int(state.get("score", 0)), int(state.get("wave", 0))]
			elif int(state.get("lives", 3)) <= 0:
				outcome = "loss"
				detail = "lives_exhausted"
			else:
				outcome = "incomplete"
		"echoes_gauntlet":
			if bool(state.get("canonical_cosmic_defeat", false)):
				outcome = "loss"
				detail = "canonical_cosmic_defeat_forbidden_flag"
			elif phase == "results" or bool(state.get("cleared", false)):
				outcome = "win"
				detail = "score=%d" % int(state.get("score", 0))
			else:
				outcome = "incomplete"
		"convergence_unbound":
			if phase == "results" or phase == "save":
				outcome = "win"
				detail = "preset=%s" % str(state.get("rules", {}).get("preset_id", ""))
			elif bool(state.get("aborted", false)):
				outcome = "loss"
				detail = "aborted"
			else:
				outcome = "incomplete"
		_:
			outcome = "incomplete"
			detail = "unknown_mode"
	return {
		"mode_id": mode_id,
		"outcome": outcome,
		"detail": detail,
		"phase": phase,
		"result_kind": result_kind,
		"feeds_ranked_mmr": false,
		"retry_allowed": true,
		"exit_returns_to": "trials",
	}


static func run_simulation_play(mode_id: String, seed: int = 42, seats: int = 2, unbound_preset: String = Unbound.PRESET_TOTAL) -> Dictionary:
	## Honest SIMULATION playable burst — never auto REAL_PLAYER.
	var state: Dictionary = {}
	match mode_id:
		"resonance_trial":
			state = Derby.run_solo_to_results(seed, "ember-vale")
		"fractured_accord":
			state = Flagline.run_capture_journey(seed, seats)
		"prism_weave":
			state = Prism.create(seed, clampi(seats, 2, 10))
			for _i in range(60 * 5):
				state = Prism.step(state)
				if str(state.get("phase", "")) == "results":
					break
		"riftline_defense":
			state = Riftline.run_seeded_smoke(seed)
		"echoes_gauntlet":
			state = Echoes.run_clear_smoke(seed, seats >= 2)
		"convergence_unbound":
			state = Unbound.create_session(seed, unbound_preset, true, seats)
			state = Unbound.advance_journey(state)
			state = Unbound.advance_journey(state)
			state = Unbound.simulate_play_frames(state, 180)
			state = Unbound.advance_journey(state)
		_:
			return {"ok": false, "reason": "unknown_mode", "mode_id": mode_id}
	state["result_kind"] = "SIMULATION"
	state["earned_personal_best"] = false
	var outcome: Dictionary = evaluate_outcome(mode_id, state)
	return {
		"ok": true,
		"mode_id": mode_id,
		"state": state,
		"outcome": outcome,
		"playable_experience": is_playable_experience(mode_id),
		"first_play_instructions": first_play_instructions(mode_id),
		"result_kind": "SIMULATION",
		"feeds_ranked_mmr": false,
	}


static func run_ordinary_live_prep(mode_id: String, seats: int = 2, unbound_preset: String = Unbound.PRESET_COLOSSUS) -> Dictionary:
	## Prepare live shared combat for ordinary-input ownership paths.
	if not Bridge.supports_live_shared_combat(mode_id):
		return {"ok": false, "reason": "live_shared_combat_unsupported", "mode_id": mode_id}
	var prep: Dictionary = Bridge.prepare_live_battle(mode_id, seats, unbound_preset, -1)
	prep["first_play_instructions"] = first_play_instructions(mode_id)
	prep["playable_experience"] = is_playable_experience(mode_id)
	prep["win_condition"] = win_condition(mode_id)
	prep["loss_condition"] = loss_condition(mode_id)
	prep["retry_policy"] = retry_policy(mode_id)
	return prep


static func exit_to_trials_menu(gs: Node) -> Dictionary:
	## Mode exit clears Trials modifiers and returns to Trials hub contract.
	if gs != null and gs.has_method("end_trial"):
		gs.end_trial()
	return {
		"ok": true,
		"exit_returns_to": "trials",
		"standard_modes_restored": true,
		"feeds_ranked_mmr": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
	}
