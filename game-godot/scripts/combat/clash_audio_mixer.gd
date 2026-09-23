extends RefCounted
class_name ClashAudioMixer

## Original / procedural placeholders only. No copyrighted audio.

const LAYERS := [
	"energy_bed_a",
	"energy_bed_b",
	"central_collision",
	"escalating_pressure",
	"strain_pulses",
	"environment_lf",
	"resolution_transient",
	"post_resolution_tail",
]


static func mix(a_id: String, b_id: String, winner: String) -> Dictionary:
	var reduce := false
	if Engine.get_main_loop() != null:
		var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState")
		if gs != null:
			reduce = not bool(gs.training_sfx_enabled)
	var cues: Array = []
	for layer in LAYERS:
		cues.append({
			"layer": layer,
			"cue_id": "aa_clash_%s" % layer,
			"loop": layer.begins_with("energy_bed") or layer == "escalating_pressure",
			"max_duration_frames": 48,
			"mix_priority": 80 if layer == "resolution_transient" else 40,
			"duck": layer == "environment_lf",
			"placeholder": true,
			"copyrighted": false,
			"stops_on_recover": true,
		})
	return {
		"a": a_id,
		"b": b_id,
		"winner": winner,
		"layers": cues,
		"silent": reduce,
		"loops_stop_on_recover": true,
		"HUMAN_AURA_CLASH_PASS": false,
	}
