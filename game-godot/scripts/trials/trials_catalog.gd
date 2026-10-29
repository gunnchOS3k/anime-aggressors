extends RefCounted
class_name TrialsCatalog
## Player-facing Trials of Convergence registry helpers.

const Authority = preload("res://scripts/trials/mode_authority.gd")


static func entries() -> Array:
	return Authority.load_catalog().get("modes", [])


static func display_rows() -> Array:
	var rows: Array = []
	for m in entries():
		if typeof(m) != TYPE_DICTIONARY:
			continue
		rows.append({
			"id": str(m.get("id", "")),
			"title": str(m.get("display_name", "")),
			"subtitle": str(m.get("subtitle", "")),
			"scene_key": str(m.get("scene_key", "")),
			"players": Authority.player_count_truth(str(m.get("id", ""))),
			"feeds_ranked_mmr": bool(m.get("feeds_ranked_mmr", false)),
			"label": str(m.get("label", "")),
		})
	return rows


static func scene_key_for(mode_id: String) -> String:
	var e: Dictionary = Authority.mode_entry(mode_id)
	return str(e.get("scene_key", ""))
