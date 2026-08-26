extends RefCounted
class_name FighterPresentationCache

## Tracks live presentation instances — no cross-context reuse of mutable nodes.

const _PC = preload("res://scripts/visual/presentation_context.gd")

static var _live_instances: Dictionary = {} # owner_key -> {context, fighter_id, generation, node_id}
static var _texture_cache: Dictionary = {} # cache_key -> ImageTexture (immutable bakes only)
static var _bake_generations: Dictionary = {} # cache_key -> int
static var _cross_context_violations: int = 0
static var _stale_reuse_violations: int = 0


static func owner_key(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return ""
	return "%s:%d" % [node.get_path(), node.get_instance_id()]


static func register_live(owner: Node, context: String, fighter_id: String, generation: int) -> void:
	var key := owner_key(owner)
	if key.is_empty():
		return
	var ctx := _PC.normalize_context(context)
	if _live_instances.has(key):
		var prev: Dictionary = _live_instances[key]
		if str(prev.get("context", "")) != ctx and str(prev.get("fighter_id", "")) == fighter_id:
			_cross_context_violations += 1
	_live_instances[key] = {
		"context": ctx,
		"fighter_id": fighter_id,
		"generation": generation,
		"node_id": owner.get_instance_id(),
	}


static func release_live(owner: Node) -> void:
	var key := owner_key(owner)
	if key.is_empty():
		return
	_live_instances.erase(key)


static func get_texture(cache_key: String) -> Texture2D:
	return _texture_cache.get(cache_key, null)


static func put_texture(cache_key: String, tex: Texture2D, generation: int) -> void:
	var prev_gen: int = int(_bake_generations.get(cache_key, -1))
	if prev_gen > generation:
		_stale_reuse_violations += 1
		return
	_bake_generations[cache_key] = generation
	_texture_cache[cache_key] = tex


static func invalidate_texture(cache_key: String) -> void:
	_texture_cache.erase(cache_key)
	_bake_generations.erase(cache_key)


static func telemetry() -> Dictionary:
	return {
		"LIVE_INSTANCE_COUNT": _live_instances.size(),
		"TEXTURE_CACHE_COUNT": _texture_cache.size(),
		"CROSS_CONTEXT_VIOLATIONS": _cross_context_violations,
		"STALE_REUSE_VIOLATIONS": _stale_reuse_violations,
		"live_instances": _live_instances.duplicate(true),
	}
