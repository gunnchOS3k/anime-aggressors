extends Camera2D
class_name PlatformFighterCamera

const MIN_ZOOM := 0.85
const MAX_ZOOM := 1.15

@export var fighter_a_path: NodePath
@export var fighter_b_path: NodePath
@export var follow_smoothing: float = 7.5
@export var zoom_smoothing: float = 6.0
@export var padding: Vector2 = Vector2(260, 180)
@export var camera_bounds: CameraBounds
@export var impulse_path: NodePath

var fighter_a: Node2D
var fighter_b: Node2D
var impulse: CameraImpulse

func _ready() -> void:
	fighter_a = get_node_or_null(fighter_a_path)
	fighter_b = get_node_or_null(fighter_b_path)
	impulse = get_node_or_null(impulse_path)
	if impulse == null:
		impulse = CameraImpulse.new()
		add_child(impulse)

func _process(delta: float) -> void:
	if fighter_a == null or fighter_b == null:
		return

	var center := (fighter_a.global_position + fighter_b.global_position) * 0.5
	center += impulse.sample(delta)
	if camera_bounds != null:
		center = camera_bounds.clamp_position(center)
	global_position = global_position.lerp(center, clampf(follow_smoothing * delta, 0.0, 1.0))

	var spread := absf(fighter_a.global_position.x - fighter_b.global_position.x)
	var vertical := absf(fighter_a.global_position.y - fighter_b.global_position.y)
	var spread_ratio := maxf(spread / maxf(1.0, padding.x), vertical / maxf(1.0, padding.y))
	var target_zoom := clampf(1.0 + spread_ratio * 0.12, MIN_ZOOM, MAX_ZOOM)
	var next_zoom := lerpf(zoom.x, target_zoom, clampf(zoom_smoothing * delta, 0.0, 1.0))
	zoom = Vector2.ONE * next_zoom
