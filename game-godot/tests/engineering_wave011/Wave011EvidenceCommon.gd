extends RefCounted
class_name Wave011EvidenceCommon

## Shared Wave011 evidence helpers — restage is TEST PRECONDITION only.

const ART_DIR := "res://artifacts/engineering_wave011"
const ROSTER := [
	"ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
	"nix-calder", "orion-vell", "vesper-nyx",
]

static var restage_count: int = 0


static func write_artifact(filename: String, payload: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ART_DIR))
	var f := FileAccess.open(ART_DIR.path_join(filename), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()


static func release_slot(slot: int) -> void:
	for suffix in ["left", "right", "up", "down", "jump", "attack", "special", "shield", "grab", "dodge"]:
		var action := "p%d_%s" % [slot, suffix]
		if InputMap.has_action(action):
			Input.action_release(action)


static func release_p1() -> void:
	release_slot(1)


static func release_p2() -> void:
	release_slot(2)


static func restage_on_platform(p1, p2, gap: float) -> void:
	## TEST PRECONDITION — not gameplay proof.
	restage_count += 1
	var floor_y: float = float(p1.spawn_point.y)
	if p2.is_on_floor() and not p1.is_on_floor():
		floor_y = p2.global_position.y
	elif p1.is_on_floor():
		floor_y = p1.global_position.y
	var cx: float = float(p1.platform_center_x)
	p1.global_position = Vector2(cx - gap * 0.5, floor_y)
	p2.global_position = Vector2(cx + gap * 0.5, floor_y)
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1.facing = 1
	p2.facing = -1


static func wait_frames(tree: SceneTree, n: int) -> void:
	for i in n:
		await tree.physics_frame


static func provenance_flags() -> Dictionary:
	return {
		"TEST_PRECONDITION_RESTAGE": true,
		"RESTAGE_COUNT": restage_count,
		"RESTAGE_USED_AS_GAMEPLAY_PROOF": false,
		"INPUT_INTENT_COUNTED_AS_SUCCESS": false,
		"battle_eval_mode": false,
		"production_gate_harness_used_as_proof": false,
		"aura_assign_used_as_charge_proof": false,
	}
