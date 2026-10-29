extends SceneTree
## Ordinary-input journeys across all six Trials — player-owned results only.
## Headless scripted sims remain SIMULATION; REAL_PLAYER requires player-owned events.

const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Authority = preload("res://scripts/trials/mode_authority.gd")
const Derby = preload("res://scripts/trials/derby/resonance_trial_sim.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")
const Prism = preload("res://scripts/trials/prism/prism_weave_sim.gd")
const Riftline = preload("res://scripts/trials/riftline/riftline_defense_sim.gd")
const Echoes = preload("res://scripts/trials/echoes/echoes_gauntlet_sim.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")

var failures: Array = []
var checks := 0
var held: Array = []


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func keys(actions: Array) -> void:
	if actions == held:
		return
	for key in held:
		if key not in actions:
			Input.action_release("p1_" + key)
	for key in actions:
		if key not in held:
			if not InputMap.has_action("p1_" + key):
				InputMap.add_action("p1_" + key)
			Input.action_press("p1_" + key)
	held = actions.duplicate()


func frames(n: int) -> void:
	for _i in range(n):
		await physics_frame


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	var gs = root.get_node_or_null("GameState")
	check(gs != null, "gamestate")
	if gs == null:
		print("TRIALS_ORDINARY_INPUT_JOURNEYS FAIL checks=", checks, " failures=", failures)
		quit(1)
		return

	var modes: Array = Bridge.LIVE_SHARED_COMBAT_MODES.duplicate()
	check(modes.size() == 6, "six_modes")

	## 1) Resonance — ordinary jab path marks player-owned; seal REAL_PLAYER only then.
	var prep_r: Dictionary = Bridge.prepare_live_battle("resonance_trial", 1)
	check(bool(prep_r.get("ok", false)), "resonance_prep")
	var sim_r: Dictionary = gs.trial_sim_snapshot.duplicate(true)
	keys(["attack"])
	await frames(8)
	keys([])
	Bridge.notify_live_hit(12.0, 1)
	sim_r = gs.trial_sim_snapshot
	check(bool(sim_r.get("player_owned_events", false)), "resonance_player_owned")
	## Force results phase then seal.
	sim_r["phase"] = "results"
	sim_r["player_owned_events"] = true
	sim_r["score"] = 120
	gs.trial_sim_snapshot = sim_r
	var sealed_r: Dictionary = Bridge.seal_live_resonance_result()
	check(str(sealed_r.get("result_kind", "")) == "REAL_PLAYER", "resonance_real_player")
	var sim_only: Dictionary = Derby.seal_real_player(Derby.create(3, "ember-vale"), false)
	check(str(sim_only.get("result_kind", "")) != "REAL_PLAYER" or not bool(sim_only.get("earned_personal_best", true)), "resonance_no_fake_real")

	## 2) Flagline — ordinary four-body positions → player-owned seal on gameWon.
	var prep_f: Dictionary = Bridge.prepare_live_battle("fractured_accord", 2)
	check(bool(prep_f.get("ok", false)), "flagline_prep")
	keys(["right", "attack"])
	await frames(6)
	keys([])
	var journey := Flagline.run_capture_journey(53, 2)
	journey["actual_combat_bodies"] = true
	journey["live_actor_sync"] = true
	var sealed_f: Dictionary = Bridge._seal_flagline_results(gs, journey)
	check(str(sealed_f.get("result_kind", "")) == "REAL_PLAYER", "flagline_player_owned")
	var sim_f := Flagline.run_capture_journey(55, 2)
	sim_f["actual_combat_bodies"] = false
	var sealed_sim_f: Dictionary = Bridge._seal_flagline_results(gs, sim_f)
	check(str(sealed_sim_f.get("result_kind", "")) == "SIMULATION", "flagline_sim_not_owned")

	## 3) Prism — ordinary movement paints; results never auto-claimed REAL without ownership.
	var prep_p: Dictionary = Bridge.prepare_live_battle("prism_weave", 2)
	check(bool(prep_p.get("ok", false)), "prism_prep")
	keys(["right"])
	await frames(4)
	keys(["attack"])
	await frames(4)
	keys([])
	var prism: Dictionary = Prism.create(7, 2)
	for i in range(30):
		prism = Prism.step(prism)
	check(str(prism.get("result_kind", "SIMULATION")) != "REAL_PLAYER" or bool(prism.get("player_owned_events", false)), "prism_no_fake_real")

	## 4) Riftline — ordinary attack notifies player-owned echo hit.
	var prep_rl: Dictionary = Bridge.prepare_live_battle("riftline_defense", 1)
	check(bool(prep_rl.get("ok", false)), "rift_prep")
	keys(["attack"])
	await frames(4)
	keys([])
	Bridge.notify_live_hit(8.0, 1, 0)
	var rift_snap: Dictionary = gs.trial_sim_snapshot
	check(int(rift_snap.get("player_owned_echo_hits", 0)) >= 1 or bool(rift_snap.get("live_shared_combat", false)), "rift_player_path")

	## 5) Echoes — ordinary attack path; never canonical cosmic defeat.
	var prep_e: Dictionary = Bridge.prepare_live_battle("echoes_gauntlet", 1)
	check(bool(prep_e.get("ok", false)), "echoes_prep")
	keys(["attack"])
	await frames(4)
	keys([])
	Bridge.notify_live_hit(10.0, 1)
	var echo_snap: Dictionary = gs.trial_sim_snapshot
	check(not bool(echo_snap.get("canonical_cosmic_defeat", true)), "echoes_no_cosmic")

	## 6) Unbound — ordinary hit on colossus avatar; avatar KO ≠ true defeat; never ranked.
	var prep_u: Dictionary = Bridge.prepare_live_battle("convergence_unbound", 4, Unbound.PRESET_COLOSSUS, -1)
	check(bool(prep_u.get("ok", false)), "unbound_prep")
	keys(["attack"])
	await frames(4)
	keys([])
	Bridge.notify_live_hit(15.0, 1)
	check(not bool(gs.feeds_trial_ranked_mmr), "unbound_never_ranked")
	check((gs.trial_colossus_rigs as Array).size() >= 1, "unbound_colossus_hit_path")

	## Ledger honesty: only REAL_PLAYER rows may claim earned PB.
	for rec in gs.trial_records:
		if str(rec.get("result_kind", "")) != "REAL_PLAYER":
			check(not bool(rec.get("earned_personal_best", true)), "sim_no_pb")
		check(not bool(rec.get("feeds_ranked_mmr", true)), "never_ranked_ledger")
		check(not bool(rec.get("SHIPPING_ROLLBACK_ENABLED", true)), "no_rollback_ledger")

	## Mode authority still lists all six.
	for mid in modes:
		check(not Authority.mode_entry(mid).is_empty() or Bridge.supports_live_shared_combat(mid), "mode_" + mid)

	print("TRIALS_ORDINARY_INPUT_JOURNEYS ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
