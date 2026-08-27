extends SceneTree

const _AuraTierContract = preload("res://scripts/combat/aura_tier_contract.gd")
const OUT_PATHS := [
	"res://../artifacts/engineering_wave021/AURA_TIER_RESULT.json",
	"../artifacts/engineering_wave021/AURA_TIER_RESULT.json",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := 0
	var cases := [
		[0.0, 0],
		[24.0, 0],
		[25.0, 1],
		[50.0, 2],
		[75.0, 3],
		[100.0, 3],
	]
	for c in cases:
		if _AuraTierContract.tier_from_aura(float(c[0])) != int(c[1]):
			failures += 1
	if not _AuraTierContract.can_initiate_transform(75.0):
		failures += 1
	if _AuraTierContract.can_initiate_transform(50.0):
		failures += 1
	for fid in ["ember-vale", "rook-ironside", "juno-spark"]:
		var prof := _AuraTierContract.audio_escalation_profile(fid, 3)
		if not bool(prof.get("royalty_safe", false)):
			failures += 1
	var ok := failures == 0
	var payload := {
		"ok": ok,
		"OWNER_REG_023": "PASS" if ok else "FAIL",
		"AURA_TIER_FAILURES": failures,
		"TIER_NAMES": _AuraTierContract.TIER_NAMES,
		"emitted_at": Time.get_datetime_string_from_system(true),
	}
	_write(payload)
	print("AURA_TIER ok=", ok)
	quit(0 if ok else 1)


func _write(payload: Dictionary) -> void:
	var text := JSON.stringify(payload, "\t")
	for p in OUT_PATHS:
		var abs_path := ProjectSettings.globalize_path(p) if str(p).begins_with("res://") else str(p)
		if not abs_path.is_absolute_path():
			abs_path = ProjectSettings.globalize_path("res://../") + abs_path.trim_prefix("../")
		DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		var f := FileAccess.open(abs_path, FileAccess.WRITE)
		if f:
			f.store_string(text)
			f.close()
