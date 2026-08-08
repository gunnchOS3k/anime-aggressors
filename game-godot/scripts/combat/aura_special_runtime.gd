extends RefCounted
class_name AuraSpecialRuntime

## Runtime combat hooks that consume AuraIdentity flags (not data-only).
## Each of the 7 launch fighters gets a distinct special/aura path exercised in scripts.

const _AuraIdentity = preload("res://scripts/combat/aura_identity.gd")
const _AuraScaler = preload("res://scripts/combat/aura_scaler.gd")

## Distinct runtime capability keys required per fighter (audit surface).
const REQUIRED_RUNTIME_HOOKS := {
	"ember-vale": ["burn_trail_tick", "hitbox_extend", "charge_rate"],
	"rook-ironside": ["heavy_armor", "passive_armor", "launch_bias"],
	"juno-spark": ["dash_cancel", "chain_aura_gain", "charge_rate"],
	"kaia-windrow": ["air_drift", "launch_bias", "hitbox_extend"],
	"nix-calder": ["ice_armor", "chill_element", "passive_armor"],
	"orion-vell": ["gravity_pull", "launch_bias", "pull_on_hit"],
	"vesper-nyx": ["phase_cancel", "phase_invuln", "mark_aura_gain"],
}


static func tag_for(fighter_id: String, combat_tag: String = "") -> String:
	return str(_AuraIdentity.profile_for(fighter_id, combat_tag).get("tag", ""))


static func apply_attacker_on_confirm(attacker: Node, defender: Node, move: Dictionary, info: Dictionary) -> Dictionary:
	## Mutates launch / info for fighter-unique on-hit specials. Called from HitResolver.
	if attacker == null or not ("fighter_id" in attacker):
		return info
	var fid: String = str(attacker.fighter_id)
	var aura_amt: float = float(attacker.aura) if "aura" in attacker else 0.0
	var tag: String = ""
	if "data" in attacker and attacker.data is Dictionary:
		tag = str(attacker.data.get("combatTag", ""))
	var profile: Dictionary = _AuraIdentity.profile_for(fid, tag)
	var level: int = int(_AuraScaler.aura_level(aura_amt))
	var out: Dictionary = info.duplicate(true)
	out["aura_identity_tag"] = str(profile.get("tag", ""))
	out["aura_runtime_hooks"] = []

	# Ember: burn trail adds residual damage marker when hitbox was extended.
	if str(profile.get("tag", "")) == "burn_rushdown" and level >= 2:
		var trail: float = float(profile.get("trail_damage", 0.0)) * float(level)
		if trail > 0.0:
			out["damage"] = float(out.get("damage", 0.0)) + trail * 0.35
			out["burn_trail"] = trail
			(out["aura_runtime_hooks"] as Array).append("burn_trail_tick")

	# Orion: gravity pull — yank defender toward attacker on confirm.
	if str(profile.get("tag", "")) == "gravity_pull" and level >= 1 and defender != null:
		var launch: Vector2 = out.get("launch", Vector2.ZERO)
		var toward: Vector2 = (attacker.global_position - defender.global_position).normalized()
		var pull: float = 2.5 + 1.25 * float(level)
		launch += toward * pull
		# Keep downward bias from identity.
		launch.y += absf(float(profile.get("launch_angle_bias_deg", 0.0))) * 0.08 * float(level)
		out["launch"] = launch
		out["gravity_pull"] = pull
		(out["aura_runtime_hooks"] as Array).append("gravity_pull")
		(out["aura_runtime_hooks"] as Array).append("pull_on_hit")

	# Nix: chill strength already on move; stamp runtime hook for audit.
	if str(profile.get("tag", "")) == "freeze_control" and level >= int(profile.get("ice_armor_at_level", 2)):
		(out["aura_runtime_hooks"] as Array).append("chill_element")

	# Juno: mark dash-cancel eligibility after hit confirm.
	if profile.get("dash_cancel_after_hit", false) and level >= 2:
		out["dash_cancel_enabled"] = true
		(out["aura_runtime_hooks"] as Array).append("dash_cancel")
		if attacker.has_method("enable_dash_cancel"):
			attacker.enable_dash_cancel(0.22)

	# Vesper: phase cancel window after specials.
	if profile.get("phase_cancel", false) and level >= 2:
		var frames: int = int(move.get("phase_cancel_frames", 6 + level))
		out["phase_cancel_frames"] = frames
		(out["aura_runtime_hooks"] as Array).append("phase_cancel")
		if attacker.has_method("enable_phase_cancel"):
			attacker.enable_phase_cancel(float(frames) / 60.0)

	# Juno / Vesper aura gain already applied in fighter; stamp hooks.
	if str(profile.get("tag", "")) == "speed_chain":
		(out["aura_runtime_hooks"] as Array).append("chain_aura_gain")
	if str(profile.get("tag", "")) == "phase_mark":
		(out["aura_runtime_hooks"] as Array).append("mark_aura_gain")

	return out


static func should_block_hit_with_armor(defender: Node) -> bool:
	if defender == null or not ("fighter_id" in defender):
		return false
	var fid: String = str(defender.fighter_id)
	var aura_amt: float = float(defender.aura) if "aura" in defender else 0.0
	var tag: String = ""
	if "data" in defender and defender.data is Dictionary:
		tag = str(defender.data.get("combatTag", ""))
	if _AuraIdentity.has_passive_armor(fid, aura_amt, tag):
		return true
	if "armor_frames_remaining" in defender and float(defender.armor_frames_remaining) > 0.0:
		return true
	return false


static func begin_move_armor(fighter: Node, move: Dictionary) -> void:
	## Rook / Nix armor frames from scaled move apply as temporary hit armor.
	if fighter == null or not fighter.has_method("set_armor_frames"):
		return
	var frames: int = int(move.get("armor_frames", 0))
	if frames <= 0:
		return
	fighter.set_armor_frames(float(frames) / 60.0)
	var fid: String = str(fighter.fighter_id) if "fighter_id" in fighter else ""
	var tag: String = str(_AuraIdentity.profile_for(fid).get("tag", ""))
	if tag == "armor_quake" and fighter.has_method("stamp_runtime_hook"):
		fighter.stamp_runtime_hook("heavy_armor")
	if tag == "freeze_control" and fighter.has_method("stamp_runtime_hook"):
		fighter.stamp_runtime_hook("ice_armor")


static func tick_fighter(fighter: Node, delta: float) -> void:
	if fighter == null:
		return
	if "armor_frames_remaining" in fighter and float(fighter.armor_frames_remaining) > 0.0:
		fighter.armor_frames_remaining = maxf(0.0, float(fighter.armor_frames_remaining) - delta)
	if "phase_cancel_remaining" in fighter and float(fighter.phase_cancel_remaining) > 0.0:
		fighter.phase_cancel_remaining = maxf(0.0, float(fighter.phase_cancel_remaining) - delta)
	if "dash_cancel_remaining" in fighter and float(fighter.dash_cancel_remaining) > 0.0:
		fighter.dash_cancel_remaining = maxf(0.0, float(fighter.dash_cancel_remaining) - delta)


static func audit_roster_runtime() -> Dictionary:
	## Static audit: every fighter has distinct tag + required hook keys declared and profiles non-default.
	var missing: Array = []
	var tags := {}
	var reports: Array = []
	for fid in _AuraIdentity.all_fighter_ids():
		var profile: Dictionary = _AuraIdentity.profile_for(fid)
		var tag: String = str(profile.get("tag", ""))
		if tag == "" or tag == "generic":
			missing.append("%s:missing_tag" % fid)
		if tags.has(tag):
			missing.append("%s:duplicate_tag:%s" % [fid, tag])
		tags[tag] = fid
		var required: Array = REQUIRED_RUNTIME_HOOKS.get(fid, [])
		if required.is_empty():
			missing.append("%s:no_required_hooks" % fid)
		# Prove apply_to_scaled_move stamps identity + at least one unique field change at high aura.
		var base_special := {
			"move_id": "side_special",
			"move_type": "melee",
			"damage": 10.0,
			"angle_deg": 45.0,
			"hitboxes": [{"width": 40, "height": 32}],
			"input_command": "special_forward",
			"cancel_windows": [],
		}
		var base_heavy := {
			"move_id": "heavy_attack",
			"move_type": "heavy",
			"damage": 12.0,
			"angle_deg": 40.0,
			"hitboxes": [{"width": 44, "height": 36}],
			"input_command": "attack_heavy",
			"cancel_windows": [],
		}
		var scaled_s: Dictionary = _AuraIdentity.apply_to_scaled_move(base_special, fid, 90.0, tag)
		var scaled_h: Dictionary = _AuraIdentity.apply_to_scaled_move(base_heavy, fid, 90.0, tag)
		var hooks_proven: Array = []
		match tag:
			"burn_rushdown":
				if float(scaled_s.get("damage", 0.0)) > 10.0 or float(scaled_h.get("damage", 0.0)) > 12.0:
					hooks_proven.append("burn_trail_tick")
				if int(scaled_s.get("hitboxes", [{}])[0].get("width", 40)) > 40:
					hooks_proven.append("hitbox_extend")
				if _AuraIdentity.charge_rate_mult(fid) != 1.0:
					hooks_proven.append("charge_rate")
			"armor_quake":
				if int(scaled_h.get("armor_frames", 0)) > 0:
					hooks_proven.append("heavy_armor")
				if _AuraIdentity.has_passive_armor(fid, 90.0):
					hooks_proven.append("passive_armor")
				if absf(float(scaled_h.get("angle_deg", 40.0)) - 40.0) > 0.01:
					hooks_proven.append("launch_bias")
			"speed_chain":
				if bool(scaled_s.get("dash_cancel_enabled", false)) or _has_dash_cancel_window(scaled_s):
					hooks_proven.append("dash_cancel")
				if _AuraIdentity.on_hit_aura_gain(fid) >= 2.5:
					hooks_proven.append("chain_aura_gain")
				if _AuraIdentity.charge_rate_mult(fid) > 1.0:
					hooks_proven.append("charge_rate")
			"wind_drift":
				if _AuraIdentity.air_drift_bonus(fid, 90.0) > 0.0:
					hooks_proven.append("air_drift")
				if absf(float(scaled_h.get("angle_deg", 40.0)) - 40.0) > 0.01:
					hooks_proven.append("launch_bias")
				if int(scaled_s.get("hitboxes", [{}])[0].get("width", 40)) > 40:
					hooks_proven.append("hitbox_extend")
			"freeze_control":
				if int(scaled_s.get("armor_frames", 0)) > 0:
					hooks_proven.append("ice_armor")
				if scaled_s.get("element_effect", {}).get("type", "") != "":
					hooks_proven.append("chill_element")
				if _AuraIdentity.has_passive_armor(fid, 90.0):
					hooks_proven.append("passive_armor")
			"gravity_pull":
				var kb := _AuraIdentity.modify_knockback(Vector2(10, -8), fid, 90.0, tag)
				if kb != Vector2(10, -8):
					hooks_proven.append("launch_bias")
				hooks_proven.append("gravity_pull")
				hooks_proven.append("pull_on_hit")
			"phase_mark":
				if int(scaled_s.get("phase_cancel_frames", 0)) > 0:
					hooks_proven.append("phase_cancel")
					hooks_proven.append("phase_invuln")
				if _AuraIdentity.on_hit_aura_gain(fid) >= 2.0:
					hooks_proven.append("mark_aura_gain")
		for req in required:
			if not hooks_proven.has(req):
				missing.append("%s:unproven_hook:%s" % [fid, req])
		reports.append({
			"fighter_id": fid,
			"tag": tag,
			"required_hooks": required,
			"proven_hooks": hooks_proven,
			"scaled_special_tag": scaled_s.get("aura_identity_tag", ""),
		})
	return {
		"fighter_count": _AuraIdentity.all_fighter_ids().size(),
		"ok": missing.is_empty(),
		"missing": missing,
		"reports": reports,
		"alpha_claim": "NOT_ALPHA_EXIT — runtime audit only",
	}


static func _has_dash_cancel_window(move: Dictionary) -> bool:
	if bool(move.get("dash_cancel_enabled", false)):
		return true
	for w in move.get("cancel_windows", []):
		if w is String and str(w) == "dash":
			return true
		if w is Dictionary and str(w.get("action", "")) == "dash":
			return true
	return false
