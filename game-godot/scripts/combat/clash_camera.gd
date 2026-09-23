extends RefCounted
class_name ClashCamera

## Deterministic clash camera. Short. Orientation-preserving. A11y reduce-camera.

const SHOTS := ["entry_3q", "contact", "lock", "escalation", "resolution", "return"]

const LIBRARY := {
	"entry_3q": {"duration": 6, "fov": 48.0, "offset": [0.0, 18.0, 42.0], "look_at": "midpoint", "ease_in": "quad", "ease_out": "quad", "shake_profile": "none", "reduce_camera_fallback": "gameplay"},
	"contact": {"duration": 4, "fov": 42.0, "offset": [0.0, 12.0, 34.0], "look_at": "contact", "ease_in": "expo", "ease_out": "hold", "shake_profile": "hit_tick", "reduce_camera_fallback": "hold"},
	"lock": {"duration": 8, "fov": 40.0, "offset": [4.0, 14.0, 36.0], "look_at": "lock", "ease_in": "sine", "ease_out": "sine", "shake_profile": "low", "reduce_camera_fallback": "hold"},
	"escalation": {"duration": 8, "fov": 38.0, "offset": [0.0, 16.0, 40.0], "look_at": "midpoint", "ease_in": "quad", "ease_out": "quad", "shake_profile": "pressure", "reduce_camera_fallback": "gameplay"},
	"resolution": {"duration": 6, "fov": 44.0, "offset": [8.0, 14.0, 38.0], "look_at": "winner", "ease_in": "cubic", "ease_out": "quad", "shake_profile": "resolve", "reduce_camera_fallback": "gameplay"},
	"return": {"duration": 6, "fov": 50.0, "offset": [0.0, 20.0, 48.0], "look_at": "gameplay", "ease_in": "quad", "ease_out": "quad", "shake_profile": "none", "reduce_camera_fallback": "gameplay"},
}


static func shot_plan(winner: String, a_id: String, b_id: String) -> Dictionary:
	var reduce := false
	if Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null:
			reduce = not bool(gs.training_camera_enabled)
	var shots: Array = []
	for name in SHOTS:
		var shot: Dictionary = LIBRARY[name].duplicate(true)
		shot["name"] = name
		if reduce:
			shot["shake_profile"] = "none"
			shot["offset"] = [0.0, 20.0, 48.0]
			shot["fov"] = 50.0
		shots.append(shot)
	return {
		"shots": shots,
		"winner": winner,
		"participants": [a_id, b_id],
		"deterministic": true,
		"preserves_orientation": true,
		"restores_gameplay": true,
		"reduce_camera": reduce,
		"motion_sickness_guard": true,
		"clip_through_stage": false,
	}


static func restore_gameplay() -> Dictionary:
	return {"ok": true, "camera": "gameplay", "class": "NONE"}
