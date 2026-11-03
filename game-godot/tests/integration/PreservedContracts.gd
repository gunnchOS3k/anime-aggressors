extends SceneTree
## Real source APIs in an isolated user directory; no earned progress or match acceptance.
const Outcome = preload("res://scripts/combat/combat_outcome.gd")
const Replay = preload("res://scripts/net/replay_store.gd")
var failures: Array = []
var checks := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	# These sources reference autoloads. Load after the isolated tree exists,
	# just like the preserved save/replay probes, rather than at script compile.
	var Story = load("res://scripts/story/v1_campaign_runtime.gd")
	var Stack = load("res://scripts/net/private_netplay_stack.gd")
	if not OS.get_user_data_dir().get_file().begins_with("aa-preserved-"):
		push_error("Refusing non-isolated user directory"); quit(2); return
	for gate in ["parry", "shield", "armor", "invulnerable", "explicit_zero", "rules_zero", "dealt_mult_zero", "resolved_zero"]:
		var zero := Outcome.confirmed_body_damage(37.5, 0.0, gate)
		check(zero.meter_after == 37.5 and zero.damage_applied == 0.0 and zero.stocks_delta == 0, "resolved_zero:"+gate)
	var hit := Outcome.confirmed_body_damage(37.5, 6.25)
	check(hit.meter_after == 43.75 and hit.damage_applied == 6.25, "resolved_damage_once")
	check(Outcome.guard_transition("idle", true, true, true, true, false).state == "shield_start", "fresh_guard")
	check(Outcome.guard_transition("shield_start", true, false, true, true, false).state == "shield_hold", "held_guard")
	check(Outcome.parry_window_open(3, false) and not Outcome.parry_window_open(4, false), "four_frame_guard_window")
	check(Outcome.shield_contact(100, 3, true, 6).state == "parry", "parry_outcome")
	check(Outcome.shield_contact(100, 3, false, 6).shield_health == 97, "shield_damage_separate")
	# Explicit prefix fixtures test restoration; they never claim earned nodes.
	var ids: Array = ["kaia:one", "kaia:two", "kaia:three"]
	var saved: Dictionary = Story.story_checkpoint("kaia-windrow", ids, [ids[0]], 2, 61.25)
	saved.cursor = "untrusted:cursor"
	var restored: Dictionary = Story.restore_story_checkpoint(saved, ids)
	check(restored.cursor == ids[1] and restored.combat.stocks == 2 and restored.combat.damage_percent == 61.25, "cursor_and_combat_restore_together")
	var broken: Dictionary = Story.story_checkpoint("kaia-windrow", ids, [ids[1]], 3, 0.0)
	check(broken.completed.is_empty() and not broken.has("combat"), "invalid_prefix_does_not_restore_combat")
	check(not Story.story_checkpoint("kaia-windrow", ids, [ids[0]], true, 0.0).has("combat"), "reject_boolean_stock")
	var stack = Stack.new()
	stack.host_create_room("IsolatedHost", 42.0, 6.0, 0.0)
	stack.guest_join("IsolatedGuest", "", 55.0, 12.0, 0.0)
	stack.ready_and_start(77, "skyline-arena")
	var simulation: Dictionary = stack.simulate_match_frames(12)
	check(simulation.ok, "existing_private_stack_simulation")
	var prior := Replay.read_json(Replay.DEFAULT_PATH)
	check(prior.ok, "existing_replay_disk_roundtrip")
	if prior.ok:
		var record := Replay.create_record(prior.record.meta, prior.record.frames, restored)
		var path := "user://story_replay_fixture.json"
		check(Replay.write_json(record, path), "story_replay_write")
		var loaded := Replay.read_json(path)
		check(loaded.ok, "story_replay_read")
		if loaded.ok:
			check(loaded.record.story_checkpoint == {"cursor":ids[1], "stocks":2, "damage_percent":61.25}, "story_replay_preserves_result")
		var bad := record.duplicate(true)
		bad.story_checkpoint.damage_percent = 0.0
		check(not Replay.verify_record(bad).ok, "story_replay_rejects_changed_result")
	print("PRESERVED_CONTRACTS ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
