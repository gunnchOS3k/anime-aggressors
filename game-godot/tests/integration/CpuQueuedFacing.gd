extends SceneTree
## Input-intent regression, not native contact/AI difficulty acceptance.
const Cpu = preload("res://scripts/fighters/cpu_controller.gd")
const Stub = preload("res://tests/vxp22_hf/HfCpuStub.gd")
var failures: Array = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var actor = Stub.new();root.add_child(actor)
	var opponent = Stub.new();root.add_child(opponent)
	var cpu = Cpu.new();cpu.setup(actor,1,739)
	for direction in [-1,1]:
		actor.global_position=Vector2.ZERO;opponent.global_position=Vector2(25*direction,0)
		actor.facing=-direction;actor._on_floor=true;actor._pending_attack_cmd=""
		cpu.tick(1.0/60,opponent)
		check(axis()==-direction,"Original unqueued back-spacing preserved")
		actor.queue_attack_command("attack_neutral")
		cpu.tick(1.0/60,opponent)
		check(axis()==direction,"Queued attack must request turn toward observed opponent")
		check(actor.facing==-direction,"CPU must not bypass Fighter's facing authority")
		check(actor._pending_attack_cmd=="attack_neutral","Original command preserved")
		actor._on_floor=false
		cpu.tick(1.0/60,opponent)
		check(axis()==0,"Airborne facing/back-air policy preserved")
	actor.controls_enabled=false
	Input.action_press("p2_right")
	cpu.tick(1.0/60,opponent)
	check(axis()==0,"Locked controls must clear CPU input")
	actor.controls_enabled=true;actor._on_floor=true
	actor.global_position=Vector2(470,0);opponent.global_position=Vector2(520,0)
	actor.facing=-1;actor._pending_attack_cmd="attack_neutral"
	cpu.tick(1.0/60,opponent)
	check(axis()<0,"Edge recovery must outrank an outward queued attack")
	cpu.clear_simulated_inputs();actor.free();opponent.free()
	if failures.is_empty():print("CPU_QUEUED_FACING_PASS: both directions, back-spacing and airborne policy retained")
	else:push_error(JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func axis() -> int:
	return int(Input.is_action_pressed("p2_right"))-int(Input.is_action_pressed("p2_left"))

func check(ok: bool, message: String) -> void:
	if not ok:failures.append(message)
