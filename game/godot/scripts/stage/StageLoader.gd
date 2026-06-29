extends Node
class_name StageLoader

@export var stage_root_path: NodePath
@export var default_stage: StageDefinition

var active_stage_node: Node
var active_stage_definition: StageDefinition

func _ready() -> void:
	if default_stage != null:
		load_stage(default_stage)

func load_stage(stage: StageDefinition) -> Node:
	active_stage_definition = stage
	if active_stage_node != null:
		active_stage_node.queue_free()

	var stage_root := get_node_or_null(stage_root_path)
	if stage_root == null:
		stage_root = self

	if stage.scene_path.is_empty():
		active_stage_node = Node2D.new()
		stage_root.add_child(active_stage_node)
		return active_stage_node

	var packed: PackedScene = load(stage.scene_path)
	if packed == null:
		push_warning("Stage scene could not be loaded: %s" % stage.scene_path)
		active_stage_node = Node2D.new()
	else:
		active_stage_node = packed.instantiate()
	stage_root.add_child(active_stage_node)
	return active_stage_node
