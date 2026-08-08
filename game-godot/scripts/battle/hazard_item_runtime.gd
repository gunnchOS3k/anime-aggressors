extends Node
class_name HazardItemRuntime

## Items / stage-hazards mode runtime (Alpha depth).
## Spawns timed hazard pulses + pickup items that modify aura/damage.

signal hazard_tick(info: Dictionary)
signal item_collected(slot: int, item_id: String)

var enabled: bool = false
var items_enabled: bool = true
var hazards_enabled: bool = true
var _elapsed: float = 0.0
var _spawn_timer: float = 0.0
var _hazard_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _fighters: Array = []
var _active_items: Array = []  # [{id, x, ttl, node}]
var _hazard_pulse: float = 0.0
var stage_root: Node2D
var host: Node2D

const ITEM_TABLE: Array[Dictionary] = [
	{"id": "aura_shard", "effect": "aura", "amount": 25.0},
	{"id": "vital_orb", "effect": "heal_pct", "amount": 12.0},
	{"id": "surge_capsule", "effect": "damage_buff", "amount": 1.15, "ttl": 6.0},
]


func configure(battle_host: Node2D, fighters: Array, seed_value: int, stage: Node2D) -> void:
	host = battle_host
	stage_root = stage
	_fighters = fighters
	_rng.seed = seed_value if seed_value != 0 else 41
	enabled = true
	_elapsed = 0.0
	_spawn_timer = 2.5
	_hazard_timer = 4.0
	_active_items.clear()


func tick(delta: float) -> void:
	if not enabled:
		return
	_elapsed += delta
	if hazards_enabled:
		_hazard_timer -= delta
		if _hazard_timer <= 0.0:
			_hazard_timer = 5.5 + _rng.randf_range(-0.5, 1.0)
			_pulse_hazard()
		if _hazard_pulse > 0.0:
			_hazard_pulse = maxf(0.0, _hazard_pulse - delta)
	if items_enabled:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = 7.0 + _rng.randf_range(-1.0, 2.0)
			_spawn_item()
		_tick_items(delta)


func _pulse_hazard() -> void:
	_hazard_pulse = 1.25
	# Center-lane hazard: damages fighters near x=0 while pulse active.
	var info := {"type": "lane_surge", "x": 0.0, "radius": 70.0, "damage": 4.5}
	for f in _fighters:
		if f == null:
			continue
		if absf(float(f.global_position.x)) <= 70.0:
			f.damage_percent = float(f.damage_percent) + 4.5
			if f.has_method("stamp_runtime_hook"):
				f.stamp_runtime_hook("hazard_hit")
	hazard_tick.emit(info)
	_flash_hazard_band()


func _flash_hazard_band() -> void:
	if stage_root == null:
		return
	var band := ColorRect.new()
	band.color = Color(0.95, 0.35, 0.2, 0.35)
	band.size = Vector2(140, 320)
	band.position = Vector2(-70, -40)
	band.z_index = -1
	stage_root.add_child(band)
	var tw := stage_root.create_tween()
	tw.tween_property(band, "modulate:a", 0.0, 1.1)
	tw.finished.connect(band.queue_free)


func _spawn_item() -> void:
	if stage_root == null:
		return
	var def: Dictionary = ITEM_TABLE[_rng.randi_range(0, ITEM_TABLE.size() - 1)]
	var x: float = _rng.randf_range(-220.0, 220.0)
	var node := ColorRect.new()
	node.size = Vector2(22, 22)
	node.position = Vector2(x - 11.0, 150.0)
	node.color = Color(0.95, 0.85, 0.25, 0.9)
	stage_root.add_child(node)
	_active_items.append({
		"id": def.get("id", "item"),
		"def": def,
		"x": x,
		"ttl": 10.0,
		"node": node,
	})


func _tick_items(delta: float) -> void:
	var remain: Array = []
	for item in _active_items:
		item["ttl"] = float(item.get("ttl", 0.0)) - delta
		var collected := false
		for f in _fighters:
			if f == null:
				continue
			if absf(float(f.global_position.x) - float(item.get("x", 0.0))) < 28.0 and absf(float(f.global_position.y) - 160.0) < 80.0:
				_apply_item(f, item.get("def", {}))
				item_collected.emit(int(f.slot) if "slot" in f else 0, str(item.get("id", "")))
				collected = true
				break
		if collected or float(item.get("ttl", 0.0)) <= 0.0:
			var n = item.get("node", null)
			if n != null and is_instance_valid(n):
				n.queue_free()
		else:
			remain.append(item)
	_active_items = remain


func _apply_item(fighter: Node, def: Dictionary) -> void:
	match str(def.get("effect", "")):
		"aura":
			fighter.aura = minf(100.0, float(fighter.aura) + float(def.get("amount", 20.0)))
		"heal_pct":
			fighter.damage_percent = maxf(0.0, float(fighter.damage_percent) - float(def.get("amount", 10.0)))
		"damage_buff":
			# Short sticky buff via aura bump as Alpha proxy.
			fighter.aura = minf(100.0, float(fighter.aura) + 15.0)
	if fighter.has_method("stamp_runtime_hook"):
		fighter.stamp_runtime_hook("item_pickup")


func debug_summary() -> Dictionary:
	return {
		"enabled": enabled,
		"hazards_enabled": hazards_enabled,
		"items_enabled": items_enabled,
		"active_items": _active_items.size(),
		"elapsed": _elapsed,
		"hazard_pulse": _hazard_pulse,
		"mode": "hazards",
		"alpha_claim": "NOT_ALPHA_EXIT — hazards/items mode scaffold",
	}
