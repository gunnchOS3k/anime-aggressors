extends SceneTree
## Pure state/data contract checks. No seeded campaign or unlock acceptance.
const Forms = preload("res://scripts/combat/form_definition.gd")
const Authority = preload("res://scripts/combat/form_state_authority.gd")
const Data = preload("res://scripts/data/data_loader.gd")
var failures: Array = []
var rows: Array = []
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)
func run() -> void:
	await process_frame
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="): output=arg.get_slice("=",1)
	for fid in Authority.SPECTRUM + Authority.COSMIC:
		var manifest: Dictionary = Data.load_moves(fid)
		var doc: Dictionary = Forms.load_forms(fid)
		check(manifest.moves.size()==24,fid+":24moveIDs")
		check(not Authority.describe(fid,"BASE",doc).grants_progress,fid+":descriptor_never_unlocks")
		for state in ["BASE","BLACK_PUPPET","WHITE_PUPPET","PRISMATIC_GRAY","ESSENCE_0","ESSENCE_1","ESSENCE_2","ESSENCE_4","ESSENCE_6","COSMIC_BOSS"]:
			var descriptor: Dictionary = Forms.describe_state(fid,state)
			var applicable: bool = state=="BASE" or (fid in Authority.SPECTRUM and state!="COSMIC_BOSS") or (fid in Authority.COSMIC and state=="COSMIC_BOSS")
			check(descriptor.applicable==applicable,fid+state+":canon_applicability")
			check(not descriptor.grants_progress,fid+state+":no_earned_authority")
			if descriptor.applicable:
				for body in ["male","female"]:
					check(ResourceLoader.exists("res://assets/characters/collectible_v1/%s/%s/%s.glb"%[fid,body,descriptor.asset_form]),fid+state+body+":resource")
			rows.append({"fighter":fid,"state":state,"descriptor":descriptor})
		check(not Forms.describe_state(fid,"ESSENCE_3").applicable,fid+":no_unapproved_essence3")
		if fid in Authority.COSMIC:
			check(doc.get("state_domain","")=="cosmic_playable_advancement",fid+":separate_playable_cosmic_ladder")
			check(doc.get("tuning_status","")=="TUNING_CANDIDATE",fid+":not_final_balance")
			check(not doc.canon_policy.grants_story_progress and not doc.canon_policy.boss_immunity,fid+":no_boss_or_story_grant")
		check(doc.form_ladder.size()==3,fid+":preserved_ladder")
		for state in doc.form_ladder:
			check(Forms.describe_state(fid,state).domain==("legacy_aura_ladder" if fid in Authority.SPECTRUM else "cosmic_playable_advancement"),fid+state+":not_story_alias")
			var entry: Dictionary=Forms.form_entry(doc,state)
			check(is_equal_approx(Forms.body_scale(entry),1.0),fid+state+":canonical_scale")
			for mid in Forms.move_overrides(entry):
				var base: Dictionary=Data.find_move(manifest,mid)
				check(not base.is_empty(),fid+state+mid+":live_override_ID")
				var original:=base.duplicate(true)
				var actual: Dictionary=Forms.apply_move_override(base,entry,mid)
				check(base==original,fid+state+mid+":no_manifest_mutation")
				for field in entry.move_overrides[mid]:check(actual.get(field)==entry.move_overrides[mid][field],fid+state+mid+str(field)+":existing_payload")
	var ember:=Forms.form_entry(Forms.load_forms("ember-vale"),"EMBER_ASCENDED")
	var burst: Dictionary=Data.find_move(Data.load_moves("ember-vale"),"aura_burst")
	var result: Dictionary=Forms.apply_move_override(burst,ember,"aura_burst")
	check(result.damage==14.0 and result.training_display_name=="Ascension Rush",":original_Ember_payload_restored")
	for key in ["startup_frames","active_frames","recovery_frames","hitstop_frames","base_knockback","knockback_growth","launch_angle_degrees","hitboxes"]:
		check(result.get(key)==burst.get(key),":unchanged_Ember_burst_"+key)
	check(not ember.move_overrides.has("signature_lane_burst"),":clip_alias_not_override_key")
	var f=FileAccess.open(output.path_join("form_state_authority.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"scope":"existing state domains, resources and literal existing override payload; no visual, balance approval or earned progression"},"  "));f.close()
	print("FORM_STATE_AUTHORITY ","PASS" if failures.is_empty() else "FAIL");quit(0 if failures.is_empty() else 1)
