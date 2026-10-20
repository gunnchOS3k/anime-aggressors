extends "res://tests/v1_closure/FighterSpacingReview.gd"
## Same ordinary input recipe as the retained spacing movie. Observers only.
var pose_samples: Array = []
var surface_contacts: Array = []
var foreground_requested := false
func wait(count: int) -> void:
	if not foreground_requested and "--native-foreground" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		# Existing native clock diagnostic method; capture-only, never gameplay.
		foreground_requested = true
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
		DisplayServer.window_move_to_foreground()
	for i in range(count):
		if battle != null:
			var actors: Array = []
			for actor in [p, d]:
				var sk: Skeleton3D = actor.model_3d.get_animation_controller().get_skeleton()
				sk.force_update_all_bone_transforms()
				var points: Dictionary = {}
				for name in ["Hips", "Chest", "Head", "Hand_L", "Hand_R", "Foot_L", "Foot_R"]:
					var point := projected(actor.model_3d, sk, name)
					points[name] = [point.x, point.y]
				actors.append({"slot": actor.slot, "points_world": points})
			pose_samples.append({"physics_frame": Engine.get_physics_frames(), "case": label, "actors": actors})
		await super.wait(1)
func contact(actor, other, info: Dictionary) -> void:
	super.contact(actor, other, info)
	var c = actor.model_3d.get_animation_controller()
	var mid: String = str(info.move_id) + ("_left" if actor.attack_direction == -1 else "")
	var limb: String = str(c._choreography_timing.get(mid, {}).get("striking_limb", "Hand_R"))
	var hand := projected_surface(actor.model_3d, limb)
	var overlap: Rect2 = actor.hit_resolver._world_bounds(actor.get_node("Hitbox/HitShape")).intersection(actor.hit_resolver._world_bounds(other.get_node("Hurtbox/HurtShape")))
	var feet: Dictionary = {}
	for side in ["L", "R"]:
		var sole := -INF
		for point in projected_surface(actor.model_3d, "Foot_" + side): sole = maxf(sole, point.y)
		feet[side] = sole - actor.hit_resolver._world_bounds(actor.get_node("CollisionShape2D")).end.y
	surface_contacts.append({"event_id": info.combat_event_id, "frame": Engine.get_physics_frames(), "move": info.move_id, "owner": info.contact_owner, "result": info.contact_result, "intended_limb": limb, "hand_to_real_overlap_surface_px": polygon_gap(hand, rect_polygon(overlap)) if overlap.has_area() else -1.0, "boot_sole_below_collider_px": feet, "scope": "weighted skin projection at authentic contact; direct throws need not have an active melee overlap; no artistic pass threshold"})
func write_evidence(final: bool) -> void:
	super.write_evidence(final)
	var f = FileAccess.open(output.path_join("contact_integration.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"complete": final, "pose_samples": pose_samples, "contacts": surface_contacts, "scope": "ordinary active local controllers; unchanged inherited approach/shield/strike/dodge/jump/grab/throw/whiff inputs; no frozen actors or seeded transforms/damage/results"})); f.close()
