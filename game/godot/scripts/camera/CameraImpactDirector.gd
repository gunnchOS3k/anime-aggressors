extends Node
class_name CameraImpactDirector

@export var camera_path: NodePath
@export var impulse_path: NodePath

var camera: PlatformFighterCamera
var impulse: CameraImpulse

func _ready() -> void:
	camera = get_node_or_null(camera_path) as PlatformFighterCamera
	impulse = get_node_or_null(impulse_path) as CameraImpulse
	if impulse == null and camera != null:
		impulse = camera.impulse

func on_hit_confirmed(hit_info: Dictionary) -> void:
	if impulse == null:
		return
	var launch: Vector2 = hit_info.get("launch_velocity", Vector2.ZERO)
	var strength := clampf(launch.length() / 900.0, 0.4, 1.4)
	impulse.add_impulse(Vector2(signf(launch.x) * 14.0 * strength, -10.0 * strength))
	if camera != null:
		camera.zoom = Vector2.ONE * clampf(camera.zoom.x - 0.04 * strength, camera.MIN_ZOOM, camera.MAX_ZOOM)

func on_ko() -> void:
	if impulse != null:
		impulse.add_impulse(Vector2(0, -18))
	if camera != null:
		camera.zoom = Vector2.ONE * (camera.MAX_ZOOM + 0.05)
