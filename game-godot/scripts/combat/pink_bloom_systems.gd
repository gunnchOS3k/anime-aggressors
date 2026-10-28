extends RefCounted
## Deterministic Primordial Pink / First Bloom combat systems.
## Narrative omnipotence ≠ desync: every gameplay-affecting effect carries a
## stable event ID and is retired from combat state on expiry or cancel.
##
## THREE-FORM CANON (owner-approved name/title/mythology):
##   I  FAMILIAR_ROSE — primary standard-playable; uses COMPETITIVE_SELF_LIMITED contract
##   II FIRST_BLOOM — Ascendant revelation; bounded deterministic competitive effects
##   III EVERLASTING_ORIGIN — Story + opted-in Mythic Party only; NEVER invincible ranked
## COMPETITIVE_SELF_LIMITED is NOT a fourth story form — it is Familiar Rose's gameplay contract.
## Final art / balance / cinematics / V1: NOT approved.

const SCHEMA := "pink_bloom_systems/v2"
const FIGHTER_ID := "rosamere"
const Selection = preload("res://scripts/combat/rosamere_form_selection.gd")

const SYSTEM_IDS := [
	"FirstPermission",
	"BloomSeed",
	"PetalConstellation",
	"OriginationScript",
	"FirstDawn",
	"GentleReversal",
	"QuietEmbrace",
]

const SUPER_IDS := [
	"a_world_in_bloom",
	"before_there_was_time",
	"the_first_permission",
	"mythic_everything_again",
]

const FORM_COMPETITIVE := "COMPETITIVE_SELF_LIMITED"
const FORM_FAMILIAR := "FAMILIAR_ROSE"
const FORM_FIRST_BLOOM := "FIRST_BLOOM"
const FORM_EVERLASTING := "EVERLASTING_ORIGIN"

const STORY_FORMS := [FORM_FAMILIAR, FORM_FIRST_BLOOM, FORM_EVERLASTING]

var epoch: int = 0
var frame: int = 0
var next_event_seq: int = 1
## Active story manifestation (one of three). Never COMPETITIVE_SELF_LIMITED.
var form_id: String = FORM_FAMILIAR
## Gameplay contract ID. COMPETITIVE_SELF_LIMITED attaches to Familiar Rose.
var gameplay_contract_id: String = FORM_COMPETITIVE
var active_effects: Array = []
var retired_event_ids: Array = []
var origination_script_level: int = 0
var petal_constellation_charges: int = 0


func reset(p_epoch: int = 1) -> void:
	epoch = p_epoch
	frame = 0
	next_event_seq = 1
	form_id = FORM_FAMILIAR
	gameplay_contract_id = FORM_COMPETITIVE
	active_effects.clear()
	retired_event_ids.clear()
	origination_script_level = 0
	petal_constellation_charges = 0


func capture() -> Dictionary:
	return {
		"schema": SCHEMA,
		"fighter_id": FIGHTER_ID,
		"epoch": epoch,
		"frame": frame,
		"next_event_seq": next_event_seq,
		"form_id": form_id,
		"story_form_id": form_id,
		"gameplay_contract_id": gameplay_contract_id,
		"active_effects": active_effects.duplicate(true),
		"retired_event_ids": retired_event_ids.duplicate(true),
		"origination_script_level": origination_script_level,
		"petal_constellation_charges": petal_constellation_charges,
		"ranked_invincible": false,
		"everlasting_ranked_forbidden": true,
		"three_form_canon": true,
		"manifestation_count": 3,
	}


func restore(record: Dictionary) -> bool:
	var schema := str(record.get("schema", ""))
	if schema != SCHEMA and schema != "pink_bloom_systems/v1":
		return false
	if str(record.get("fighter_id", "")) != FIGHTER_ID:
		return false
	if bool(record.get("ranked_invincible", false)):
		return false
	epoch = int(record.get("epoch", 0))
	frame = int(record.get("frame", 0))
	next_event_seq = int(record.get("next_event_seq", 1))
	var raw_form := str(record.get("form_id", FORM_FAMILIAR))
	var norm: Dictionary = Selection.normalize_selection(raw_form)
	if not bool(norm.get("ok", false)):
		return false
	form_id = str(norm.get("form_id", FORM_FAMILIAR))
	gameplay_contract_id = str(record.get("gameplay_contract_id", norm.get("gameplay_contract_id", FORM_COMPETITIVE)))
	if form_id == FORM_FAMILIAR:
		gameplay_contract_id = FORM_COMPETITIVE
	active_effects = record.get("active_effects", []).duplicate(true)
	retired_event_ids = record.get("retired_event_ids", []).duplicate(true)
	origination_script_level = int(record.get("origination_script_level", 0))
	petal_constellation_charges = int(record.get("petal_constellation_charges", 0))
	return true


func set_form(p_form: String, mythic_consent: bool = false) -> Dictionary:
	## Accepts story form IDs or COMPETITIVE_SELF_LIMITED (maps onto Familiar Rose).
	var norm: Dictionary = Selection.normalize_selection(p_form)
	if not bool(norm.get("ok", false)):
		return _fail("unknown_form")
	var resolved := str(norm.get("form_id", FORM_FAMILIAR))
	if resolved == FORM_EVERLASTING and not mythic_consent:
		return _fail("everlasting_requires_mythic_consent")
	form_id = resolved
	gameplay_contract_id = str(norm.get("gameplay_contract_id", ""))
	if form_id == FORM_FAMILIAR:
		gameplay_contract_id = FORM_COMPETITIVE
	return {
		"ok": true,
		"form_id": form_id,
		"story_form_id": form_id,
		"gameplay_contract_id": gameplay_contract_id,
		"can_lose": competitive_can_lose(),
		"ranked_allowed": form_id != FORM_EVERLASTING,
		"fourth_form": false,
		"manifestation_count": 3,
	}


func story_forms() -> Array:
	return STORY_FORMS.duplicate()


func advance_frame() -> Array:
	frame += 1
	var retired: Array = []
	var keep: Array = []
	for effect in active_effects:
		if int(effect.get("expires_frame", -1)) <= frame:
			retired.append(str(effect.get("event_id", "")))
			retired_event_ids.append(str(effect.get("event_id", "")))
		else:
			keep.append(effect)
	active_effects = keep
	return retired


func activate(system_id: String, owner_slot: int, payload: Dictionary = {}) -> Dictionary:
	if system_id not in SYSTEM_IDS and system_id not in SUPER_IDS:
		return _fail("unknown_system")
	if system_id == "mythic_everything_again" and form_id != FORM_EVERLASTING:
		return _fail("mythic_requires_everlasting_form")
	if form_id == FORM_FAMILIAR or gameplay_contract_id == FORM_COMPETITIVE:
		# Self-limited competitive path — no omnipotent overrides.
		if bool(payload.get("omnipotent", false)):
			return _fail("competitive_rejects_omnipotence")
	var duration := int(payload.get("duration_frames", _default_duration(system_id)))
	var event_id := "pink:%d:%d:%d:%d:%s" % [epoch, frame, owner_slot, next_event_seq, system_id]
	next_event_seq += 1
	var effect := {
		"event_id": event_id,
		"system_id": system_id,
		"owner_slot": owner_slot,
		"spawn_frame": frame,
		"expires_frame": frame + max(1, duration),
		"payload": payload.duplicate(true),
		"deterministic": true,
		"form_id": form_id,
		"gameplay_contract_id": gameplay_contract_id,
	}
	active_effects.append(effect)
	match system_id:
		"OriginationScript":
			origination_script_level = mini(3, origination_script_level + 1)
		"PetalConstellation":
			petal_constellation_charges = mini(6, petal_constellation_charges + 1)
		"BloomSeed":
			effect["payload"]["seed_id"] = event_id
		"FirstPermission":
			effect["payload"]["agency_window"] = true
	return {"ok": true, "effect": effect}


func cancel(event_id: String) -> bool:
	var found := false
	var keep: Array = []
	for effect in active_effects:
		if str(effect.get("event_id", "")) == event_id:
			found = true
			retired_event_ids.append(event_id)
		else:
			keep.append(effect)
	active_effects = keep
	return found


func has_active(system_id: String) -> bool:
	for effect in active_effects:
		if str(effect.get("system_id", "")) == system_id:
			return true
	return false


func active_event_ids() -> Array:
	var ids: Array = []
	for effect in active_effects:
		ids.append(str(effect.get("event_id", "")))
	return ids


func competitive_can_lose() -> bool:
	## Familiar Rose (competitive contract) and First Bloom can lose.
	## Everlasting Origin is story/mythic — not a ranked invincible win condition.
	return form_id != FORM_EVERLASTING


func _default_duration(system_id: String) -> int:
	match system_id:
		"FirstPermission":
			return 90
		"BloomSeed":
			return 120
		"PetalConstellation":
			return 45
		"OriginationScript":
			return 60
		"FirstDawn":
			return 30
		"GentleReversal":
			return 24
		"QuietEmbrace":
			return 40
		"a_world_in_bloom":
			return 96
		"before_there_was_time":
			return 72
		"the_first_permission":
			return 108
		"mythic_everything_again":
			return 180
		_:
			return 30


func _fail(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
