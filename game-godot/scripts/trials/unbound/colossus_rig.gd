extends RefCounted
class_name ColossusRig
## Real giant engineering — dictionary authority + ColossusActor node factory.
## Not a simple scale-up transform. Cosmic Colossus Yin/Yang + Rosamere Everlasting
## Origin controllable in opt-in Mythic only. Avatar KO ≠ true Rosamere defeat.
## Live battles mount ColossusActor (CharacterBody2D + capsule) beyond dict scaffolds.

const Authority = preload("res://scripts/trials/mode_authority.gd")


static func spawn_for_preset(preset_id: String, seed: int) -> Array:
	var rigs: Array = []
	match preset_id:
		"colossus_clash":
			rigs.append(_rig("cosmic_colossus_yin", "Cosmic Colossus Yin", seed, 0))
			rigs.append(_rig("cosmic_colossus_yang", "Cosmic Colossus Yang", seed, 1))
			rigs.append(_rig("rosamere_everlasting_origin", "Rosamere Everlasting Origin (avatar)", seed, 2))
		"kaiju_siege":
			rigs.append(_rig("kaiju_echo_black", "Black Puppet Echo", seed, 0))
			rigs.append(_rig("kaiju_echo_white", "White Puppet Echo", seed, 1))
		_:
			pass
	return rigs


static func _rig(id: String, display: String, seed: int, slot: int) -> Dictionary:
	return {
		"rig_id": id,
		"display_name": display,
		"slot": slot,
		"seed": seed,
		"scale": 4.5,
		"hp": 1000,
		"max_hp": 1000,
		"position": {"x": 600.0 + float(slot) * 420.0, "y": 520.0},
		"facing": 1 if slot % 2 == 0 else -1,
		"collision": {
			"mode": "scale_aware_capsule",
			"radius": 48.0 * 4.5,
			"height": 120.0 * 4.5,
			"hurtbox_layers": ["torso", "guard", "reach"],
			"not_simple_uniform_scale_hitbox": true,
			"frame_sampled": true,
		},
		"camera": {
			"spectacle_framing": true,
			"min_zoom_out": 1.8,
			"shake_budget_per_10s": 4,
			"a11y_reduce_motion_respected": true,
		},
		"controllable_in_mythic_only": true,
		"is_yin_yang_rosamere_puppet_without_approval": false,
		"avatar_ko_is_true_rosamere_defeat": false,
		"real_giant_engineering": true,
		"not_scale_up_transform_only": true,
		"live_tick_enabled": true,
		"HUMAN_ART_APPROVED": false,
		"final_rig_approved": false,
	}


static func apply_hit(rig: Dictionary, knockback_mult: float, facing: int) -> Dictionary:
	var next: Dictionary = rig.duplicate(true)
	var impulse: float = 420.0 * knockback_mult * float(facing)
	next["last_impulse"] = impulse
	next["facing"] = facing
	var pos: Dictionary = next.get("position", {"x": 960.0, "y": 540.0}).duplicate(true)
	pos["x"] = float(pos.get("x", 960.0)) + impulse * 0.08
	next["position"] = pos
	next["hp"] = maxi(0, int(next.get("hp", 1000)) - int(18 * knockback_mult))
	if int(next.get("hp", 1)) <= 0:
		next["avatar_ko"] = true
		next["true_entity_defeated"] = false
		## Avatar KO never becomes true Rosamere / cosmos defeat.
		next["canonical_cosmic_defeat"] = false
	return next


static func step_rigs(rigs: Array, frame: int, seed: int) -> Array:
	## Advance colossus spectacle scaffolds — scale-aware motion, not uniform scale-up transform.
	var out: Array = []
	var rng: Callable = Authority.mulberry32(seed * 4099 + frame)
	for rig in rigs:
		var next: Dictionary = rig.duplicate(true)
		if bool(next.get("avatar_ko", false)):
			out.append(next)
			continue
		var pos: Dictionary = next.get("position", {"x": 960.0, "y": 540.0}).duplicate(true)
		var sway: float = (float(rng.call()) - 0.5) * 10.0
		pos["x"] = float(pos.get("x", 960.0)) + sway
		pos["y"] = float(pos.get("y", 540.0)) + sin(float(frame) * 0.05 + float(next.get("slot", 0))) * 2.0
		next["position"] = pos
		next["frame"] = frame
		next["live_tick_enabled"] = true
		out.append(next)
	return out


static func overlap_summary(rig: Dictionary, point: Vector2) -> Dictionary:
	## Scale-aware capsule overlap probe for live Unbound hits (scaffold, not final art).
	var c: Dictionary = rig.get("collision", {})
	var pos: Dictionary = rig.get("position", {})
	var center := Vector2(float(pos.get("x", 960.0)), float(pos.get("y", 540.0)))
	var radius: float = float(c.get("radius", 0.0))
	var height: float = float(c.get("height", 0.0))
	var dx: float = absf(point.x - center.x)
	var dy: float = absf(point.y - center.y)
	var inside: bool = dx <= radius and dy <= height * 0.5
	return {
		"inside": inside,
		"rig_id": str(rig.get("rig_id", "")),
		"mode": str(c.get("mode", "")),
		"not_simple_uniform_scale_hitbox": bool(c.get("not_simple_uniform_scale_hitbox", false)),
		"HUMAN_ART_APPROVED": false,
	}


static func validate_engineering(rig: Dictionary) -> Dictionary:
	var ok: bool = bool(rig.get("real_giant_engineering", false)) \
		and bool(rig.get("not_scale_up_transform_only", false)) \
		and str(rig.get("collision", {}).get("mode", "")) == "scale_aware_capsule" \
		and not bool(rig.get("avatar_ko_is_true_rosamere_defeat", true))
	return {"ok": ok, "rig_id": rig.get("rig_id", ""), "shipping": Authority.shipping_flags_false()}


static func camera_profile_for_battle(rig: Dictionary) -> Dictionary:
	## Spectacle camera scaffold for BattleCameraController — a11y-aware, not final art.
	var cam: Dictionary = rig.get("camera", {})
	var zoom_out: float = float(cam.get("min_zoom_out", 1.8))
	return {
		"minZoom": clampf(0.55 / maxf(zoom_out * 0.35, 0.5), 0.42, 0.85),
		"maxZoom": 1.05,
		"lerp": 0.1,
		"deadzone": {"x": 140, "y": 90},
		"spectacle_framing": bool(cam.get("spectacle_framing", true)),
		"shake_budget_per_10s": int(cam.get("shake_budget_per_10s", 4)),
		"a11y_reduce_motion_respected": bool(cam.get("a11y_reduce_motion_respected", true)),
		"colossus_rig_id": str(rig.get("rig_id", "")),
		"HUMAN_ART_APPROVED": false,
		"collision_scaffold": rig.get("collision", {}),
	}


static func collision_scaffold_summary(rig: Dictionary) -> Dictionary:
	var c: Dictionary = rig.get("collision", {})
	return {
		"mode": str(c.get("mode", "")),
		"radius": float(c.get("radius", 0.0)),
		"height": float(c.get("height", 0.0)),
		"not_simple_uniform_scale_hitbox": bool(c.get("not_simple_uniform_scale_hitbox", false)),
		"real_giant_engineering": bool(rig.get("real_giant_engineering", false)),
		"HUMAN_ART_APPROVED": false,
	}
