extends CanvasLayer
class_name ArtSourceReviewOverlay

## Dev/review overlay. Disabled unless HUMAN_ART_STAGING or HUMAN_ART_FULL_ROSTER_REVIEW is on.
const _Resolver = preload("res://scripts/visual/fighter_asset_resolver.gd")

var _source_label: Label
var _count_label: Label


static func enabled() -> bool:
	return _Resolver.staging_review_enabled()


func _ready() -> void:
	layer = 80
	if not enabled():
		visible = false
		return
	_build()
	refresh()


func _build() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 16)
	root.add_theme_constant_override("margin_top", 8)
	root.add_theme_constant_override("margin_right", 16)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	_source_label = Label.new()
	_source_label.name = "ArtSourceLabel"
	_source_label.add_theme_font_size_override("font_size", 16)
	_source_label.text = "ART SOURCE: CURRENT_ACCEPTED_ART"
	box.add_child(_source_label)
	_count_label = Label.new()
	_count_label.name = "RosterCounts"
	_count_label.add_theme_font_size_override("font_size", 14)
	box.add_child(_count_label)


func set_fighter(fighter_id: String, fighter_data: Dictionary = {}) -> void:
	if not enabled():
		visible = false
		return
	visible = true
	if _source_label == null:
		return
	var model: Dictionary = _Resolver.resolve_model_path(fighter_id, fighter_data)
	var label := _Resolver.art_source_public_label(str(model.get("source", "")), str(model.get("path", "")))
	_source_label.text = "ART SOURCE: %s" % label
	refresh()


func refresh() -> void:
	if _count_label == null:
		return
	var counts: Dictionary = _Resolver.roster_review_counts()
	_count_label.text = str(counts.get("label", "Candidate: 0/7"))
