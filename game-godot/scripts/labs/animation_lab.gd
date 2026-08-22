extends Control

## Wave014 Animation Lab — scrub procedural clips via canonical runtime controller.

const FIGHTERS := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]
const _AssetResolver = preload("res://scripts/visual/fighter_asset_resolver.gd")
const MODEL_SCRIPT := preload("res://scripts/fighters/fighter_model_3d.gd")
const _DataLoader = preload("res://scripts/data/data_loader.gd")
const _FighterStates = preload("res://scripts/fighters/fighter_states.gd")

@onready var _list: ItemList = $Panel/List
@onready var _detail: Label = $Panel/Detail

var _models: Dictionary = {}
var _preview_host: Node


func _ready() -> void:
	_preview_host = Node.new()
	_preview_host.name = "PreviewHost"
	add_child(_preview_host)
	for fighter_id in FIGHTERS:
		var model: Node = MODEL_SCRIPT.new()
		_preview_host.add_child(model)
		model.visible = false
		model.configure(_DataLoader.load_fighter(fighter_id))
		_models[fighter_id] = model
		var info: Dictionary = _AssetResolver.resolve_animation_root(fighter_id)
		_list.add_item("%s | %s" % [fighter_id, info.get("source", "?")])
	_list.item_selected.connect(_on_selected)


func _on_selected(index: int) -> void:
	if index < 0 or index >= FIGHTERS.size():
		return
	var fighter_id: String = FIGHTERS[index]
	for fid in _models.keys():
		_models[fid].visible = fid == fighter_id
	var model = _models[fighter_id]
	var root := "res://content/fighters/%s/animations/procedural" % fighter_id
	var manifest_path := "%s/manifest.json" % root
	var controller = model.get_animation_controller() if model.has_method("get_animation_controller") else null
	var text := "fighter=%s\nroot=%s\nANIMATION_LAB_USES_CANONICAL_RUNTIME_CONTROLLER=%s\nactive_clip=%s\n" % [
		fighter_id,
		root,
		str(controller != null),
		model.get_active_animation_clip() if model.has_method("get_active_animation_clip") else "",
	]
	if FileAccess.file_exists(manifest_path):
		var f := FileAccess.open(manifest_path, FileAccess.READ)
		if f:
			text += f.get_as_text().left(400)
			f.close()
	model.play_for_state(_FighterStates.IDLE, {})
	_detail.text = text
