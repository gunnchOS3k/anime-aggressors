extends RefCounted
class_name SmokeGameRcAchievements

## Real-condition achievement tests. No cheat unlock path.

const _SmokeAssert = preload("res://tests/smoke_assert.gd")
const _Runtime := preload("res://scripts/core/AchievementRuntime.gd")

const CATALOG := "res://release/ACHIEVEMENTS.json"
const SAVE := "user://aa_achievements_smoke.json"


static func run() -> bool:
	_SmokeAssert.reset()
	_wipe_save()
	var rt = _Runtime.new()
	rt.configure_isolated(SAVE, CATALOG)
	_SmokeAssert.ok(rt.catalog_count() == 12, "catalog count 12")
	_SmokeAssert.ok(rt.completion_percent() == 0.0, "start at 0%")
	_SmokeAssert.ok(not rt.is_unlocked("aa.first_steps"), "tutorial locked")

	# Hidden entries stay masked in the browser until unlocked.
	var hidden_masked := false
	for entry in rt.browser_entries():
		if str(entry.get("id", "")) == "aa.hidden_undefeated":
			hidden_masked = str(entry.get("title", "")) == "???" and not bool(entry.get("unlocked", false))
	_SmokeAssert.ok(hidden_masked, "hidden achievement masked")

	# Real flag from complete_tutorial path.
	rt.set_flag("tutorial_completed", true)
	_SmokeAssert.ok(rt.is_unlocked("aa.first_steps"), "tutorial unlock")
	var stamp := rt.unlocked_at("aa.first_steps")
	_SmokeAssert.ok(not stamp.is_empty(), "unlock timestamp")
	rt.set_flag("tutorial_completed", true)
	_SmokeAssert.ok(rt.unlocked_at("aa.first_steps") == stamp, "duplicate prevention keeps timestamp")
	_SmokeAssert.ok(rt.unlocked_count() == 1, "duplicate did not double-count")

	rt.report_event("match_won", 1)
	_SmokeAssert.ok(rt.is_unlocked("aa.first_blood"), "first win")
	rt.report_event("match_complete", 5)
	_SmokeAssert.ok(rt.is_unlocked("aa.veteran"), "five matches")
	rt.report_event("pause_resume", 1)
	_SmokeAssert.ok(rt.is_unlocked("aa.pause_and_breathe"), "pause/resume")
	rt.report_event("credits_opened", 1)
	_SmokeAssert.ok(rt.is_unlocked("aa.credits_roll"), "credits")

	rt.set_flag("challenge:damage_100", true)
	rt.report_event("challenge_complete", 1)
	rt.set_flag("challenge:ko_90s", true)
	rt.report_event("challenge_complete", 1)
	rt.set_flag("challenge:survive_stocks", true)
	rt.report_event("challenge_complete", 1)
	_SmokeAssert.ok(rt.is_unlocked("aa.break_100"), "break 100")
	_SmokeAssert.ok(rt.is_unlocked("aa.ko_clock"), "ko clock")
	_SmokeAssert.ok(rt.is_unlocked("aa.hold_the_line"), "survive")
	_SmokeAssert.ok(rt.is_unlocked("aa.challenge_set"), "three challenges")

	rt.set_flag("arcade_complete", true)
	rt.set_stat("arcade_wins", 7.0)
	_SmokeAssert.ok(rt.is_unlocked("aa.arcade_clear"), "arcade clear")
	_SmokeAssert.ok(rt.is_unlocked("aa.hidden_undefeated"), "hidden undefeated")

	# Two-bout sprint flag.
	rt.set_flag("challenge:arcade_sprint", true)
	_SmokeAssert.ok(rt.is_unlocked("aa.sprint_two"), "sprint two")

	_SmokeAssert.ok(rt.unlocked_count() == 12, "all 12 unlocked via real conditions")
	_SmokeAssert.ok(is_equal_approx(rt.completion_percent(), 100.0), "100%")
	var notes: Array = rt.drain_notifications()
	_SmokeAssert.ok(notes.size() >= 12, "UI notifications queued")
	_SmokeAssert.ok(rt.pending_notification_count() == 0, "drain clears queue")

	# Persist + reload.
	var rt2 = _Runtime.new()
	rt2.configure_isolated(SAVE, CATALOG)
	_SmokeAssert.ok(rt2.is_unlocked("aa.first_steps"), "persist reload")
	_SmokeAssert.ok(rt2.unlocked_at("aa.first_steps") == stamp, "timestamp persisted")
	_SmokeAssert.ok(is_equal_approx(rt2.completion_percent(), 100.0), "percent persisted")

	# Offline: save is a local user:// file, not a network call.
	_SmokeAssert.ok(FileAccess.file_exists(SAVE), "offline save file")

	_wipe_save()
	return _SmokeAssert.passed()


static func _wipe_save() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
