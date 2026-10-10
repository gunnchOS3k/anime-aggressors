extends Node2D
class_name LaunchTrailSystem
## Discrete original smoke volumes follow real victim displacement during hitstun.
const _Renderer = preload("res://scripts/visual/spectral_feedback_renderer.gd")
var _active := false
var _target: WeakRef
var _fid := ""
var _tier := "LOW"
var _last := Vector2.ZERO
var _distance := 0.0
var _elapsed := 0.0
var emitted := 0
func begin(defender: Node2D, attacker_id: String, tier: String) -> void:
	_target=weakref(defender);_fid=attacker_id;_tier=tier;_active=tier!="LOW";_last=defender.global_position;_distance=0;_elapsed=0;emitted=0
func follow(defender: Node2D, velocity: Vector2) -> void:
	if not _active or defender == null: return
	var displacement := defender.global_position-_last
	_last=defender.global_position
	_distance+=displacement.length()
	var renderer = _Renderer.obtain(defender)
	if renderer == null: return
	var spacing := 9.0 if renderer.option("reduced_particles") else 3.0
	if _distance>=spacing:
		_distance=0
		# Density, extent and lifetime follow authentic velocity, not a fabricated line length.
		var strength := clampf(velocity.length()/160.0,.1,1.0)
		var extent := 16.0+strength*34.0
		renderer.emit_effect(_fid,4,defender.global_position+Vector2(0,-24),-velocity.normalized(),extent,.24+strength*.25)
		emitted+=1
func end() -> void: _active=false
func clear() -> void: _active=false;_distance=0
func _physics_process(delta: float) -> void:
	if not _active or _target == null: return
	var target = _target.get_ref()
	if target == null: clear();return
	if "_hitstop" in target and target._hitstop>0:return
	if "state_machine" in target and target.state_machine.current_state not in ["hitstun","launched","tumble","hurt_light","hurt_heavy"]:
		end();return
	_elapsed+=delta
	if ("hitstun_remaining" in target and target.hitstun_remaining<=0) or _elapsed>1.0:
		end();return
	follow(target,target.velocity if "velocity" in target else Vector2.ZERO)
