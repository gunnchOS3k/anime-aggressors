extends RefCounted
class_name SmokeWaveDAlpha

## Wave D Alpha depth smoke: aura identity, stages, arcade scripts, batch harness, CPU observe.
## Avoids GameState autoload — Godot 4.5 `-s` compiles suites before reliable autoload use.

const _AuraIdentity = preload("res://scripts/combat/aura_identity.gd")
const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")
const _BatchMatchHarness = preload("res://scripts/battle/batch_match_harness.gd")
const _CpuController = preload("res://scripts/fighters/cpu_controller.gd")
const _SmokeAssert = preload("res://tests/smoke_assert.gd")

const FIGHTERS: Array[String] = [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

const NEW_STAGES: Array[String] = [
	"cascade-foundry", "void-pier", "ember-courtyard",
]


static func run() -> bool:
	_SmokeAssert.reset()

	# 7 aura identity profiles in combat scripts.
	var ids: Array = _AuraIdentity.all_fighter_ids()
	_SmokeAssert.ok(ids.size() >= 7, "aura identity must cover 7 fighters, got %d" % ids.size())
	var tags := {}
	for fid in FIGHTERS:
		var p: Dictionary = _AuraIdentity.profile_for(fid)
		var tag: String = str(p.get("tag", ""))
		_SmokeAssert.ok(tag != "", "%s missing tag" % fid)
		_SmokeAssert.ok(not tags.has(tag), "duplicate aura tag %s" % tag)
		tags[tag] = fid
		var base_move := {
			"move_id": "heavy_attack",
			"move_type": "heavy",
			"damage": 10.0,
			"angle_deg": 45.0,
			"hitboxes": [{"width": 40, "height": 32}],
			"input_command": "attack_heavy",
		}
		var scaled: Dictionary = _AuraIdentity.apply_to_scaled_move(base_move, fid, 80.0, tag)
		_SmokeAssert.ok(scaled.has("aura_identity_tag"), "%s scaled move missing identity tag" % fid)
		_SmokeAssert.ok(_AuraIdentity.charge_rate_mult(fid) > 0.0, "%s charge mult > 0" % fid)

	# Distinct charge rates across roster (not all identical).
	var unique_rates := {}
	for fid in FIGHTERS:
		unique_rates[str(_AuraIdentity.charge_rate_mult(fid))] = true
	_SmokeAssert.ok(unique_rates.size() >= 4, "expected diverse aura charge rates, got %d" % unique_rates.size())

	# Stages: 6 production (5 competitive + training).
	var prod_path := "res://data/stages/production_stages.json"
	_SmokeAssert.ok(FileAccess.file_exists(prod_path), "production_stages.json missing")
	var f := FileAccess.open(prod_path, FileAccess.READ)
	var prod: Dictionary = JSON.parse_string(f.get_as_text())
	var stages: Array = prod.get("stages", [])
	_SmokeAssert.ok(stages.size() >= 6, "need >=6 stages toward launch, got %d" % stages.size())
	for sid in NEW_STAGES:
		_SmokeAssert.ok(stages.has(sid), "production list missing %s" % sid)
		var sp := "res://data/stages/%s.json" % sid
		_SmokeAssert.ok(FileAccess.file_exists(sp), "stage file missing %s" % sid)
		var sf := FileAccess.open(sp, FileAccess.READ)
		var sd: Dictionary = JSON.parse_string(sf.get_as_text())
		_SmokeAssert.ok(str(sd.get("artStatus", "")) == "PROCEDURAL_FINAL", "%s must mark PROCEDURAL_FINAL art" % sid)

	# Arcade ladder wired in scripts + scene (no autoload).
	_SmokeAssert.ok(ResourceLoader.exists("res://scenes/menus/ArcadeScene.tscn"), "ArcadeScene missing")
	_SmokeAssert.ok(FileAccess.file_exists("res://scripts/menus/arcade_scene.gd"), "arcade_scene.gd missing")
	var gs := FileAccess.open("res://scripts/core/GameState.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(gs.contains("begin_arcade"), "GameState begin_arcade missing")
	_SmokeAssert.ok(gs.contains("ARCADE_LADDER"), "GameState ARCADE_LADDER missing")
	for fid in FIGHTERS:
		_SmokeAssert.ok(gs.contains('"%s"' % fid) or gs.contains("'%s'" % fid), "arcade ladder should reference %s" % fid)
	var mode_src := FileAccess.open("res://scripts/menus/mode_select_scene.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(mode_src.contains("_on_arcade_pressed"), "mode select arcade hook missing")
	var router := FileAccess.open("res://scripts/core/SceneRouter.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(router.contains('"arcade"'), "SceneRouter arcade route missing")

	# CPU: no hidden-state aura forge; observe API present; tiers 1–5.
	var _cpu = _CpuController.new()
	_SmokeAssert.ok(_cpu != null, "CpuController constructible")
	var cpu_src := FileAccess.open("res://scripts/fighters/cpu_controller.gd", FileAccess.READ).get_as_text()
	_SmokeAssert.ok(not cpu_src.contains("_fighter.aura = 100"), "CPU must not forge aura=100")
	_SmokeAssert.ok(cpu_src.contains("func observe"), "CPU observation model required")
	_SmokeAssert.ok(cpu_src.contains("level >= 5") or cpu_src.contains("clampi(cpu_level, 1, 5)"), "CPU tier 5 expected")

	# Batch harness deterministic.
	_SmokeAssert.ok(_BatchMatchHarness.assert_deterministic(7, 48, 11), "batch harness must be deterministic")
	var batch: Dictionary = _BatchMatchHarness.run_batch(14, 40, 99)
	_SmokeAssert.ok(int(batch.get("match_count", 0)) == 14, "batch match_count")
	_SmokeAssert.ok(str(batch.get("alpha_claim", "")).contains("NOT_ALPHA_EXIT"), "must not claim Alpha exit")
	_SmokeAssert.ok(int(batch.get("aura_profiles", 0)) >= 7, "batch reports aura profiles")

	# Aura scaler still present for YAML scaling path.
	_SmokeAssert.ok(_AuraScaler.aura_level(100.0) == 4, "aura level 4 at 100")

	return _SmokeAssert.passed()
