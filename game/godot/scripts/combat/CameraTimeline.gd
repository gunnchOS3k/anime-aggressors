extends RefCounted
class_name CameraTimeline

const EVENTS := {
	"light_impact": {"x": 8.0, "y": -6.0, "zoom": -0.02},
	"medium_impact": {"x": 12.0, "y": -8.0, "zoom": -0.03},
	"launch_impact": {"x": 14.0, "y": -12.0, "zoom": -0.04},
	"sweep_impact": {"x": 10.0, "y": -4.0, "zoom": -0.02},
	"ko_impact": {"x": 0.0, "y": -18.0, "zoom": 0.05},
}

static func queue_event(fighter: FighterController, event_id: String) -> void:
	var battle := fighter.get_parent() as BattleScene
	if battle == null:
		return
	var director := battle.get_node_or_null("CameraImpactDirector") as CameraImpactDirector
	if director == null:
		return
	var spec: Dictionary = EVENTS.get(event_id, EVENTS["light_impact"])
	director.on_hit_confirmed({
		"launch_velocity": Vector2(spec.get("x", 8.0), spec.get("y", -6.0)),
	})
