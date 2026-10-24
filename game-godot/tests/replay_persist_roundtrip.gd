extends SceneTree

## Isolated private-match replay round-trip.
## The completion path must write the record ReplayStore.write_json already
## knows how to store, then read that same JSON and check the existing checksum.
## Refuses the owner "Anime Aggressors" user directory.

const REPLAY_PATH := "user://aa_private_match_replay.json"
const EXPECT_SEED := 77
const EXPECT_FRAMES := 12


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var user_dir := OS.get_user_data_dir()
	print("USER_DIR %s" % user_dir)
	if "Anime Aggressors" in user_dir:
		print("FAIL refused owner save directory")
		quit(2)
		return
	var Replay = load("res://scripts/net/replay_store.gd")
	var Stack = load("res://scripts/net/private_netplay_stack.gd")
	var has_write: bool = bool(Replay.has_method("write_json"))
	var has_read: bool = bool(Replay.has_method("read_json"))
	print("HAS_WRITE_JSON %s" % str(has_write))
	print("HAS_READ_JSON %s" % str(has_read))

	var stack = Stack.new()
	var hosted: Dictionary = stack.host_create_room("ProbeHost", 42.0, 6.0, 0.0)
	var joined: Dictionary = stack.guest_join("ProbeGuest", "", 55.0, 12.0, 0.0)
	var started: Dictionary = stack.ready_and_start(EXPECT_SEED, "skyline-arena")
	var match_result: Dictionary = stack.simulate_match_frames(EXPECT_FRAMES)
	var memory_ok: bool = bool(match_result.get("replay", {}).get("ok", false)) and bool(match_result.get("replay_chain", {}).get("ok", false))
	var exists: bool = FileAccess.file_exists(REPLAY_PATH)
	print("HOST_OK %s" % str(bool(hosted.get("ok", false))))
	print("JOIN_OK %s" % str(bool(joined.get("ok", false))))
	print("START_OK %s" % str(bool(started.get("ok", false))))
	print("MATCH_OK %s" % str(bool(match_result.get("ok", false))))
	print("MEMORY_VERIFY %s" % str(memory_ok))
	print("MEMORY_FRAMES %s" % str(match_result.get("frames", -1)))
	print("REPLAY_WRITTEN %s" % str(bool(match_result.get("replay_written", false))))
	print("DISK_EXISTS %s" % str(exists))
	if exists:
		var info := FileAccess.get_file_as_bytes(REPLAY_PATH)
		print("DISK_BYTES %d" % info.size())

	if not has_read or not exists:
		print("ROUNDTRIP false")
		print("FAIL completion kept the verified record in memory and did not leave %s" % REPLAY_PATH)
		quit(1)
		return

	var loaded: Dictionary = Replay.read_json(REPLAY_PATH)
	var rec: Dictionary = loaded.get("record", {})
	var meta: Dictionary = rec.get("meta", {})
	var frames: Array = rec.get("frames", [])
	print("RELOADED ok=%s frame_count=%s seed=%s roster=%s integrity=%s" % [
		str(bool(loaded.get("ok", false))),
		str(rec.get("frame_count", -1)),
		str(meta.get("seed", -1)),
		str(meta.get("roster", [])),
		str(rec.get("integrity", "")),
	])
	print("RELOADED_VERIFY %s" % str(loaded.get("verify", {})))
	print("RELOADED_CHAIN %s" % str(loaded.get("chain", {})))
	var same: bool = bool(loaded.get("ok", false)) \
		and int(rec.get("frame_count", -1)) == EXPECT_FRAMES \
		and frames.size() == EXPECT_FRAMES \
		and int(meta.get("seed", -1)) == EXPECT_SEED \
		and str(meta.get("stage", "")) == "skyline-arena" \
		and str(rec.get("build", "")) != "" \
		and str(rec.get("integrity", "")) != ""
	if frames.size() > 0:
		var first: Dictionary = frames[0]
		print("FRAME0 frame=%s checksum=%s" % [str(first.get("frame", -1)), str(first.get("checksum", ""))])
		same = same and int(first.get("frame", -1)) == 0 and str(first.get("checksum", "")) != ""
	var tamper_ok: bool = _tamper_fails(REPLAY_PATH)
	print("TAMPER_REJECTED %s" % str(tamper_ok))
	var roundtrip: bool = same and tamper_ok
	print("ROUNDTRIP %s" % str(roundtrip))
	if not roundtrip:
		print("FAIL reloaded record did not match the private-match record or its checksum")
		quit(1)
		return
	print("PASS private match replay roundtrip")
	quit(0)


func _tamper_fails(path: String) -> bool:
	var Replay = load("res://scripts/net/replay_store.gd")
	var raw := FileAccess.get_file_as_string(path)
	if raw == "":
		return false
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var bad: Dictionary = parsed
	bad["integrity"] = "tampered"
	var tamper_path := "user://aa_private_match_replay_tampered.json"
	var wrote: bool = bool(Replay.write_json(bad, tamper_path))
	if not wrote:
		return false
	var loaded: Dictionary = Replay.read_json(tamper_path)
	var errors: Array = loaded.get("verify", {}).get("errors", [])
	return not bool(loaded.get("ok", false)) and errors.has("integrity_fail")
