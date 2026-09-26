extends RefCounted
class_name MoveExecutionHarness

## Executes every required move row through MoveRunner and content resolvers.

const _Catalog = preload("res://scripts/combat/move_content_catalog.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _MoveRunner = preload("res://scripts/combat/move_runner.gd")
const _ThrowResolver = preload("res://scripts/combat/throw_resolver.gd")
const _Vfx = preload("res://scripts/visual/move_vfx_director.gd")
const _Sfx = preload("res://scripts/audio/combat_sfx_resolver.gd")
const _Particles = preload("res://scripts/visual/elemental_particle_library.gd")
const _MoveResolver = preload("res://scripts/visual/runtime_move_resolver.gd")

static func run() -> Dictionary:
	var exec_ok := 0
	var anim_ok := 0
	var vfx_ok := 0
	var part_ok := 0
	var sfx_ok := 0
	var throw_ok := 0
	var failures: Array = []
	var details: Array = []
	for fid in _Catalog.FIGHTERS:
		var manifest: Dictionary = _DataLoader.load_moves(fid)
		var loaded := _list_clips(fid)
		for mid in _Catalog.REQUIRED_MOVES:
			var move: Dictionary = _DataLoader.find_move(manifest, mid)
			var row := {
				"fighter_id": fid,
				"move_id": mid,
				"execution": false,
				"animation": false,
				"vfx": false,
				"particle": false,
				"sfx": false,
				"locked": false,
			}
			if move.is_empty():
				failures.append("%s:%s:missing_manifest" % [fid, mid])
				details.append(row)
				continue
			var runner = _MoveRunner.new()
			var dummy := Node2D.new()
			runner.start_move(move, dummy)
			var frames := int(move.get("startup_frames", 0)) + int(move.get("active_frames", 0)) + int(move.get("recovery_frames", 0))
			frames = maxi(frames, 1)
			for _i in range(frames + 2):
				runner.tick_sim_frame()
			var recovered: bool = not bool(runner.active)
			row["execution"] = recovered
			if recovered:
				exec_ok += 1
			else:
				row["locked"] = true
				failures.append("%s:%s:state_lock" % [fid, mid])
			dummy.queue_free()
			var clip := _MoveResolver.canonical_clip_for_move_id(mid)
			if loaded.has(clip) or loaded.has(mid):
				row["animation"] = true
				anim_ok += 1
			else:
				failures.append("%s:%s:missing_clip:%s" % [fid, mid, clip])
			var ev: Dictionary = _Vfx.event_for(fid, mid)
			if not ev.is_empty() and not bool(ev.get("palette_only", true)):
				row["vfx"] = true
				vfx_ok += 1
			else:
				failures.append("%s:%s:vfx" % [fid, mid])
			var prof: Dictionary = _Particles.profile(fid, mid)
			if not prof.is_empty() and not bool(prof.get("placeholder", true)):
				row["particle"] = true
				part_ok += 1
			else:
				failures.append("%s:%s:particle" % [fid, mid])
			var sfx_row: Dictionary = _Sfx.row_for(fid, mid)
			if not sfx_row.is_empty() and not bool(sfx_row.get("silent", true)):
				row["sfx"] = true
				sfx_ok += 1
			else:
				failures.append("%s:%s:sfx" % [fid, mid])
			if mid.begins_with("throw_"):
				var resolved: Dictionary = _ThrowResolver.resolve_throw(null, null, manifest, mid.replace("throw_", ""))
				if str(resolved.get("move_id", "")) == mid and bool(resolved.get("throw", {}).get("authored", false) or resolved.has("throw")):
					throw_ok += 1
			details.append(row)
	var total := _Catalog.required_total()
	return {
		"REQUIRED_MOVE_TOTAL": total,
		"MOVE_EXECUTION_PASS": "%d/%d" % [exec_ok, total],
		"MOVE_ANIMATION_PASS": "%d/%d" % [anim_ok, total],
		"MOVE_VFX_PASS": "%d/%d" % [vfx_ok, total],
		"MOVE_PARTICLE_PASS": "%d/%d" % [part_ok, total],
		"MOVE_SFX_PASS": "%d/%d" % [sfx_ok, total],
		"DIRECTIONAL_THROW_CONTENT": "%d/28" % throw_ok,
		"execution_ok": exec_ok == total,
		"animation_ok": anim_ok == total,
		"vfx_ok": vfx_ok == total,
		"particle_ok": part_ok == total,
		"sfx_ok": sfx_ok == total,
		"throw_ok": throw_ok == 28,
		"failures": failures,
		"details": details,
	}


static func _list_clips(fighter_id: String) -> Dictionary:
	var loaded := {}
	var root := "res://content/fighters/%s/animations/procedural" % fighter_id
	var abs_root := ProjectSettings.globalize_path(root)
	if not DirAccess.dir_exists_absolute(abs_root):
		return loaded
	var dir := DirAccess.open(abs_root)
	if dir == null:
		return loaded
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".anim.json"):
			loaded[file_name.replace(".anim.json", "")] = true
		file_name = dir.get_next()
	dir.list_dir_end()
	return loaded
