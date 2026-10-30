extends "res://scripts/ui/console_menu_base.gd"
## Shared SELECT→SETUP→PLAY→RESULTS→SAVE journey host for Trials modes.
## Playable experience contract: first-play instructions, win/loss, retry, mode exit.
## Run Playable Sim = SIMULATION. Enter Live Shared Combat = ordinary-input path.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const Eligibility = preload("res://scripts/trials/rosamere_trials_eligibility.gd")
const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Presentation = preload("res://scripts/trials/mode_presentation.gd")
const Journey = preload("res://scripts/trials/trial_playable_journey.gd")
const Seats = preload("res://scripts/trials/partylink_seat_enforcement.gd")
const A11y = preload("res://scripts/ui/accessibility_surface.gd")
const Derby = preload("res://scripts/trials/derby/resonance_trial_sim.gd")
const ResonanceDummy = preload("res://scripts/trials/derby/resonance_dummy_actor.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")
const Prism = preload("res://scripts/trials/prism/prism_weave_sim.gd")
const Riftline = preload("res://scripts/trials/riftline/riftline_defense_sim.gd")
const Echoes = preload("res://scripts/trials/echoes/echoes_gauntlet_sim.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")

@export var mode_id: String = "resonance_trial"

var _status: Label
var _phase: String = "select"
var _state: Dictionary = {}
var _save: Dictionary = {}
var _outcome: Dictionary = {}
var _unbound_preset: String = Unbound.PRESET_TOTAL


func _ready() -> void:
	super._ready()
	if mode_id.is_empty():
		mode_id = str(GameState.trial_mode_id)
	if title_label:
		var entry: Dictionary = Authority.mode_entry(mode_id)
		title_label.text = str(entry.get("display_name", mode_id))
	_build_ui()
	_apply_digital_a11y()
	_enter_select()


func _apply_digital_a11y() -> Dictionary:
	## AA-RTM-009 digital polish — reduce-motion/focus/SR labels. Not device matrix pass.
	var contract: Dictionary = A11y.trials_journey_a11y_contract(mode_id)
	var polished: Dictionary = A11y.polish_menu_surface(self, "trials_journey:" + mode_id, {
		"AdvanceBtn": "Advance Trials journey",
		"PlayBtn": "Run playable simulation",
		"LiveBattleBtn": "Enter live shared combat",
		"RetryBtn": "Retry trial",
		"SaveBtn": "Save local Trials record",
		"BackBtn": "Back to Trials hub",
	})
	if _status != null and bool(contract.get("reduce_motion", false)):
		_status.text = str(_status.text) + "\nA11y: reduce_motion ON · digital polish ≠ device matrix pass"
	set_meta("trials_a11y_contract", contract)
	set_meta("trials_a11y_polish", polished)
	return polished


func _build_ui() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	_status = Label.new()
	_status.name = "JourneyStatus"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(520, 220)
	vbox.add_child(_status)
	for item in [
		["AdvanceBtn", "Advance Journey", _on_advance],
		["PlayBtn", "Run Playable Sim", _on_play],
		["LiveBattleBtn", "Enter Live Shared Combat", _on_live_battle],
		["RetryBtn", "Retry Trial", _on_retry],
		["SaveBtn", "Save Local Record", _on_save],
		["BackBtn", "Back to Trials", on_back],
	]:
		var b := Button.new()
		b.name = item[0]
		b.text = item[1]
		b.custom_minimum_size = Vector2(320, 48)
		b.pressed.connect(item[2])
		vbox.add_child(b)
		if item[0] == "LiveBattleBtn" and not Bridge.supports_live_shared_combat(mode_id):
			b.disabled = true
			b.text = "Live Shared Combat (unavailable)"
		elif item[0] == "LiveBattleBtn":
			b.text = "Enter Live Shared Combat"


func _enter_select() -> void:
	_phase = "select"
	_outcome = {}
	var blurb: Dictionary = Journey.select_blurb(mode_id, GameState.trial_seat_count)
	var forms: Array = Eligibility.offered_forms(mode_id, GameState.mythic_party_consent, GameState.trial_story_reveal)
	var art: Dictionary = Presentation.for_mode(mode_id, GameState.match_seed if GameState.match_seed != 0 else 42)
	_status.text = "SELECT — first-play instructions\n%s\n\nWin: %s\nLoss: %s\nRetry: %s\n\nPlayers: %d–%d (%s)\nRosamere forms: %s\nLive shared combat: %s · playable_experience: %s\nart_status: %s · HUMAN_ART=%s\nRanked MMR: never · Shipping flags: all false" % [
		str(blurb.get("first_play_instructions", "")),
		str(blurb.get("win_condition", "")),
		str(blurb.get("loss_condition", "")),
		str(blurb.get("retry_policy", "")),
		int(blurb.get("players", {}).get("min", 1)),
		int(blurb.get("players", {}).get("max", 1)),
		str(blurb.get("players", {}).get("honest_note", "")),
		", ".join(forms),
		str(blurb.get("live_shared_combat", false)),
		str(blurb.get("playable_experience", false)),
		str(art.get("art_status", "")),
		str(art.get("HUMAN_ART", false)),
	]
	GameState.trial_journey_phase = _phase


func _on_live_battle() -> void:
	var prep: Dictionary = Journey.run_ordinary_live_prep(mode_id, GameState.trial_seat_count, _unbound_preset)
	if not bool(prep.get("ok", false)):
		_status.text = "Live battle blocked (honest seats / mode):\n%s" % JSON.stringify(prep, "  ")
		return
	_phase = "play"
	GameState.trial_journey_phase = _phase
	_status.text = "PLAY — live shared combat\n%s\nEntering BattleScene…" % str(prep.get("first_play_instructions", ""))
	SceneRouter.go("battle")


func _on_advance() -> void:
	match _phase:
		"select":
			_phase = "setup"
			_setup()
		"setup":
			_phase = "play"
			_status.text = "PLAY ready — Run Playable Sim (SIMULATION) or Enter Live Shared Combat (ordinary-input)"
		"play":
			_show_results()
		"results":
			_phase = "save"
			_on_save()
		_:
			_enter_select()
	GameState.trial_journey_phase = _phase


func _setup() -> void:
	var seed := GameState.match_seed if GameState.match_seed != 0 else 42
	match mode_id:
		"resonance_trial":
			_state = Derby.create(seed, GameState.p1_fighter_id, 0)
			_state["challenge"] = GameState.trial_challenge
		"fractured_accord":
			_state = Flagline.create(seed, 0)
		"prism_weave":
			_state = Prism.create(seed, clampi(GameState.trial_seat_count, 2, 10))
		"riftline_defense":
			_state = Riftline.create(seed, GameState.p1_fighter_id, clampi(GameState.trial_seat_count, 1, 2))
		"echoes_gauntlet":
			_state = Echoes.create(seed, GameState.trial_seat_count >= 2)
		"convergence_unbound":
			_state = Unbound.create_session(seed, _unbound_preset, GameState.mythic_party_consent, GameState.trial_seat_count)
			_state = Unbound.advance_journey(_state)
			_state = Unbound.advance_journey(_state)
		_:
			_state = {"mode": mode_id, "error": "unknown"}
	var seat_card: Dictionary = Seats.presentation_honesty_card(mode_id, GameState.trial_seat_count, -1)
	_status.text = "SETUP\nInstructions: %s\n%s\n\n%s" % [
		Journey.first_play_instructions(mode_id),
		JSON.stringify(_setup_blurb(), "  "),
		str(seat_card.get("text", "")),
	]


func _setup_blurb() -> Dictionary:
	var seat_card: Dictionary = Seats.presentation_honesty_card(mode_id, GameState.trial_seat_count, -1)
	return {
		"mode": mode_id,
		"phase": _state.get("phase", ""),
		"seed": _state.get("seed", 0),
		"label": _state.get("label", ""),
		"win_condition": Journey.win_condition(mode_id),
		"feeds_ranked_mmr": false,
		"partylink_seat_honesty": {
			"seated": seat_card.get("seated", 0),
			"battle_scene_fighter_slots": seat_card.get("battle_scene_fighter_slots", 2),
			"invented_seats": false,
			"live_partylink": false,
			"SHIPPING_ROLLBACK_ENABLED": false,
		},
	}


func _on_play() -> void:
	_phase = "play"
	var played: Dictionary = Journey.run_simulation_play(
		mode_id,
		int(_state.get("seed", GameState.match_seed if GameState.match_seed != 0 else 42)),
		GameState.trial_seat_count,
		_unbound_preset
	)
	_state = played.get("state", {}) as Dictionary
	if mode_id == "resonance_trial":
		_state["dummy_actor"] = ResonanceDummy.identity()
	_show_results()


func _show_results() -> void:
	_phase = "results"
	_outcome = Journey.evaluate_outcome(mode_id, _state)
	GameState.trial_journey_phase = _phase
	_status.text = "RESULTS — %s (%s)\n%s\nWin condition: %s\nLoss condition: %s\n%s" % [
		str(_outcome.get("outcome", "incomplete")).to_upper(),
		str(_outcome.get("result_kind", "SIMULATION")),
		str(_outcome.get("detail", "")),
		Journey.win_condition(mode_id),
		Journey.loss_condition(mode_id),
		JSON.stringify(_summarize(), "  "),
	]


func _on_retry() -> void:
	## Retry returns to SETUP with fresh state; does not invent REAL_PLAYER.
	_outcome = {}
	_save = {}
	_setup()
	_phase = "setup"
	GameState.trial_journey_phase = _phase
	_status.text = "RETRY → SETUP\n%s\n%s" % [
		Journey.retry_policy(mode_id),
		JSON.stringify(_setup_blurb(), "  "),
	]


func _summarize() -> Dictionary:
	var base: Dictionary = {}
	match mode_id:
		"resonance_trial":
			base = {
				"phase": _state.get("phase", ""),
				"score": _state.get("score", 0),
				"grade": _state.get("grade", ""),
				"distance": int(_state.get("final_distance", 0)) / 1000,
				"contract_seconds": 10,
				"hash": Derby.state_hash(_state),
			}
		"fractured_accord":
			base = {
				"phase": _state.get("phase", ""),
				"winning_team": _state.get("winning_team", ""),
				"display_winner": Flagline.display_team(str(_state.get("winning_team", ""))),
				"rooms_won": _state.get("rooms_won", {}),
				"hash": Flagline.state_hash(_state),
			}
		"prism_weave":
			base = {"phase": _state.get("phase", ""), "winner_slot": _state.get("winner_slot", -1), "hash": Prism.state_hash(_state)}
		"riftline_defense":
			base = {"phase": _state.get("phase", ""), "score": _state.get("score", 0), "wave": _state.get("wave", 0), "hash": Riftline.state_hash(_state)}
		"echoes_gauntlet":
			base = {
				"phase": _state.get("phase", ""),
				"canonical_cosmic_defeat": _state.get("canonical_cosmic_defeat", false),
				"score": _state.get("score", 0),
				"hash": Echoes.state_hash(_state),
			}
		"convergence_unbound":
			base = {
				"phase": _state.get("phase", ""),
				"label": _state.get("label", ""),
				"preset": _state.get("rules", {}).get("preset_id", ""),
				"feeds_ranked_mmr": Unbound.never_feeds_ranked(_state),
				"colossus_rigs": (_state.get("colossus_rigs", []) as Array).size(),
			}
		_:
			base = _state.duplicate(true)
	base["outcome"] = _outcome
	base["playable_experience"] = Journey.is_playable_experience(mode_id)
	return base


func _on_save() -> void:
	_phase = "save"
	var kind := str(_state.get("result_kind", "SIMULATION"))
	if kind != "REAL_PLAYER":
		kind = "SIMULATION"
	_save = Authority.empty_save_payload(mode_id, int(_state.get("seed", 0)), _summarize(), kind)
	GameState.record_trial_result(_save)
	_status.text = "SAVE (local %s only — never ranked/career/story)\nOutcome: %s\n%s" % [
		kind,
		str(_outcome.get("outcome", "incomplete")),
		JSON.stringify(_save, "  "),
	]
	GameState.trial_journey_phase = _phase


func footer_hint() -> String:
	return "Journey SELECT→SETUP→PLAY→RESULTS→RETRY/SAVE/EXIT · never ranked"


func on_back() -> void:
	Journey.exit_to_trials_menu(GameState)
	SceneRouter.go("trials")
