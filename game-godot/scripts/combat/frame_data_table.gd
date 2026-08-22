extends RefCounted
class_name FrameDataTable

## Derives competitive frame data from canonical move definitions (not a second engine).

const _DataLoader = preload("res://scripts/data/data_loader.gd")

const CORE_IDS := [
	"jab_1", "jab_2", "jab_finisher",
	"forward_tilt", "up_tilt", "down_tilt", "dash_attack", "heavy_attack",
	"neutral_air", "forward_air", "up_air", "down_air",
	"neutral_special_projectile", "side_special", "up_special_recovery", "down_special",
	"grab", "throw_forward", "throw_back", "throw_up", "throw_down",
	"aura_burst",
]


static func row_for_move(move: Dictionary) -> Dictionary:
	var startup: int = int(move.get("startup_frames", 0))
	var active_f: int = int(move.get("active_frames", 0))
	var recovery: int = int(move.get("recovery_frames", 0))
	return {
		"move_id": str(move.get("move_id", "")),
		"fighter_id": str(move.get("fighter_id", "")),
		"startup": startup,
		"active": active_f,
		"recovery": recovery,
		"total": startup + active_f + recovery,
		"damage": float(move.get("damage", 0.0)),
		"angle_deg": float(move.get("angle_deg", 0.0)),
		"base_knockback": float(move.get("base_knockback", 0.0)),
		"hitstop": int(move.get("hitstop_frames", 0)),
		"shield_stun": int(move.get("shield_stun_frames", 0)),
		"move_type": str(move.get("move_type", "")),
		"training_display_name": str(move.get("training_display_name", move.get("move_id", ""))),
	}


static func table_for_fighter(fighter_id: String) -> Array:
	var manifest: Dictionary = _DataLoader.load_moves(fighter_id)
	var out: Array = []
	for m in manifest.get("moves", []):
		if m is Dictionary:
			out.append(row_for_move(m))
	return out


static func core_complete(fighter_id: String) -> Dictionary:
	var manifest: Dictionary = _DataLoader.load_moves(fighter_id)
	var present: Array = []
	var missing: Array = []
	for mid in CORE_IDS:
		var mv: Dictionary = _DataLoader.find_move(manifest, mid)
		if mv.is_empty():
			missing.append(mid)
		else:
			present.append(mid)
	return {
		"fighter_id": fighter_id,
		"present": present.size(),
		"missing": missing,
		"ok": missing.is_empty(),
	}


static func roster_frame_integrity() -> Dictionary:
	var missing_any: Array = []
	var reports: Array = []
	for fid in _DataLoader.roster_ids():
		var r: Dictionary = core_complete(str(fid))
		reports.append(r)
		if not bool(r.get("ok", false)):
			missing_any.append(fid)
	return {
		"ok": missing_any.is_empty(),
		"missing_fighters": missing_any,
		"reports": reports,
		"derived_from": "game-godot/data/moves/*.json",
	}


static func overlay_line(move: Dictionary, runner: Node) -> String:
	var row: Dictionary = row_for_move(move)
	var phase := "—"
	var frame := 0
	if runner != null:
		phase = str(runner.phase) if "phase" in runner else "—"
		frame = int(runner.total_frame) if "total_frame" in runner else 0
	return "%s  s:%d a:%d r:%d  phase:%s f:%d" % [
		row.get("training_display_name", row.get("move_id", "?")),
		int(row.startup), int(row.active), int(row.recovery), phase, frame,
	]
