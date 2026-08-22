extends Node

## Typed game-juice event bus (Wave012). Battle HUD stays clean; debug is training-only.

signal juice_event(event_name: String, payload: Dictionary)

const EVENT_HITSTOP := "hitstop"
const EVENT_CAMERA_SHAKE := "camera_shake"
const EVENT_IMPACT_VFX := "impact_vfx"
const EVENT_AURA_BUILDUP := "aura_buildup"
const EVENT_PROJECTILE_TRAIL := "projectile_trail"
const EVENT_SHIELD_FLASH := "shield_flash"
const EVENT_DODGE_PHASE := "dodge_phase"
const EVENT_GRAB_FLASH := "grab_flash"
const EVENT_LANDING_DUST := "landing_dust"
const EVENT_RECOVERY_TRAIL := "recovery_trail"
const EVENT_KO_BURST := "ko_burst"
const EVENT_VICTORY := "victory_presentation"
const EVENT_SFX := "sfx"
const EVENT_RUMBLE := "rumble"
const EVENT_ACCESSIBILITY := "accessibility_reduce"

var _reduce_flash: bool = false
var _reduce_shake: bool = false
var _reduce_particles: bool = false
var _last_event: Dictionary = {}

func set_accessibility(flash: bool, shake: bool, particles: bool) -> void:
	_reduce_flash = flash
	_reduce_shake = shake
	_reduce_particles = particles
	emit_event(EVENT_ACCESSIBILITY, {
		"flash": flash,
		"shake": shake,
		"particles": particles,
	})

func emit_event(event_name: String, payload: Dictionary = {}) -> void:
	var body: Dictionary = payload.duplicate(true)
	body["event"] = event_name
	body["t_msec"] = Time.get_ticks_msec()
	if event_name == EVENT_CAMERA_SHAKE and _reduce_shake:
		body["intensity"] = 0.0
		body["duration_s"] = 0.0
	if event_name == EVENT_IMPACT_VFX and _reduce_particles:
		body["suppressed"] = true
	if event_name in [EVENT_SHIELD_FLASH, EVENT_GRAB_FLASH, EVENT_KO_BURST] and _reduce_flash:
		body["suppressed"] = true
	_last_event = body
	juice_event.emit(event_name, body)

func get_last_event() -> Dictionary:
	return _last_event.duplicate(true)
