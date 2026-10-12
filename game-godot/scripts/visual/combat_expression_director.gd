extends Node
## Presentation observer. Aura remains owned exclusively by Fighter.
const FormDefinition=preload("res://scripts/combat/form_definition.gd")
var fighter: Node
var last_snapshot: Dictionary={}
var action_lines=preload("res://scripts/visual/action_line_director.gd").new()
func setup(owner_fighter: Node) -> void:
	fighter=owner_fighter
func _process(_delta: float) -> void:observe()
func observe() -> void:
	if not is_instance_valid(fighter) or fighter.model_3d==null or fighter.state_machine==null:return
	var state: String=fighter.state_machine.current_state
	var amount:=clampf(float(fighter.aura),0,100)
	var form: Dictionary=FormDefinition.form_entry(fighter.get_forms_doc(),fighter.get_current_form_id())
	var form_empowered:=str(form.get("ladder_step","BASE")) in ["AWAKENED_BUILD","ASCENDED"]
	var dialogue=get_node_or_null("/root/StoryDialogue")
	var options: Dictionary=dialogue.settings if dialogue!=null else {}
	var alive: bool=not state in ["ko","respawn"] and fighter.visible
	last_snapshot={"fighter_id":fighter.fighter_id,"body":fighter.model_3d.get_body_variant(),"amount":amount,"active":alive and (amount>.001 or form_empowered),"super_ready":alive and amount>=100.0,"ascension_ready":amount>=75.0,"visual_band":("maximum" if amount>=100 else "surging" if amount>=75 else "building" if amount>=50 else "growing" if amount>=25 else "subtle" if amount>0 else "calm"),"combat_level":fighter.get_aura_level(),"state":state,"form_empowered":form_empowered,"intensity":str(options.get("vfx_intensity","Balanced")),"reduced_particles":bool(options.get("reduced_particles",false)),"reduced_flash":bool(options.get("reduced_flash",false)),"high_contrast":bool(options.get("high_contrast_vfx",false)),"charging":state in ["aura_charge","aura_ready"],"grounded":fighter.is_on_floor(),"velocity":fighter.velocity,"gameplay_frame":Engine.get_physics_frames()}
	fighter.model_3d.set_empowerment_state(last_snapshot)
	action_lines.observe(fighter,last_snapshot)
	if bool(last_snapshot.active) and fighter._elemental_audio==null:
		fighter._elemental_audio=preload("res://scripts/audio/elemental_performance.gd").new()
		fighter._elemental_audio.name="ElementalPerformance";fighter.add_child(fighter._elemental_audio)
	if fighter._elemental_audio!=null:
		fighter._elemental_audio.set_fighter_identity(fighter.fighter_id)
		fighter._elemental_audio.update_empowerment(bool(last_snapshot.active) and not bool(last_snapshot.charging),amount/100.0)
