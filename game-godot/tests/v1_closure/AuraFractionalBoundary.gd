extends SceneTree
## Continuous meter selection must use existing integer-authored tiers.
## Exhaustive integer scaling hashes bind every roster move before/after.
const Scaler=preload("res://scripts/combat/aura_scaler.gd")
const Data=preload("res://scripts/data/data_loader.gd")
const Renderer=preload("res://scripts/visual/spectral_feedback_renderer.gd")
var output := ""
var baseline := ""
func _init() -> void:call_deferred("_run")
func _run() -> void:
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ordinary-output="):output=arg.get_slice("=",1)
		if arg.begins_with("--aura-integer-baseline="):baseline=arg.get_slice("=",1)
	var failures: Array=[];var rows: Array=[];var hashes: Dictionary={};var move_count:=0
	var samples=[0.0,24.0,24.001,24.999,25.0,49.0,49.5,49.999,50.0,74.0,74.5,74.999,75.0,99.0,99.2,99.999,100.0]
	for fid in Renderer.IDS:
		var manifest: Dictionary=Data.load_moves(fid)
		var moves: Array=manifest.get("moves",[])
		move_count+=moves.size()
		var hash_context:=HashingContext.new();hash_context.start(HashingContext.HASH_SHA256)
		for move in moves:
			for integer in range(101):hash_context.update(JSON.stringify(Scaler.apply_to_move(move,float(integer))).to_utf8_buffer())
		hashes[fid]=hash_context.finish().hex_encode()
		for amount in samples:
			var expected:=4 if amount>=100 else 3 if amount>=75 else 2 if amount>=50 else 1 if amount>=25 else 0
			var actual:=Scaler.aura_level(amount)
			var name: String=Scaler.LEVELS[expected].name
			if actual!=expected or Scaler.aura_level_name(amount)!=name:failures.append(fid+":"+str(amount)+":tier")
			var differences:=0
			for move in moves:
				if Scaler.apply_to_move(move,amount)!=Scaler.apply_to_move(move,floorf(amount)):differences+=1
			if differences>0:failures.append(fid+":"+str(amount)+":existing_scaled_values")
			if Scaler.projectile_value_by_aura([0,1,2,3,4],amount)!=expected:failures.append(fid+":"+str(amount)+":projectile_tier")
			rows.append({"fighter":fid,"amount":amount,"expected_existing_tier":expected,"actual":actual,"scaled_move_mismatches":differences})
	if not baseline.is_empty():
		var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(baseline))
		if hashes!=prior.integer_scaling_hashes:failures.append("accepted_integer_scaling_changed")
	var f=FileAccess.open(output.path_join("aura_fractional_boundary.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"PASS":failures.is_empty(),"failures":failures,"rows":rows,"moves":move_count,"integer_levels_checked":101,"integer_scaling_hashes":hashes,"scope":"All roster move dictionaries/approved scaling, no actor or competitive results modified"},"  "));f.close()
	print("AURA_FRACTIONAL_BOUNDARY ","PASS" if failures.is_empty() else "FAIL"," rows=",rows.size()," moves=",move_count," failures=",failures.size());quit(0 if failures.is_empty() else 1)
