extends Control

## Wave014 Animation Lab — scrub procedural clips and compare fighters.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")

@onready var _list: ItemList = $Panel/List
@onready var _detail: Label = $Panel/Detail


func _ready() -> void:
	for fighter_id in FIGHTERS:
		var info: Dictionary = _AssetResolver.resolve_animation_root(fighter_id)
		_list.add_item("%s | %s" % [fighter_id, info.get("source", "?")])
	_list.item_selected.connect(_on_selected)


func _on_selected(index: int) -> void:
	if index < 0 or index >= FIGHTERS.size():
		return
	var fighter_id: String = FIGHTERS[index]
	var root := "res://content/fighters/%s/animations/procedural" % fighter_id
	var manifest_path := "%s/manifest.json" % root
	var text := "fighter=%s\nroot=%s\nalignment_overlay=RUNTIME_ANIMATION_COMBAT_ALIGNMENT\n" % [fighter_id, root]
	if FileAccess.file_exists(manifest_path):
		var f := FileAccess.open(manifest_path, FileAccess.READ)
		if f:
			text += f.get_as_text().left(400)
			f.close()
	_detail.text = text
