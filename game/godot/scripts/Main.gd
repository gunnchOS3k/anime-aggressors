extends Node
class_name Main

enum Route { TITLE, CHARACTER_SELECT, STAGE_SELECT, VERSUS, BATTLE, DERBY }

@export var title_screen_path: NodePath
@export var character_select_path: NodePath
@export var stage_select_path: NodePath
@export var versus_screen_path: NodePath
@export var battle_scene_path: NodePath
@export var derby_mode_path: NodePath
@export var default_route: Route = Route.TITLE

var title_screen: TitleScreen
var character_select: CharacterSelect
var stage_select: StageSelect
var versus_screen: VersusScreen
var battle_scene: BattleScene
var derby_mode: ImpactDummyDerby
var current_route: Route

var _pending_p1: String = ""
var _pending_p2: String = ""
var _pending_stage: String = "skyline-arena"

func _ready() -> void:
	add_to_group("main_router")
	title_screen = get_node_or_null(title_screen_path)
	character_select = get_node_or_null(character_select_path)
	stage_select = get_node_or_null(stage_select_path)
	versus_screen = get_node_or_null(versus_screen_path)
	battle_scene = get_node_or_null(battle_scene_path)
	derby_mode = get_node_or_null(derby_mode_path)

	if title_screen != null:
		title_screen.start_pressed.connect(_on_title_battle)
		title_screen.derby_pressed.connect(_on_title_derby)
	if character_select != null:
		character_select.battle_selection_confirmed.connect(_on_battle_characters_selected)
		character_select.derby_selection_confirmed.connect(_on_derby_selected)
	if stage_select != null:
		stage_select.stage_confirmed.connect(_on_stage_selected)
	if versus_screen != null:
		versus_screen.versus_finished.connect(_on_versus_finished)

	_set_route(default_route)

func _on_title_battle() -> void:
	go_to_character_select(CharacterSelect.Mode.BATTLE)

func _on_title_derby() -> void:
	go_to_character_select(CharacterSelect.Mode.DERBY)

func go_to_character_select(mode: CharacterSelect.Mode = CharacterSelect.Mode.BATTLE) -> void:
	if character_select != null:
		character_select.set_mode(mode)
	_set_route(Route.CHARACTER_SELECT)

func go_character_select() -> void:
	go_to_character_select(CharacterSelect.Mode.BATTLE)

func _on_battle_characters_selected(p1: String, p2: String) -> void:
	_pending_p1 = p1
	_pending_p2 = p2
	_set_route(Route.STAGE_SELECT)

func _on_stage_selected(stage_id: String) -> void:
	_pending_stage = stage_id
	_set_route(Route.VERSUS)
	if versus_screen != null:
		versus_screen.show_matchup(_pending_p1, _pending_p2, _pending_stage)

func _on_versus_finished() -> void:
	if battle_scene != null:
		battle_scene.setup_match(_pending_p1, _pending_p2)
	_set_route(Route.BATTLE)

func _on_derby_selected(single_fighter_id: String) -> void:
	if derby_mode != null:
		derby_mode.set_selected_fighter(single_fighter_id)
		derby_mode.start_derby()
	_set_route(Route.DERBY)

func _set_route(next_route: Route) -> void:
	current_route = next_route
	_set_visible(title_screen, next_route == Route.TITLE)
	_set_visible(character_select, next_route == Route.CHARACTER_SELECT)
	_set_visible(stage_select, next_route == Route.STAGE_SELECT)
	_set_visible(versus_screen, next_route == Route.VERSUS)
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
