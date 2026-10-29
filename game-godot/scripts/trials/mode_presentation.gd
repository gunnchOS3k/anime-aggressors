extends RefCounted
class_name TrialsModePresentation
## Mode presentation scaffolds for Trials of Convergence.
## Honest art_status — HUMAN_ART / HUMAN_ART_APPROVED stay false. Not commercial V1 art.

const Authority = preload("res://scripts/trials/mode_authority.gd")
const Flagline = preload("res://scripts/trials/flagline/fractured_accord_sim.gd")
const Colossus = preload("res://scripts/trials/unbound/colossus_rig.gd")

const ART_STATUS_SCAFFOLD := "SCAFFOLD_PROCEDURAL"
const ART_STATUS_PLACEHOLDER := "PLACEHOLDER_GEOMETRY"


static func _base(mode_id: String) -> Dictionary:
	return {
		"mode_id": mode_id,
		"art_status": ART_STATUS_SCAFFOLD,
		"HUMAN_ART": false,
		"HUMAN_ART_APPROVED": false,
		"final_art_approved": false,
		"RC2_READY": false,
		"V1_0_0_RELEASE_AUTHORIZED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"note": "Procedural / scaffold presentation — not human-approved production art",
	}


static func for_mode(mode_id: String, seed: int = 1) -> Dictionary:
	match mode_id:
		"resonance_trial":
			return derby(seed)
		"fractured_accord":
			return flagline_territory(seed)
		"prism_weave":
			return prism_tiles(seed)
		"riftline_defense":
			return riftline_lanes(seed)
		"echoes_gauntlet":
			return survival_echoes(seed)
		"convergence_unbound":
			return unbound_colossus(seed)
		_:
			var b: Dictionary = _base(mode_id)
			b["elements"] = []
			return b


static func derby(seed: int = 1) -> Dictionary:
	var p: Dictionary = _base("resonance_trial")
	p["display_name"] = "Resonance Trial"
	p["elements"] = [
		{
			"id": "impact_dummy",
			"kind": "authored_procedural_capsule",
			"art_status": ART_STATUS_PLACEHOLDER,
			"HUMAN_ART": false,
			"not_rook_standin": true,
			"color": Color(0.72, 0.74, 0.78),
			"position": Vector2(1200, 836),
			"note": "Authored ResonanceDummyActor capsule — not a roster fighter stand-in",
		},
		{
			"id": "kinetic_bat_launcher",
			"kind": "launcher_prop",
			"art_status": ART_STATUS_SCAFFOLD,
			"HUMAN_ART": false,
			"available_after_damage_phase": true,
			"color": Color(0.95, 0.62, 0.18),
			"note": "Original Kinetic Bat launcher chrome — contract-owned, not third-party bat",
		},
		{
			"id": "distance_ruler",
			"kind": "hud_metric",
			"art_status": ART_STATUS_SCAFFOLD,
			"HUMAN_ART": false,
			"units": "fp/1000",
		},
	]
	p["seed"] = seed
	return p


static func flagline_territory(seed: int = 1, room: int = 0) -> Dictionary:
	var p: Dictionary = _base("fractured_accord")
	p["display_name"] = "Fractured Accord"
	var rooms: Array = []
	for idx in [-2, -1, 0, 1, 2]:
		rooms.append({
			"room_index": idx,
			"name": str(Flagline.ART_TERRITORY_NAMES.get(idx, "Room %d" % idx)),
			"active": idx == room,
			"beaconward_push": idx < 0,
			"veilward_push": idx > 0,
			"art_status": ART_STATUS_SCAFFOLD,
			"HUMAN_ART": false,
			"fill": Color(0.35, 0.55, 0.85) if idx <= 0 else Color(0.85, 0.55, 0.25),
		})
	p["elements"] = [
		{"id": "territory_strip", "kind": "room_strip", "rooms": rooms, "HUMAN_ART": false},
		{"id": "capture_meter", "kind": "dual_capture_bar", "aliases": Flagline.DISPLAY_ALIAS.duplicate(), "HUMAN_ART": false},
		{"id": "team_badges", "kind": "beaconward_veilward", "HUMAN_ART": false, "yin_yang_not_ordinary_captains": true},
	]
	p["current_room"] = room
	p["seed"] = seed
	return p


static func prism_tiles(seed: int = 1) -> Dictionary:
	var p: Dictionary = _base("prism_weave")
	p["display_name"] = "Prism Weave"
	var Prism = load("res://scripts/trials/prism/prism_weave_sim.gd")
	var markers: Array = []
	if Prism != null:
		for m in Prism.TEAM_MARKERS:
			markers.append({"marker": m, "art_status": ART_STATUS_SCAFFOLD, "HUMAN_ART": false})
	p["elements"] = [
		{
			"id": "harmonic_grid",
			"kind": "tile_grid",
			"cols": 24,
			"rows": 14,
			"art_status": ART_STATUS_SCAFFOLD,
			"HUMAN_ART": false,
			"accessibility_markers": markers,
			"note": "Harmonic tiles use shape markers beyond color",
		},
		{
			"id": "weave_pulse",
			"kind": "bounded_harmonic",
			"count": 6,
			"art_status": ART_STATUS_SCAFFOLD,
			"HUMAN_ART": false,
		},
	]
	p["seed"] = seed
	return p


static func riftline_lanes(seed: int = 1) -> Dictionary:
	var p: Dictionary = _base("riftline_defense")
	p["display_name"] = "Riftline Defense"
	var lanes: Array = []
	for i in range(4):
		lanes.append({
			"lane": i,
			"y": 120 + i * 140,
			"art_status": ART_STATUS_SCAFFOLD,
			"HUMAN_ART": false,
			"echo_path": true,
		})
	p["elements"] = [
		{"id": "lane_rails", "kind": "four_lanes", "lanes": lanes, "HUMAN_ART": false},
		{"id": "fracture_echo_silhouettes", "kind": "echo_sprites", "is_real_puppet": false, "HUMAN_ART": false, "art_status": ART_STATUS_PLACEHOLDER},
		{"id": "fighter_projectile_chrome", "kind": "identity_projectiles", "HUMAN_ART": false},
	]
	p["seed"] = seed
	return p


static func survival_echoes(seed: int = 1) -> Dictionary:
	var p: Dictionary = _base("echoes_gauntlet")
	p["display_name"] = "Echoes of Convergence"
	p["elements"] = [
		{
			"id": "echo_adds",
			"kind": "survival_echo_swarm",
			"art_status": ART_STATUS_PLACEHOLDER,
			"HUMAN_ART": false,
			"echoes_are_real_puppets": false,
			"echoes_are_souls": false,
		},
		{
			"id": "boss_simulation_plates",
			"kind": "boss_silhouettes",
			"art_status": ART_STATUS_SCAFFOLD,
			"HUMAN_ART": false,
			"bosses_are_simulations": true,
			"canonical_cosmic_defeat": false,
		},
		{
			"id": "origin_mirage_banner",
			"kind": "lore_banner",
			"text": "Origin Mirage — simulation only",
			"HUMAN_ART": false,
		},
	]
	p["seed"] = seed
	return p


static func unbound_colossus(seed: int = 1, preset_id: String = "colossus_clash") -> Dictionary:
	var p: Dictionary = _base("convergence_unbound")
	p["display_name"] = "Convergence Unbound"
	p["label"] = "UNBALANCED MYTHIC"
	var rigs: Array = Colossus.spawn_for_preset(preset_id, seed)
	var camera_scaffold: Array = []
	for rig in rigs:
		camera_scaffold.append({
			"rig_id": rig.get("rig_id", ""),
			"collision": rig.get("collision", {}),
			"camera": Colossus.camera_profile_for_battle(rig),
			"HUMAN_ART": false,
			"final_rig_approved": false,
		})
	p["elements"] = [
		{"id": "mythic_banner", "kind": "label_strip", "text": "UNBALANCED MYTHIC · never ranked MMR", "HUMAN_ART": false},
		{"id": "colossus_collision_scaffolds", "kind": "scale_aware_capsules", "rigs": camera_scaffold, "HUMAN_ART": false},
		{"id": "spectacle_camera", "kind": "camera_scaffold", "a11y_reduce_motion_respected": true, "HUMAN_ART": false},
	]
	p["feeds_ranked_mmr"] = false
	p["seed"] = seed
	p["preset_id"] = preset_id
	return p


static func assert_no_human_art(payload: Dictionary) -> bool:
	if bool(payload.get("HUMAN_ART", false)):
		return false
	if bool(payload.get("HUMAN_ART_APPROVED", false)):
		return false
	for el in payload.get("elements", []):
		if typeof(el) != TYPE_DICTIONARY:
			continue
		if bool(el.get("HUMAN_ART", false)) or bool(el.get("HUMAN_ART_APPROVED", false)):
			return false
	return true
