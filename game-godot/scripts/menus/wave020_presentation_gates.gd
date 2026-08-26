extends RefCounted
class_name Wave020PresentationGates

## Wave020 STOP_THE_LINE — presentation slice gates.
## After baseline + REG-008 + Slice A/B retests: framing+flourish ON for player builds.
## Diagnostics may freeze via WAVE020_SLICE_MODE=baseline|a|b.

static var dynamic_framing_enabled: bool = true
static var showcase_flourish_enabled: bool = true
## Accepted on Wave020 v1 (PR #91); remain on unless select regresses.
static var pause_movelist_enabled: bool = true
static var elemental_audio_enabled: bool = true


static func freeze_revised_presentation() -> void:
	dynamic_framing_enabled = false
	showcase_flourish_enabled = false


static func enable_slice_a_framing() -> void:
	dynamic_framing_enabled = true


static func enable_slice_b_flourish() -> void:
	showcase_flourish_enabled = true


static func currently_enabled() -> Dictionary:
	return {
		"dynamic_framing": dynamic_framing_enabled,
		"showcase_flourish": showcase_flourish_enabled,
		"pause_movelist": pause_movelist_enabled,
		"elemental_audio": elemental_audio_enabled,
	}
