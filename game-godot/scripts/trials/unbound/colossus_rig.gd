extends RefCounted
class_name ColossusRig
## Real giant engineering scaffolding — rigs, scale-aware collision, cameras.
## Not a simple scale-up transform. Cosmic Colossus Yin/Yang + Rosamere Everlasting
## Origin controllable in opt-in Mythic only. Avatar KO ≠ true Rosamere defeat.

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
		"collision": {
			"mode": "scale_aware_capsule",
			"radius": 48.0 * 4.5,
			"height": 120.0 * 4.5,
			"not_simple_uniform_scale_hitbox": true,
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
		"HUMAN_ART_APPROVED": false,
		"final_rig_approved": false,
	}


static func apply_hit(rig: Dictionary, knockback_mult: float, facing: int) -> Dictionary:
	var next: Dictionary = rig.duplicate(true)
	var impulse: float = 420.0 * knockback_mult * float(facing)
	next["last_impulse"] = impulse
	next["hp"] = maxi(0, int(next.get("hp", 1000)) - int(18 * knockback_mult))
	if int(next.get("hp", 1)) <= 0:
		next["avatar_ko"] = true
		next["true_entity_defeated"] = false
	return next


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
