extends RefCounted
## Original source-morph direction, sampled by the existing gameplay sequence.
## No anatomy, skeletal timing, gameplay state or independent phase timer.
static var _score: Dictionary = {}

static func sample(fighter: String, target_form: String, phase: float) -> Dictionary:
	if _score.is_empty():
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/animation/facial_performance_8d.json"))
		if doc is Dictionary:_score = doc
	var profile: Dictionary = _score.get("fighters", {}).get(fighter, {})
	var step := ""
	for candidate in ["AWAKENED_BUILD", "ASCENDED", "COSMIC_SURGE", "COSMIC_ASCENDANT"]:
		if target_form.ends_with(candidate):step = candidate;break
	for stage in profile.get("stages", []):
		if stage.ladder_step != step:continue
		var keys: Array = stage["keys"]
		var t := clampf(phase, 0.0, 1.0)
		for index in range(1, keys.size()):
			var left: Dictionary = keys[index-1]
			var right: Dictionary = keys[index]
			if t > float(right.phase):continue
			var u := clampf((t-float(left.phase))/maxf(float(right.phase)-float(left.phase),.00001),0,1)
			u = u*u*(3.0-2.0*u)
			var weights: Dictionary = {}
			for channel in _score.get("channels", []):
				weights[channel] = lerpf(float(left.weights.get(channel,0)),float(right.weights.get(channel,0)),u)
			return weights
	return {}
