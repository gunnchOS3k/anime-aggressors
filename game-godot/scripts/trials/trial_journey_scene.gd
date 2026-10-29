extends "res://scripts/ui/console_menu_base.gd"
## Shared SELECT→SETUP→PLAY→RESULTS→SAVE journey host for Trials modes.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const Eligibility = preload("res://scripts/trials/rosamere_trials_eligibility.gd")
const Derby = preload("res://scripts/trials/derby/resonance_trial_sim.gd")
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
var _unbound_preset: String = Unbound.PRESET_TOTAL


func _ready() -> void:
	super._ready()
	if mode_id.is_empty():
		mode_id = str(GameState.trial_mode_id)
	if title_label:
		var entry: Dictionary = Authority.mode_entry(mode_id)
		title_label.text = str(entry.get("display_name", mode_id))
	_build_ui()
	_enter_select()


func _build_ui() -> void:
	var vbox := get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	_status = Label.new()
	_status.name = "JourneyStatus"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(520, 180)
	vbox.add_child(_status)
	for item in [
		["AdvanceBtn", "Advance Journey", _on_advance],
		["PlayBtn", "Run Playable Sim", _on_play],
		["SaveBtn", "Save Local Record", _on_save],
		["BackBtn", "Back to Trials", on_back],
	]:
		var b := Button.new()
		b.name = item[0]
		b.text = item[1]
		b.custom_minimum_size = Vector2(320, 48)
		b.pressed.connect(item[2])
		vbox.add_child(b)


func _enter_select() -> void:
	_phase = "select"
	var pc: Dictionary = Authority.player_count_truth(mode_id)
	var forms: Array = Eligibility.offered_forms(mode_id, GameState.mythic_party_consent, GameState.trial_story_reveal)
	_status.text = "SELECT\nMode: %s\nPlayers: %d–%d (%s)\nRosamere forms offered: %s\nRanked MMR: never\nShipping flags: all false" % [
		mode_id, int(pc.min), int(pc.max), str(pc.honest_note), ", ".join(forms),
	]
	GameState.trial_journey_phase = _phase


func _on_advance() -> void:
	match _phase:
		"select":
			_phase = "setup"
			_setup()
		"setup":
			_phase = "play"
			_status.text = "PLAY ready — press Run Playable Sim"
		"play":
			_phase = "results"
			_status.text = "RESULTS\n%s" % JSON.stringify(_summarize(), "  ")
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
			_state = Unbound.advance_journey(_state)  # select -> setup
			_state = Unbound.advance_journey(_state)  # setup -> play
		_:
			_state = {"mode": mode_id, "error": "unknown"}
	_status.text = "SETUP\n%s" % JSON.stringify(_setup_blurb(), "  ")


func _setup_blurb() -> Dictionary:
	return {
		"mode": mode_id,
		"phase": _state.get("phase", ""),
		"seed": _state.get("seed", 0),
		"label": _state.get("label", ""),
		"feeds_ranked_mmr": false,
	}


func _on_play() -> void:
	_phase = "play"
	match mode_id:
		"resonance_trial":
			_state = Derby.run_solo_to_results(int(_state.get("seed", 42)), str(_state.get("fighter_id", "ember-vale")))
		"fractured_accord":
			_state = Flagline.run_capture_journey(int(_state.get("seed", 42)))
		"prism_weave":
			## Short deterministic burst for interactive play; full 60s available in suite.
			var s: Dictionary = _state if not _state.is_empty() else Prism.create(42, 4)
			for i in range(60 * 5):
				s = Prism.step(s)
				if str(s.get("phase", "")) == "results":
					break
			_state = s
		"riftline_defense":
			_state = Riftline.run_seeded_smoke(int(_state.get("seed", 42)))
		"echoes_gauntlet":
			_state = Echoes.run_clear_smoke(int(_state.get("seed", 42)), bool(_state.get("coop", false)))
		"convergence_unbound":
			if _state.is_empty():
				_setup()
			_state = Unbound.simulate_play_frames(_state, 180)
			_state = Unbound.advance_journey(_state)  # play -> results
		_:
			pass
	_phase = "results"
	GameState.trial_journey_phase = _phase
	_status.text = "RESULTS\n%s" % JSON.stringify(_summarize(), "  ")


func _summarize() -> Dictionary:
	match mode_id:
		"resonance_trial":
			return {
				"phase": _state.get("phase", ""),
				"score": _state.get("score", 0),
				"grade": _state.get("grade", ""),
				"distance": int(_state.get("final_distance", 0)) / 1000,
				"contract_seconds": 10,
				"hash": Derby.state_hash(_state),
			}
		"fractured_accord":
			return {
				"phase": _state.get("phase", ""),
				"winning_team": _state.get("winning_team", ""),
				"display_winner": Flagline.display_team(str(_state.get("winning_team", ""))),
				"rooms_won": _state.get("rooms_won", {}),
				"hash": Flagline.state_hash(_state),
			}
		"prism_weave":
			return {"phase": _state.get("phase", ""), "winner_slot": _state.get("winner_slot", -1), "hash": Prism.state_hash(_state)}
		"riftline_defense":
			return {"phase": _state.get("phase", ""), "score": _state.get("score", 0), "wave": _state.get("wave", 0), "hash": Riftline.state_hash(_state)}
		"echoes_gauntlet":
			return {
				"phase": _state.get("phase", ""),
				"canonical_cosmic_defeat": _state.get("canonical_cosmic_defeat", false),
				"score": _state.get("score", 0),
				"hash": Echoes.state_hash(_state),
			}
		"convergence_unbound":
			return {
				"phase": _state.get("phase", ""),
				"label": _state.get("label", ""),
				"preset": _state.get("rules", {}).get("preset_id", ""),
				"feeds_ranked_mmr": Unbound.never_feeds_ranked(_state),
				"colossus_rigs": (_state.get("colossus_rigs", []) as Array).size(),
			}
		_:
			return _state


func _on_save() -> void:
	_phase = "save"
	_save = Authority.empty_save_payload(mode_id, int(_state.get("seed", 0)), _summarize())
	GameState.record_trial_result(_save)
	_status.text = "SAVE (local only)\n%s" % JSON.stringify(_save, "  ")
	GameState.trial_journey_phase = _phase


func footer_hint() -> String:
	return "Journey SELECT→SETUP→PLAY→RESULTS→SAVE · never ranked"


func on_back() -> void:
	SceneRouter.go("trials")
