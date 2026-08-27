extends RefCounted
class_name AuraTierContract

## Wave021 ascension aura tiers (0–3). Distinct from combat aura_level 0–4 scaling.

const TIER_CALM := 0
const TIER_BUILDING := 1
const TIER_SURGING := 2
const TIER_ASCENSION_READY := 3

const TIER_NAMES := {
	TIER_CALM: "CALM",
	TIER_BUILDING: "BUILDING",
	TIER_SURGING: "SURGING",
	TIER_ASCENSION_READY: "ASCENSION_READY",
}

const TIER_THRESHOLDS := [
	{"min": 0.0, "max": 24.99, "tier": TIER_CALM},
	{"min": 25.0, "max": 49.99, "tier": TIER_BUILDING},
	{"min": 50.0, "max": 74.99, "tier": TIER_SURGING},
	{"min": 75.0, "max": 100.0, "tier": TIER_ASCENSION_READY},
]


static func tier_from_aura(aura_amount: float) -> int:
	for entry in TIER_THRESHOLDS:
		if aura_amount >= entry.min and aura_amount <= entry.max:
			return int(entry.tier)
	return TIER_CALM


static func tier_name(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 0, 3), "CALM"))


static func can_initiate_transform(aura_amount: float) -> bool:
	return tier_from_aura(aura_amount) >= TIER_ASCENSION_READY


static func audio_escalation_profile(fighter_id: String, tier: int) -> Dictionary:
	var base_hz := 220.0
	var element_bias := 0.0
	match fighter_id:
		"ember-vale":
			element_bias = 40.0
		"rook-ironside":
			element_bias = -30.0
		"juno-spark":
			element_bias = 80.0
		"kaia-windrow":
			element_bias = 20.0
		"nix-calder":
			element_bias = -10.0
		"orion-vell":
			element_bias = 15.0
		"vesper-nyx":
			element_bias = -20.0
	var t := clampi(tier, 0, 3)
	return {
		"fighter_id": fighter_id,
		"tier": t,
		"tier_name": tier_name(t),
		"procedural_pitch_hz": base_hz + element_bias + float(t) * 35.0,
		"procedural_volume": 0.35 + float(t) * 0.12,
		"royalty_safe": true,
	}


static func contract_snapshot() -> Dictionary:
	return {
		"schema": "wave021_aura_tier/v1",
		"tiers": TIER_NAMES.duplicate(),
		"thresholds": TIER_THRESHOLDS.duplicate(true),
	}
