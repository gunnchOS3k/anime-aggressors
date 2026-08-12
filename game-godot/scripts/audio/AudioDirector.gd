extends Node

## Production audio director — real autoload over ProceduralAudioBank + Master bus.
## Headless/null-audio drivers still exercise call paths and state; acoustic
## device output remains PHYSICAL_PENDING.

const _Bank = preload("res://scripts/audio/procedural_audio_bank.gd")

var _enabled: bool = true
var _music_playing: bool = false
var _last_music_stage: String = ""
var _last_ui: String = ""
var _last_sfx: String = ""
var _paused_snapshot: Dictionary = {}
var _degraded: bool = false
var ACOUSTIC_OUTPUT_PHYSICAL: String = "PHYSICAL_PENDING"


func _ready() -> void:
	apply_master_volume(float(GameState.master_volume) if Engine.get_main_loop() else 1.0)
	_Bank.ensure_bus_player(self)


func apply_master_volume(linear: float) -> void:
	var v := clampf(linear, 0.0, 1.0)
	if Engine.get_main_loop() and "master_volume" in GameState:
		GameState.master_volume = v
	var db := -80.0 if v <= 0.0 else linear_to_db(maxf(0.0001, v))
	AudioServer.set_bus_volume_db(0, db)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		stop_music()


func play_ui(category: String = "ui_confirm") -> Dictionary:
	if not _enabled:
		return {"ok": true, "skipped": true, "reason": "disabled"}
	var result: Dictionary = _Bank.play_shared(category, self)
	_last_ui = category
	if not bool(result.get("ok", false)):
		_degraded = true
	return result


func play_sfx(fighter_id: String, category: String) -> Dictionary:
	if not _enabled:
		return {"ok": true, "skipped": true, "reason": "disabled"}
	var result: Dictionary = _Bank.play_fighter(fighter_id, category, self)
	_last_sfx = "%s:%s" % [fighter_id, category]
	if not bool(result.get("ok", false)):
		_degraded = true
		# Fail-soft: shared bank fallback already inside play_fighter.
	return result


func play_stage_music(stage_id: String) -> Dictionary:
	if not _enabled:
		return {"ok": true, "skipped": true, "reason": "disabled"}
	var result: Dictionary = _Bank.play_stage_bed(stage_id, self)
	_last_music_stage = stage_id
	_music_playing = bool(result.get("ok", false))
	if not _music_playing:
		_degraded = true
	return result


func stop_music() -> void:
	var root := _Bank.ensure_bus_player(self)
	if root == null:
		_music_playing = false
		return
	for child in root.get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
			child.queue_free()
	_music_playing = false


func on_pause() -> void:
	_paused_snapshot = {
		"music_playing": _music_playing,
		"last_music_stage": _last_music_stage,
		"master_volume": float(GameState.master_volume),
	}
	# Soft-pause: stop playback nodes but retain logical state for resume.
	var root := _Bank.ensure_bus_player(self)
	if root != null:
		for child in root.get_children():
			if child is AudioStreamPlayer:
				(child as AudioStreamPlayer).stream_paused = true


func on_resume() -> void:
	var root := _Bank.ensure_bus_player(self)
	if root != null:
		for child in root.get_children():
			if child is AudioStreamPlayer:
				(child as AudioStreamPlayer).stream_paused = false
	# If pause cleared players, restore stage bed from snapshot without inventing new content.
	if bool(_paused_snapshot.get("music_playing", false)) and not _music_playing:
		play_stage_music(str(_paused_snapshot.get("last_music_stage", "training-grid")))


func describe() -> Dictionary:
	return {
		"schema": "aa_audio_director/v1",
		"enabled": _enabled,
		"music_playing": _music_playing,
		"last_ui": _last_ui,
		"last_sfx": _last_sfx,
		"last_music_stage": _last_music_stage,
		"degraded": _degraded,
		"ACOUSTIC_OUTPUT_PHYSICAL": ACOUSTIC_OUTPUT_PHYSICAL,
		"bus_volume_db": AudioServer.get_bus_volume_db(0),
	}
