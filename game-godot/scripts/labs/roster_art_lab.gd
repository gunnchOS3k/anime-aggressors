extends Control

## Wave014 Roster Art Lab — displays seven visible procedural production-proxy models.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")

@onready var _grid: GridContainer = $Grid
@onready var _status: Label = $Status


func _ready() -> void:
	_populate()


func _populate() -> void:
	var loaded := 0
	for fighter_id in FIGHTERS:
		var info: Dictionary = _AssetResolver.resolve_model_path(fighter_id, {"id": fighter_id})
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(180, 200)
		var model: Node = MODEL_SCRIPT.new()
		model.name = "Preview_%s" % fighter_id
		card.add_child(model)
		var data := _DataLoader.load_fighter(fighter_id)
		var configured := model.configure(data)
		if configured and model.is_procedural_proxy_visible():
			loaded += 1
		var caption := Label.new()
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD
		caption.text = "%s\n%s\nvisible=%s" % [
			fighter_id,
			info.get("tier", "?"),
			str(model.is_procedural_proxy_visible()),
		]
		card.add_child(caption)
		_grid.add_child(card)
	_status.text = "ROSTER_ARTLAB_REAL_PROCEDURAL_MODELS=%d / 7 — CANONICAL_VISIBLE_MODEL" % loaded
