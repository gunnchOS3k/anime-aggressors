extends RefCounted
## Describes the EXISTING independent state domains; does not grant a form,
## receipt, stat modifier or unlock. A clip alias is never a gameplay move ID.
const SPECTRUM := ["ember-vale","rook-ironside","juno-spark","kaia-windrow","nix-calder","orion-vell","vesper-nyx"]
const COSMIC := ["yin","yang"]
const PINK := ["rosamere"]
const PINK_MANIFESTATIONS := ["FAMILIAR_ROSE", "FIRST_BLOOM", "EVERLASTING_ORIGIN"]
const ESSENCE_COUNTS := [0,1,2,4,6]

static func describe(fighter_id: String, state: String, legacy: Dictionary = {}) -> Dictionary:
	var spectrum := fighter_id in SPECTRUM
	var cosmic := fighter_id in COSMIC
	var pink := fighter_id in PINK
	var result := {"applicable":false,"state":state,"domain":"unknown","asset_form":"","grants_progress":false,"human_approved":false}
	if pink:
		if state == "COMPETITIVE_SELF_LIMITED":
			return {"applicable":true,"state":state,"domain":"gameplay_contract","asset_form":"FAMILIAR_ROSE","attaches_to_form":"FAMILIAR_ROSE","is_story_form":false,"fourth_form":false,"grants_progress":false,"human_approved":false,"final_art_approved":false}
		if state in PINK_MANIFESTATIONS or state == "BASE" or legacy.get("forms", {}).has(state):
			var form_id := "FAMILIAR_ROSE" if state == "BASE" else state
			return {"applicable":true,"state":form_id,"domain":"primordial_pink_three_form_canon","asset_form":form_id,"gameplay_owner":"RosamereFormSelection + PinkBloomSystems","story_alias":false,"manifestation_count":3,"grants_progress":false,"human_approved":false,"final_art_approved":false}
		return result
	if not spectrum and not cosmic: return result
	if state == "BASE":
		result.merge({"applicable":true,"domain":"playable_base","asset_form":"BASE"},true)
	elif legacy.get("forms",{}).has(state) and (spectrum or (cosmic and legacy.get("state_domain","")=="cosmic_playable_advancement")):
		result.merge({"applicable":true,"domain":"legacy_aura_ladder" if spectrum else "cosmic_playable_advancement","asset_form":"BASE","gameplay_owner":"TransformPipeline + literal move_overrides","story_alias":false},true)
	elif spectrum and state in ["BLACK_PUPPET","WHITE_PUPPET","PRISMATIC_GRAY"]:
		result.merge({"applicable":true,"domain":"story_visual_variant","asset_form":state,"gameplay_owner":"signed CampaignRuntime / Story encounter","dedicated_combat_acting_verified":false},true)
	elif spectrum and state.begins_with("ESSENCE_"):
		var suffix := state.trim_prefix("ESSENCE_")
		if suffix in ["0","1","2","4","6"]:
			var count := int(suffix)
			result.merge({"applicable":true,"domain":"story_progression","essence":count,"asset_form":"PRISMATIC_GRAY" if count==6 else "BASE","intermediate_collectible_visual_implemented":false,"selection_owner":"signed CampaignRuntime; descriptor cannot award Essences"},true)
	elif cosmic and state == "COSMIC_BOSS":
		result.merge({"applicable":true,"domain":"story_cosmic_context","asset_form":"COSMIC_BOSS","gameplay_status":"ARCHITECTURE_ONLY distinct boss kit; current Story encounter context exists"},true)
	return result
