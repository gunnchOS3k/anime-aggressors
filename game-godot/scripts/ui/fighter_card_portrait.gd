extends TextureRect
class_name FighterCardPortrait
## Wave020 CP2: select-card art from canonical FighterModel3D (not stick silhouettes).
## Bakes once per fighter_id into a shared static cache to avoid 7 live SubViewports.

const MODEL_SCRIPT = preload("res://scripts/fighters/fighter_model_3d.gd")
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")

static var _cache: Dictionary = {} # fighter_id -> ImageTexture
static var _baking: Dictionary = {} # fighter_id -> bool

var fighter_id: String = ""
var focused: bool = false
var _accent: Color = Color(1, 0.85, 0.3)


func configure(id: String, _primary_color: Color, accent_color: Color) -> void:
	fighter_id = id
	_accent = accent_color
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_cached_or_bake()


func set_focused(value: bool) -> void:
	focused = value
	modulate = Color(1.12, 1.12, 1.18, 1.0) if focused else Color(1, 1, 1, 1)
	queue_redraw()


func _apply_cached_or_bake() -> void:
	if _cache.has(fighter_id):
		texture = _cache[fighter_id]
		return
	# Prefer deferred bake so tile layout exists.
	call_deferred("_bake_portrait")


func _bake_portrait() -> void:
	if fighter_id.is_empty():
		return
	if _cache.has(fighter_id):
		texture = _cache[fighter_id]
		return
	if bool(_baking.get(fighter_id, false)):
		return
	_baking[fighter_id] = true
	var presentation: Dictionary = _AssetResolver.resolve_presentation(
		fighter_id, _AssetResolver.CTX_SELECT_CARD
	)
	if not bool(presentation.get("is_current_canonical", false)):
		_AssetResolver.PLAYER_VISIBLE_LEGACY_CARD_OCCURRENCES += 1
	var host := Node2D.new()
	host.name = "CardBakeHost_%s" % fighter_id
	# Park off-tree bake under the scene tree root briefly.
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		_baking[fighter_id] = false
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
	if model.has_method("configure"):
		model.configure(data)
	if model.has_method("set_select_mode"):
		model.set_select_mode(true)
	# Allow SubViewport to paint.
	await tree.process_frame
	await tree.process_frame
	var img: Image = null
	if model.has_method("capture_portrait_image"):
		img = model.capture_portrait_image()
	elif model.has_method("get_viewport_image"):
		img = model.get_viewport_image()
	if img != null and img.get_width() > 0:
		var tex := ImageTexture.create_from_image(img)
		_cache[fighter_id] = tex
		if is_instance_valid(self):
			texture = tex
	else:
		_AssetResolver.CANONICAL_MODEL_LOAD_FAILURES += 1
	host.queue_free()
	_baking[fighter_id] = false


func _draw() -> void:
	if focused:
		var w := size.x
		var h := size.y
		draw_arc(Vector2(w * 0.5, h * 0.45), minf(w, h) * 0.42, 0.0, TAU, 28, _accent, 2.0)
