extends Control

## Wave014 Roster Art Lab — displays seven procedural production-proxy models.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")

@onready var _grid: GridContainer = $Grid
@onready var _status: Label = $Status


func _ready() -> void:
	_populate()


func _populate() -> void:
	var loaded := 0
	for fighter_id in FIGHTERS:
		var info: Dictionary = _AssetResolver.resolve_model_path(fighter_id, {"id": fighter_id})
		var card := Label.new()
		card.text = "%s\n%s\n%s" % [fighter_id, info.get("tier", "?"), info.get("path", "missing")]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD
		card.custom_minimum_size = Vector2(180, 72)
		if str(info.get("tier", "")) == "PROCEDURAL_PRODUCTION_PROXY":
			loaded += 1
		_grid.add_child(card)
	_status.text = "ROSTER_ARTLAB_REAL_PROCEDURAL_MODELS=%d / 7 — PROCEDURAL_PRODUCTION_PROXY_RENDER" % loaded
