extends TextureRect
class_name FighterCardPortrait
## Wave020 isolation: bake immutable textures per fighter+context; never share live SubViewports.

const MODEL_SCRIPT = preload("res://scripts/fighters/fighter_model_3d.gd")
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const _PresentationContext = preload("res://scripts/visual/presentation_context.gd")
const _PresentationCache = preload("res://scripts/visual/fighter_presentation_cache.gd")

static var _baking: Dictionary = {} # cache_key -> generation

var fighter_id: String = ""
var _portrait_context: String = _PresentationContext.CTX_SELECT_CARD
var focused: bool = false
var _accent: Color = Color(1, 0.85, 0.3)
var _bake_generation: int = 0


func configure(id: String, _primary_color: Color, accent_color: Color) -> void:
	configure_for_context(id, _primary_color, accent_color, _PresentationContext.CTX_SELECT_CARD)


func configure_for_context(id: String, _primary_color: Color, accent_color: Color, context: String) -> void:
	fighter_id = id
	_portrait_context = _PresentationContext.normalize_context(context)
	_accent = accent_color
	_bake_generation += 1
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_cached_or_bake()


func set_focused(value: bool) -> void:
	focused = value
	modulate = Color(1.12, 1.12, 1.18, 1.0) if focused else Color(1, 1, 1, 1)
	queue_redraw()


func _apply_cached_or_bake() -> void:
	var key := _PresentationContext.cache_key(fighter_id, _portrait_context)
	var cached: Texture2D = _PresentationCache.get_texture(key)
	if cached != null:
		texture = cached
		return
	call_deferred("_bake_portrait")


func _bake_portrait() -> void:
	if fighter_id.is_empty():
		return
	var key := _PresentationContext.cache_key(fighter_id, _portrait_context)
	var gen := _bake_generation
	var cached: Texture2D = _PresentationCache.get_texture(key)
	if cached != null:
		texture = cached
		return
	if bool(_baking.get(key, false)):
		return
	_baking[key] = true
	var presentation: Dictionary = _AssetResolver.resolve_presentation(
		fighter_id, _PresentationContext.resolver_context(_portrait_context)
	)
	if not bool(presentation.get("is_current_canonical", false)):
		_AssetResolver.PLAYER_VISIBLE_LEGACY_CARD_OCCURRENCES += 1
	var host := Node2D.new()
	host.name = "CardBakeHost_%s_%s" % [fighter_id, _portrait_context]
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		_baking[key] = false
		return
	tree.root.add_child(host)
	var model: Node2D = MODEL_SCRIPT.new()
	model.name = "BakeModel"
	host.add_child(model)
	var gs = tree.root.get_node_or_null("/root/GameState")
	var data: Dictionary = {}
	if gs != null and gs.has_method("load_fighter"):
		data = gs.load_fighter(fighter_id)
	else:
		data = {"id": fighter_id}
	if model.has_method("set_presentation_context"):
		model.set_presentation_context(_portrait_context)
	elif model.has_method("set_select_mode"):
		model.set_select_mode(_portrait_context == _PresentationContext.CTX_SELECT_CARD or _portrait_context == _PresentationContext.CTX_SELECT_PREVIEW)
	if model.has_method("configure"):
		model.configure(data)
	await tree.process_frame
	await tree.process_frame
	if gen != _bake_generation:
		host.queue_free()
		_baking[key] = false
		return
	var img: Image = null
	if model.has_method("capture_portrait_image"):
		img = model.capture_portrait_image()
	if img != null and img.get_width() > 0:
		var tex := ImageTexture.create_from_image(img)
		_PresentationCache.put_texture(key, tex, gen)
		if is_instance_valid(self) and gen == _bake_generation:
			texture = tex
	else:
		_AssetResolver.CANONICAL_MODEL_LOAD_FAILURES += 1
	host.queue_free()
	_baking[key] = false


func _draw() -> void:
	if focused:
		var w := size.x
		var h := size.y
		draw_arc(Vector2(w * 0.5, h * 0.45), minf(w, h) * 0.42, 0.0, TAU, 28, _accent, 2.0)
