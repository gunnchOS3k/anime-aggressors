extends RefCounted
class_name ProceduralAudioBank

## Path A synthesized audio loader — uses existing procedural WAV bank (no second asset system).

const SHARED_ROOT := "res://assets/audio/procedural/shared"
const FIGHTER_ROOT := "res://assets/audio/procedural/fighters"
const STAGE_ROOT := "res://assets/audio/procedural/stages"

const SHARED_CATS: Array[String] = [
	"hit", "move", "charge", "projectile", "defense", "ko",
	"ui_confirm", "ui_back", "ui_select",
]

static var _cache: Dictionary = {}
static var _players_root: Node = null


static func ensure_bus_player(host: Node = null) -> Node:
	if _players_root != null and is_instance_valid(_players_root):
		return _players_root
	var tree := Engine.get_main_loop() as SceneTree
	var parent: Node = host
	if parent == null and tree != null:
		parent = tree.root
	if parent == null:
		return null
	var existing := parent.get_node_or_null("ProceduralAudioPlayers")
	if existing != null:
		_players_root = existing
		return _players_root
	var n := Node.new()
	n.name = "ProceduralAudioPlayers"
	parent.add_child(n)
	_players_root = n
	return _players_root


static func load_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return null
	var stream: AudioStream = null
	# Prefer imported AudioStreamWAV after a clean `godot --import`.
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	# Fallback when .import remaps exist but .godot/imported/*.sample is absent.
	if stream == null and FileAccess.file_exists(path):
		stream = AudioStreamWAV.load_from_file(path) as AudioStream
	if stream == null:
		return null
	_cache[path] = stream
	return stream


static func shared_path(category: String) -> String:
	return "%s/%s.wav" % [SHARED_ROOT, category]


static func fighter_path(fighter_id: String, category: String) -> String:
	return "%s/%s/%s.wav" % [FIGHTER_ROOT, fighter_id, category]


static func stage_bed_path(stage_id: String) -> String:
	return "%s/%s/bed.wav" % [STAGE_ROOT, stage_id]


static func play(path: String, host: Node = null, volume_db: float = 0.0) -> Dictionary:
	var stream := load_stream(path)
	if stream == null:
		return {"ok": false, "path": path, "error": "missing_stream"}
	var root := ensure_bus_player(host)
	if root == null or not root.is_inside_tree():
		return {"ok": true, "path": path, "playing": false, "loaded": true, "deferred": true}
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	root.add_child(player)
	if not player.is_inside_tree():
		player.queue_free()
		return {"ok": true, "path": path, "playing": false, "loaded": true, "deferred": true}
	player.finished.connect(player.queue_free)
	player.play()
	return {"ok": true, "path": path, "playing": true}


static func play_shared(category: String, host: Node = null) -> Dictionary:
	return play(shared_path(category), host)


static func play_fighter(fighter_id: String, category: String, host: Node = null) -> Dictionary:
	var path := fighter_path(fighter_id, category)
	var result := play(path, host)
	if bool(result.get("ok", false)):
		return result
	return play_shared(category, host)


static func play_stage_bed(stage_id: String, host: Node = null) -> Dictionary:
	return play(stage_bed_path(stage_id), host, -8.0)


static func map_sfx_event_to_category(sfx_event: String) -> String:
	var e := sfx_event.to_lower()
	if e.contains("proj"):
		return "projectile"
	if e.contains("heavy") or e.contains("burst") or e.contains("charge"):
		return "charge"
	if e.contains("dair") or e.contains("defense") or e.contains("shield"):
		return "defense"
	if e.contains("ko") or e.contains("throw"):
		return "ko"
	if e.contains("move") or e.contains("jab") or e.contains("dash"):
		return "move"
	return "hit"


static func preload_launch_bank() -> Dictionary:
	var loaded := 0
	var missing: Array = []
	for cat in SHARED_CATS:
		var p := shared_path(cat)
		if load_stream(p) != null:
			loaded += 1
		else:
			missing.append(p)
	for fid in [
		"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
		"nix-calder", "orion-vell", "vesper-nyx",
	]:
		for cat in ["hit", "move", "charge", "projectile", "defense", "ko"]:
			var p := fighter_path(fid, cat)
			if load_stream(p) != null:
				loaded += 1
			else:
				missing.append(p)
	for sid in [
		"skyline-arena", "neon-rooftops", "cascade-foundry",
		"void-pier", "ember-courtyard", "training-grid",
	]:
		var p := stage_bed_path(sid)
		if load_stream(p) != null:
			loaded += 1
		else:
			missing.append(p)
	return {
		"ok": missing.is_empty(),
		"loaded": loaded,
		"missing": missing,
		"cache_size": _cache.size(),
	}


static func self_test() -> Dictionary:
	_cache.clear()
	var bank: Dictionary = preload_launch_bank()
	var hit := load_stream(shared_path("hit"))
	var bed := load_stream(stage_bed_path("skyline-arena"))
	var fighter := load_stream(fighter_path("ember-vale", "hit"))
	return {
		"ok": bool(bank.get("ok", false)) and hit != null and bed != null and fighter != null,
		"bank": bank,
		"hit_ok": hit != null,
		"bed_ok": bed != null,
		"fighter_ok": fighter != null,
	}
