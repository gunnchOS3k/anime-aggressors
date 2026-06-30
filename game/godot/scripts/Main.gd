extends Node
class_name Main

enum Route { CHARACTER_SELECT, BATTLE, DERBY }

@export var character_select_path: NodePath
@export var battle_scene_path: NodePath
@export var derby_mode_path: NodePath
@export var default_route: Route = Route.CHARACTER_SELECT

var character_select: CharacterSelect
var battle_scene: BattleScene
var derby_mode: ImpactDummyDerby
var current_route: Route

func _ready() -> void:
	add_to_group("main_router")
	character_select = get_node_or_null(character_select_path)
	battle_scene = get_node_or_null(battle_scene_path)
	derby_mode = get_node_or_null(derby_mode_path)

	if character_select != null:
		character_select.battle_selection_confirmed.connect(_on_battle_selected)
		character_select.derby_selection_confirmed.connect(_on_derby_selected)

	var derby_btn := get_node_or_null("ModeBar/DerbyButton") as Button
	var battle_btn := get_node_or_null("ModeBar/BattleButton") as Button
	if derby_btn != null:
		derby_btn.pressed.connect(func(): go_to_character_select(CharacterSelect.Mode.DERBY))
	if battle_btn != null:
		battle_btn.pressed.connect(func(): go_to_character_select(CharacterSelect.Mode.BATTLE))

	_set_route(default_route)

func go_to_character_select(mode: CharacterSelect.Mode = CharacterSelect.Mode.BATTLE) -> void:
	if character_select != null:
		character_select.set_mode(mode)
	_set_route(Route.CHARACTER_SELECT)

func go_character_select() -> void:
	go_to_character_select(CharacterSelect.Mode.BATTLE)

func _on_battle_selected(p1_fighter_id: String, p2_fighter_id: String) -> void:
	if battle_scene != null:
		battle_scene.setup_match(p1_fighter_id, p2_fighter_id)
	_set_route(Route.BATTLE)

func _on_derby_selected(single_fighter_id: String) -> void:
	if derby_mode != null:
		derby_mode.set_selected_fighter(single_fighter_id)
		derby_mode.start_derby()
	_set_route(Route.DERBY)

func _set_route(next_route: Route) -> void:
	current_route = next_route
	_set_visible(character_select, next_route == Route.CHARACTER_SELECT)
	_set_visible(battle_scene, next_route == Route.BATTLE)
	_set_visible(derby_mode, next_route == Route.DERBY)

func _set_visible(node: Node, visible: bool) -> void:
	if node == null:
		return
	if node is CanvasItem:
		(node as CanvasItem).visible = visible
	elif node is Node3D:
		(node as Node3D).visible = visible
	node.set_process(visible)
	node.set_physics_process(visible)
