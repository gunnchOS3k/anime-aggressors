extends SceneTree

const _AudioBank = preload("res://scripts/audio/procedural_audio_bank.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave020/ELEMENTAL_AUDIO_RUNTIME_RESULT.json",
	"../artifacts/engineering_wave020/ELEMENTAL_AUDIO_RUNTIME_RESULT.json",
]

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const ELEMENTS := {
	"ember-vale": "fire",
	"rook-ironside": "earth",
	"juno-spark": "electric",
	"kaia-windrow": "wind",
	"nix-calder": "frost",
	"orion-vell": "gravity",
	"vesper-nyx": "shadow",
}
const KEY_CATS := ["charge", "projectile", "signature"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var collisions := 0
	var generic_overuse := 0
	var fighters_ok := 0
	var desktop_pass := true
	var hashes: Dictionary = {}

	for fid in FIGHTERS:
		var ok_f := true
		for cat in KEY_CATS:
			var path := _AudioBank.fighter_path(fid, cat)
			var stream := _AudioBank.load_stream(path)
			if stream == null:
				ok_f = false
				generic_overuse += 1
				continue
			var key := "%s:%s" % [cat, path]
			if hashes.has(key):
				collisions += 1
			else:
				hashes[key] = fid
		if ok_f:
			fighters_ok += 1

	# Mapping checks
	if _AudioBank.map_sfx_event_to_category("flame_burst_sfx") != "signature":
		desktop_pass = false
	if _AudioBank.map_sfx_event_to_category("frost_proj_sfx") != "projectile":
		desktop_pass = false
	if _AudioBank.map_sfx_event_to_category("aura_charge_sfx") != "charge":
		desktop_pass = false

	var payload := {
		"ok": fighters_ok == 7 and collisions == 0 and generic_overuse == 0 and desktop_pass,
		"FIGHTERS_WITH_ELEMENTAL_AUDIO": fighters_ok,
		"GENERIC_AUDIO_OVERUSE_CASES": generic_overuse,
		"AUDIO_IDENTITY_COLLISIONS": collisions,
		"DESKTOP_AUDIO_RUNTIME_PASS": desktop_pass and fighters_ok == 7,
		"PIXEL_AUDIO_RUNTIME_PASS": null,
		"fighter_elements": ELEMENTS,
	}
	_write(payload)
	_finish(payload.ok, payload, 0 if payload.ok else 1)


func _write(payload: Dictionary) -> void:
	for rel in OUT_PATHS:
		var f := FileAccess.open(rel, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(payload, "\t") + "\n")
			f.close()
			return


func _finish(_ok: bool, payload: Dictionary, code: int) -> void:
	payload["emitted_at"] = Time.get_datetime_string_from_system(true)
	_write(payload)
	print(JSON.stringify(payload))
	quit(code)
