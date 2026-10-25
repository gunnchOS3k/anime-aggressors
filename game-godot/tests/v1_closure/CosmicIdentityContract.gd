extends SceneTree
const Identity=preload("res://scripts/combat/aura_identity.gd")
const Runtime=preload("res://scripts/combat/aura_special_runtime.gd")
var output:=""
func _init():call_deferred("run")
func run():
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
	var failures:Array=[];var audit:Dictionary=Runtime.audit_roster_runtime()
	if not audit.ok or audit.fighter_count!=9:failures.append("nine_distinct_profile_contracts")
	for fid in ["yin","yang"]:
		var p=Identity.profile_for(fid,"burn_rushdown")
		if p.tag=="burn_rushdown" or p.get("trail_damage",0)>0 or p.get("hitbox_extend_px",0)>0:failures.append(fid+":Ember_inheritance")
		var source={"move_id":"side_special","damage":7.0,"hitboxes":[{"width":40,"height":32}],"element_effect":{"type":"flame","effect":"burn"}}
		var move=Identity.apply_to_scaled_move(source,fid,90,"burn_rushdown")
		if move.damage!=7 or move.hitboxes!=source.hitboxes or move.element_effect.type!=("void" if fid=="yin" else "radiance"):failures.append(fid+":identity_without_numeric_leak")
	var f=FileAccess.open(output.path_join("cosmic_identity_contract.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"audit":audit,"scope":"profile/identity routing audit; live mechanics and human balance are separate"},"  "));f.close()
	print("COSMIC_IDENTITY ","PASS" if failures.is_empty() else "FAIL");quit(0 if failures.is_empty() else 1)
