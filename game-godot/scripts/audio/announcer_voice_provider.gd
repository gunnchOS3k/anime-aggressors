extends RefCounted
class_name AnnouncerVoiceProvider

## Review-only spoken-name provider.
## Final licensed/owner performer assets are a separate future slot.
## Do not treat platform TTS or optional review renders as shipping voice art.

const REVIEW_ONLY := true
const ANNOUNCER_FINAL_VOICE_ASSETS := false
const SELECT_ANNOUNCER_AUDIO_RIGHTS_READY := false

## Future original/licensed recorded voice slot. Missing files are expected.
const FINAL_VOICE_DIR := "res://assets/audio/announcer/final/"
## Optional REVIEW_ONLY rendered speech. Forbidden for final release if present.
const REVIEW_RENDER_DIR := "res://assets/audio/announcer/review_only/"

const SPOKEN_NAMES := {
	"ember-vale": "Ember",
	"rook-ironside": "Rook",
	"juno-spark": "Juno",
	"kaia-windrow": "Kaia",
	"nix-calder": "Nix",
	"orion-vell": "Orion",
	"vesper-nyx": "Vesper",
}

## "", "fake", or "force_unavailable" — tests only.
static var _test_backend: String = ""
static var _speak_log: Array = []


static func spoken_name(fighter_id: String) -> String:
	return str(SPOKEN_NAMES.get(fighter_id, ""))


static func mapping_complete() -> bool:
	return SPOKEN_NAMES.size() == 7 and spoken_name("ember-vale") == "Ember"


static func final_voice_path(fighter_id: String) -> String:
	return "%s%s.wav" % [FINAL_VOICE_DIR, fighter_id]


static func review_render_path(fighter_id: String) -> String:
	return "%s%s.wav" % [REVIEW_RENDER_DIR, fighter_id]


static func use_fake_backend_for_tests() -> void:
	_test_backend = "fake"
	_speak_log.clear()


static func use_unavailable_backend_for_tests() -> void:
	_test_backend = "force_unavailable"
	_speak_log.clear()


static func reset_for_tests() -> void:
	_test_backend = ""
	_speak_log.clear()


static func speak_log() -> Array:
	return _speak_log.duplicate()


static func speak_lockin(fighter_id: String, host: Node = null) -> Dictionary:
	var name := spoken_name(fighter_id)
	var result := {
		"ok": false,
		"spoken": false,
		"fighter_id": fighter_id,
		"spoken_name": name,
		"backend": "",
		"review_only": REVIEW_ONLY,
		"ANNOUNCER_FINAL_VOICE_ASSETS": ANNOUNCER_FINAL_VOICE_ASSETS,
		"SELECT_ANNOUNCER_AUDIO_RIGHTS_READY": SELECT_ANNOUNCER_AUDIO_RIGHTS_READY,
		"reason": "",
	}
	if name.is_empty():
		result["reason"] = "unknown_fighter"
		_warn_unavailable(result)
		return result
	if _test_backend == "force_unavailable":
		result["backend"] = "unavailable_test"
		result["reason"] = "speech_unavailable"
		_warn_unavailable(result)
		return result
	if _test_backend == "fake":
		_speak_log.append(name)
		result["ok"] = true
		result["spoken"] = true
		result["backend"] = "fake_review_test"
		result["reason"] = "review_spoken_name"
		return result
	# Final recorded assets stay unused until rights and assets are both true.
	if ANNOUNCER_FINAL_VOICE_ASSETS and SELECT_ANNOUNCER_AUDIO_RIGHTS_READY and FileAccess.file_exists(final_voice_path(fighter_id)):
		result["backend"] = "final_recorded"
		result["reason"] = "final_assets_not_authorized"
		_warn_unavailable(result)
		return result
	var tts := _speak_platform_tts(name)
	if bool(tts.get("spoken", false)):
		_speak_log.append(name)
		result["ok"] = true
		result["spoken"] = true
		result["backend"] = "platform_tts_review_only"
		result["voice_id"] = tts.get("voice_id", "")
		result["reason"] = "review_spoken_name"
		return result
	if FileAccess.file_exists(review_render_path(fighter_id)):
		var played := _play_review_render(fighter_id, host)
		if bool(played.get("ok", false)):
			_speak_log.append(name)
			result["ok"] = true
			result["spoken"] = true
			result["backend"] = "review_only_render"
			result["reason"] = "review_spoken_name"
			return result
	result["backend"] = str(tts.get("backend", "none"))
	result["reason"] = "speech_unavailable"
	_warn_unavailable(result)
	return result


static func _speak_platform_tts(name: String) -> Dictionary:
	var out := {"spoken": false, "voice_id": "", "backend": "platform_tts_missing"}
	if not DisplayServer.has_method("tts_get_voices"):
		return out
	if not DisplayServer.has_method("tts_speak"):
		return out
	var voices: Array = DisplayServer.tts_get_voices()
	if voices.is_empty():
		out["backend"] = "platform_tts_empty"
		return out
	var voice_id := _pick_review_voice(voices)
	if voice_id.is_empty():
		out["backend"] = "platform_tts_no_voice"
		return out
	DisplayServer.tts_speak(name, voice_id, 85, 1.0, 0.95, 0, false)
	out["spoken"] = true
	out["voice_id"] = voice_id
	out["backend"] = "platform_tts_review_only"
	return out


static func _pick_review_voice(voices: Array) -> String:
	var fallback := ""
	for voice in voices:
		if typeof(voice) != TYPE_DICTIONARY:
			continue
		var lang := str(voice.get("language", ""))
		var voice_id := str(voice.get("id", ""))
		if voice_id.is_empty():
			continue
		if fallback.is_empty():
			fallback = voice_id
		if lang.begins_with("en"):
			return voice_id
	return fallback


static func _play_review_render(fighter_id: String, host: Node) -> Dictionary:
	var path := review_render_path(fighter_id)
	if host == null or not is_instance_valid(host):
		return {"ok": false, "reason": "no_host"}
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return {"ok": false, "reason": "review_render_unreadable"}
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	host.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return {"ok": true, "path": path, "review_only": true}


static func _warn_unavailable(result: Dictionary) -> void:
	push_warning(
		"REVIEW_ONLY announcer spoken-name unavailable: fighter=%s reason=%s"
		% [str(result.get("fighter_id", "")), str(result.get("reason", ""))]
	)
