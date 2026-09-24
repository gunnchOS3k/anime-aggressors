extends SceneTree

## Headless generated-production-art asserts. Never sets HUMAN_* or MERGE.

const _Resolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const _Provenance = preload("res://scripts/visual/animation_provenance.gd")

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

var _failures: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error("GPA_FAIL: " + msg)


func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail(msg)
	else:
		print("GPA_OK: ", msg)


func _run() -> void:
	for fid in FIGHTERS:
		var anim := "res://content/fighters/%s/animations/generated_production/heavy.anim.json" % fid
		_ok(FileAccess.file_exists(anim), "%s generated heavy clip" % fid)
		var model := _Resolver.generated_glb_path(fid)
		_ok(FileAccess.file_exists(model) or ResourceLoader.exists(model), "%s generated model present or pending import" % fid)
		_ok(_Provenance.status_for(fid, "heavy") in [_Provenance.GENERATED_PRODUCTION, _Provenance.PROCEDURAL_FALLBACK], "%s provenance legal" % fid)
	_ok(FileAccess.file_exists("res://data/vfx/generated_production/clash_presets.json"), "clash vfx presets")
	_ok(FileAccess.file_exists("res://assets/audio/generated_production/shared/hit_heavy.wav"), "generated heavy hit audio")
	_ok(_Provenance.automation_may_write(_Provenance.GENERATED_PRODUCTION), "automation may write generated label")
	_ok(not _Provenance.automation_may_write(_Provenance.AUTHORED_APPROVED), "automation may not write authored approved")
	if _failures.is_empty():
		print("GPA_PASS")
		quit(0)
	else:
		print("GPA_FAIL count=", _failures.size())
		quit(1)
