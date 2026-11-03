extends SceneTree
## Real ColossusActor nodes + capsule collision beyond dictionary scaffolds.

const Colossus = preload("res://scripts/trials/unbound/colossus_rig.gd")
const ColossusActor = preload("res://scripts/trials/unbound/colossus_actor.gd")
const Bridge = preload("res://scripts/trials/shared_combat_bridge.gd")
const Unbound = preload("res://scripts/trials/unbound/unbound_ruleset.gd")

var failures: Array = []
var checks := 0


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	await process_frame
	var root_node := Node2D.new()
	root_node.name = "ColossusProbeRoot"
	root.add_child(root_node)

	var rigs: Array = Colossus.spawn_for_preset("colossus_clash", 11)
	check(rigs.size() >= 2, "rig_dicts")
	var actors: Array = ColossusActor.spawn_preset(root_node, "colossus_clash", 11)
	check(actors.size() >= 2, "actors_spawned")
	for a in actors:
		check(a is CharacterBody2D, "character_body")
		check(a.get_node_or_null("BodyCapsule") != null, "body_capsule")
		check(a.get_node_or_null("Hurtbox") != null, "hurtbox_area")
		check(bool(a.get("beyond_dictionary_scaffold")) or bool(a.to_rig_dictionary().get("beyond_dictionary_scaffold", false)), "beyond_dict")
		check(not bool(a.HUMAN_ART_APPROVED), "art_false")
		var center: Vector2 = a.global_position
		var inside: Dictionary = a.overlap_point(center)
		check(bool(inside.get("inside", false)), "overlap_center")
		check(bool(inside.get("actor_node", false)), "overlap_actor_node")
		check(bool(inside.get("area2d_hurtbox", false)), "overlap_area2d")
		var far: Dictionary = a.overlap_point(center + Vector2(5000, 5000))
		check(not bool(far.get("inside", true)), "overlap_far_miss")
		a.tick_frame(12, 11)
		a.apply_hit(1.5, 1)
		check(int(a.hp) < int(a.max_hp), "hit_reduces_hp")
		check(not bool(a.to_rig_dictionary().get("canonical_cosmic_defeat", true)), "avatar_ko_not_true_defeat")

	## Bridge mounts actors after Unbound colossus prep.
	var gs = root.get_node_or_null("GameState")
	check(gs != null, "gamestate")
	if gs != null:
		var prep: Dictionary = Bridge.prepare_live_battle("convergence_unbound", 4, Unbound.PRESET_COLOSSUS, -1)
		check(bool(prep.get("ok", false)), "prep_colossus")
		check((gs.trial_colossus_rigs as Array).size() >= 2, "gs_rigs")
		var battle := Node2D.new()
		battle.name = "FakeBattle"
		root.add_child(battle)
		var mounted: Array = Bridge.mount_colossus_actors_on_battle(battle)
		check(mounted.size() >= 2, "mounted_actors")
		check(battle.get_node_or_null("ColossusActors") != null, "actors_root")
		check(bool(gs.trial_overlay_state.get("colossus_beyond_dictionary", false)), "overlay_beyond_dict")

	print("COLOSSUS_ACTOR_COLLISION ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
