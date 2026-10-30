extends RefCounted
class_name RosamerePresentationHud
## Presentation-only HUD card for Rosamere three-form + cosmology honesty.
## Versus / training surfaces. ≠ HUMAN_ART. Does not touch HitResolver / Codex combat.

const Presentation = preload("res://scripts/visual/rosamere_form_presentation.gd")

const HUD_NAME := "RosamerePresentationCardHud"
const SLOT_META := "rosamere_presentation_hud_slot"


static func fighter_is_rosamere(fighter: Node) -> bool:
	if fighter == null or not is_instance_valid(fighter):
		return false
	if str(fighter.get("fighter_id")) == "rosamere":
		return true
	return false


static func resolve_form_id(fighter: Node) -> String:
	if fighter != null and fighter.has_method("get_current_form_id"):
		var cur := str(fighter.get_current_form_id())
		if not cur.is_empty():
			return cur
	if fighter != null and fighter.has_meta("rosamere_presentation"):
		var pres: Dictionary = fighter.get_meta("rosamere_presentation")
		var fid := str(pres.get("form_id", ""))
		if not fid.is_empty():
			return fid
	return "FAMILIAR_ROSE"


static func build_card_text(fighter: Node, mode: String = "") -> String:
	var form_id := resolve_form_id(fighter)
	var card: Dictionary = Presentation.presentation_card_for_form(form_id)
	var gray: Dictionary = Presentation.domain_honesty_surface("prismatic_gray")
	var puppet: Dictionary = Presentation.domain_honesty_surface("puppet")
	var lines: PackedStringArray = []
	lines.append("Rosamere · %s · %s" % [
		str(card.get("roman", "")),
		str(card.get("form_id", form_id)),
	])
	var line := str(card.get("presentation_line", ""))
	if not line.is_empty():
		lines.append(line)
	lines.append("Choreography stub (%s) ≠ HUMAN_ART" % str(card.get("transform_beat", "idle")))
	lines.append("Yin/Yang created by Pink · not Pink forms")
	var puppet_line := str(puppet.get("presentation_line", ""))
	if not puppet_line.is_empty():
		lines.append(puppet_line)
	var gray_line := str(gray.get("presentation_line", ""))
	if not gray_line.is_empty():
		lines.append(gray_line)
	lines.append("HitResolver untouched · presentation-only")
	if not mode.is_empty():
		lines.append("Mode: %s" % mode)
	return "\n".join(lines)


static func mount_on_hud(hud: Node, fighters: Array, mode: String = "") -> Dictionary:
	## Attach/update presentation card labels under battle/training HUD.
	## Returns honesty payload for tests; never mutates combat state.
	if hud == null or not is_instance_valid(hud):
		return {"ok": false, "reason": "no_hud", "HUMAN_ART_APPROVED": false}
	var mounted: Array = []
	var slot := 0
	for fighter in fighters:
		if not fighter_is_rosamere(fighter):
			continue
		slot += 1
		var name := "%s_P%d" % [HUD_NAME, slot]
		var label: Label = hud.get_node_or_null(name) as Label
		if label == null:
			label = Label.new()
			label.name = name
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size = Vector2(420, 0)
			label.add_theme_font_size_override("font_size", 12)
			label.modulate = Color(1.0, 0.82, 0.9, 0.92)
			## Training: top-left under move list; versus P1 left / P2 right-ish.
			if slot == 1:
				label.position = Vector2(24, 150)
			else:
				label.position = Vector2(24, 280)
			hud.add_child(label)
		label.set_meta(SLOT_META, slot)
		label.text = build_card_text(fighter, mode)
		label.visible = true
		mounted.append({
			"slot": slot,
			"form_id": resolve_form_id(fighter),
			"label_name": name,
			"text": label.text,
		})
	## Hide stale cards when Rosamere leaves the matchup.
	for child in hud.get_children():
		if child is Label and str(child.name).begins_with(HUD_NAME) and not child.has_meta(SLOT_META):
			pass
		elif child is Label and str(child.name).begins_with(HUD_NAME):
			var keep := false
			for row in mounted:
				if str(row.get("label_name", "")) == str(child.name):
					keep = true
					break
			if not keep:
				child.visible = false
	return {
		"ok": not mounted.is_empty(),
		"mounted": mounted,
		"count": mounted.size(),
		"HUMAN_ART_APPROVED": false,
		"choreography_is_human_art": false,
		"HitResolver_untouched": true,
		"Codex_combat_data_untouched": true,
		"presentation_only": true,
		"mode": mode,
	}


static func refresh_fighter_card(hud: Node, fighter: Node, mode: String = "") -> bool:
	if hud == null or not fighter_is_rosamere(fighter):
		return false
	for child in hud.get_children():
		if child is Label and str(child.name).begins_with(HUD_NAME) and child.visible:
			## Prefer matching by form refresh of all Rosamere cards.
			pass
	var result: Dictionary = mount_on_hud(hud, [fighter], mode)
	return bool(result.get("ok", false))


static func find_mounted_labels(hud: Node) -> Array:
	var out: Array = []
	if hud == null:
		return out
	for child in hud.get_children():
		if child is Label and str(child.name).begins_with(HUD_NAME) and child.visible:
			out.append(child)
	return out
