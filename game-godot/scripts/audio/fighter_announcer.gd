extends RefCounted
class_name FighterAnnouncer

## Original lock-in announcer. Announce on confirm only — never hover/focus.
## Spoken names use AnnouncerVoiceProvider (review-only TTS). Final voice is pending.

const _Bank = preload("res://scripts/audio/procedural_audio_bank.gd")
const _Identity = preload("res://scripts/visual/elemental_material_contract.gd")
const _Voice = preload("res://scripts/audio/announcer_voice_provider.gd")

const ANNOUNCER_FINAL_VOICE_ASSETS := false
const SELECT_ANNOUNCER_AUDIO_RIGHTS_READY := false
const DEBOUNCE_SEC := 0.55
const VOICE_LOCK_SEC := 0.85

const DISPLAY_NAMES := {
	"ember-vale": "Ember Vale",
	"rook-ironside": "Rook Ironside",
	"juno-spark": "Juno Spark",
	"kaia-windrow": "Kaia Windrow",
	"nix-calder": "Nix Calder",
	"orion-vell": "Orion Vell",
	"vesper-nyx": "Vesper Nyx",
}

signal fighter_lock_started(slot: int, fighter_id: String)
signal fighter_locked(slot: int, fighter_id: String)
signal announcer_name_started(fighter_id: String)
signal announcer_name_finished(fighter_id: String)

static var _last_lock_at: Dictionary = {}
static var _voice_busy_until: float = 0.0
static var _last_events: Array = []


static func display_name(fighter_id: String) -> String:
	return str(DISPLAY_NAMES.get(fighter_id, fighter_id.replace("-", " ").capitalize()))


static func shout_label(fighter_id: String) -> String:
	return "%s!" % display_name(fighter_id).to_upper()


static func now_sec() -> float:
	return Time.get_ticks_msec() / 1000.0


static func can_announce(slot: int, fighter_id: String) -> bool:
	if fighter_id.is_empty():
		return false
	var key := "%d:%s" % [slot, fighter_id]
	var last := float(_last_lock_at.get(key, -999.0))
	if now_sec() - last < DEBOUNCE_SEC:
		return false
	if now_sec() < _voice_busy_until:
		return false
	return true


static func announce_lock(slot: int, fighter_id: String, host: Node = null, hover: bool = false) -> Dictionary:
	var result := {
		"ok": false,
		"announced": false,
		"spoken": false,
		"hover_ignored": hover,
		"fighter_id": fighter_id,
		"slot": slot,
		"display_name": display_name(fighter_id),
		"spoken_name": _Voice.spoken_name(fighter_id),
		"shout": shout_label(fighter_id),
		"ANNOUNCER_FINAL_VOICE_ASSETS": ANNOUNCER_FINAL_VOICE_ASSETS,
		"SELECT_ANNOUNCER_AUDIO_RIGHTS_READY": SELECT_ANNOUNCER_AUDIO_RIGHTS_READY,
		"review_only": true,
		"reason": "",
	}
	if hover:
		result["reason"] = "hover_does_not_announce"
		_record("hover_ignored", result)
		return result
	if not can_announce(slot, fighter_id):
		result["reason"] = "debounced_or_busy"
		_record("debounced", result)
		return result
	_last_lock_at["%d:%s" % [slot, fighter_id]] = now_sec()
	_voice_busy_until = now_sec() + VOICE_LOCK_SEC
	_emit(host, "fighter_lock_started", [slot, fighter_id])
	_record("fighter_lock_started", result)
	_emit(host, "fighter_locked", [slot, fighter_id])
	_record("fighter_locked", result)
	_emit(host, "announcer_name_started", [fighter_id])
	_record("announcer_name_started", result)
	var stinger := _play_stinger(host)
	var motif := _play_name_motif(fighter_id, host)
	var spoken := _Voice.speak_lockin(fighter_id, host)
	result["stinger"] = stinger
	result["name_motif"] = motif
	result["spoken"] = bool(spoken.get("spoken", false))
	result["spoken_backend"] = str(spoken.get("backend", ""))
	result["voice"] = spoken
	result["announced"] = true
	result["ok"] = true
	if bool(spoken.get("spoken", false)):
		result["reason"] = "announced_review_spoken_name"
	else:
		result["reason"] = "announced_visual_and_stinger_speech_unavailable"
	_emit(host, "announcer_name_finished", [fighter_id])
	_record("announcer_name_finished", result)
	return result


static func missing_voice_asset_graceful(fighter_id: String) -> Dictionary:
	# Final spoken names are not installed. System remains usable.
	return {
		"ok": true,
		"fighter_id": fighter_id,
		"voice_missing": true,
		"ANNOUNCER_FINAL_VOICE_ASSETS": ANNOUNCER_FINAL_VOICE_ASSETS,
		"fallback": "visual_callout_plus_procedural_stinger",
	}


static func last_events() -> Array:
	return _last_events.duplicate(true)


static func reset_debounce_for_tests() -> void:
	_last_lock_at.clear()
	_voice_busy_until = 0.0
	_last_events.clear()


static func _play_stinger(host: Node) -> Dictionary:
	var path := "res://assets/audio/procedural/shared/lockin_stinger.wav"
	var played := _Bank.play(path, host)
	if not bool(played.get("ok", false)):
		played = _Bank.play_shared("ui_confirm", host)
		played["fallback"] = "ui_confirm"
	return played


static func _play_name_motif(fighter_id: String, host: Node) -> Dictionary:
	# Original per-fighter motif — not speech, not a licensed announcer pack.
	var path := "res://assets/audio/procedural/announcer/name_motif_%s.wav" % fighter_id
	var played := _Bank.play(path, host)
	if not bool(played.get("ok", false)):
		return missing_voice_asset_graceful(fighter_id)
	played["speech"] = false
	played["placeholder_motif"] = true
	return played


static func identity_color(fighter_id: String) -> Color:
	var colors := _Identity.identity_colors(fighter_id)
	return colors.get("tile_accent", colors.get("accent", Color(1.0, 0.85, 0.35)))


static func _emit(host: Node, event_name: String, args: Array) -> void:
	if host != null and is_instance_valid(host) and host.has_signal(event_name):
		host.emit_signal(event_name, args[0] if args.size() == 1 else args)
	var bus = Engine.get_main_loop().root.get_node_or_null("/root/JuiceEventBus") if Engine.get_main_loop() else null
	if bus != null and bus.has_method("emit_event"):
		bus.emit_event(event_name, {"args": args})


static func _record(kind: String, payload: Dictionary) -> void:
	_last_events.append({"kind": kind, "payload": payload.duplicate(true)})
	if _last_events.size() > 32:
		_last_events.pop_front()
