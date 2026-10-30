extends RefCounted
class_name AccessibilitySurface
## Digital accessibility polish for Trials / Rosamere HUD / Story surfaces.
## Reduced motion, focus neighbors, SR/label metadata — not a device matrix pass.
## Does not invent physical device certification or claim WCAG product audit complete.
## HitResolver / Codex combat untouched.

const META_SR_NAME := "a11y_sr_name"
const META_SR_DESC := "a11y_sr_description"
const META_FOCUS_ORDER := "a11y_focus_order"
const META_REDUCE_MOTION := "a11y_reduce_motion_applied"


static func device() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("DeviceRoleRuntime")


static func reduce_motion_active() -> bool:
	var d := device()
	if d != null and d.get("reduce_motion") != null:
		return bool(d.reduce_motion)
	return bool(ProjectSettings.get_setting("anime_aggressors/accessibility/reduce_motion_user", false))


static func larger_ui_active() -> bool:
	var d := device()
	if d != null and d.get("larger_ui") != null:
		return bool(d.larger_ui)
	return bool(ProjectSettings.get_setting("anime_aggressors/accessibility/larger_ui", false))


static func label_control(control: Control, sr_name: String, sr_description: String = "") -> Dictionary:
	## Digital SR/label: accessibility_* when present; tooltip + meta always.
	if control == null or not is_instance_valid(control):
		return {"ok": false, "reason": "invalid_control"}
	control.set_meta(META_SR_NAME, sr_name)
	control.set_meta(META_SR_DESC, sr_description)
	if sr_description.is_empty():
		control.tooltip_text = sr_name
	else:
		control.tooltip_text = "%s — %s" % [sr_name, sr_description]
	## Prefer engine accessibility_* when the Control exposes them (Godot 4.x).
	var props: Array = control.get_property_list()
	var has_name := false
	var has_desc := false
	for p in props:
		var pname := str(p.get("name", ""))
		if pname == "accessibility_name":
			has_name = true
		elif pname == "accessibility_description":
			has_desc = true
	if has_name:
		control.set("accessibility_name", sr_name)
	if has_desc and not sr_description.is_empty():
		control.set("accessibility_description", sr_description)
	## Ensure focusable buttons can be keyboard/gamepad reached.
	if control is BaseButton and control.focus_mode == Control.FOCUS_NONE:
		control.focus_mode = Control.FOCUS_ALL
	return {
		"ok": true,
		"sr_name": sr_name,
		"sr_description": sr_description,
		"tooltip": control.tooltip_text,
		"focus_mode": control.focus_mode,
		"engine_accessibility_name": has_name,
		"device_matrix_pass": false,
		"HUMAN_ART_APPROVED": false,
	}


static func wire_focus_row(controls: Array) -> Dictionary:
	## Linear focus neighbors for a button/control row (digital focus polish).
	var focusable: Array = []
	for c in controls:
		if c is Control and is_instance_valid(c) and (c as Control).visible:
			var ctrl := c as Control
			if ctrl is BaseButton or ctrl.focus_mode != Control.FOCUS_NONE:
				if ctrl is BaseButton and ctrl.focus_mode == Control.FOCUS_NONE:
					ctrl.focus_mode = Control.FOCUS_ALL
				focusable.append(ctrl)
	for i in focusable.size():
		var cur: Control = focusable[i]
		var prev: Control = focusable[(i - 1 + focusable.size()) % focusable.size()]
		var next: Control = focusable[(i + 1) % focusable.size()]
		cur.focus_neighbor_left = cur.get_path_to(prev)
		cur.focus_neighbor_right = cur.get_path_to(next)
		cur.focus_neighbor_top = cur.get_path_to(prev)
		cur.focus_neighbor_bottom = cur.get_path_to(next)
		cur.set_meta(META_FOCUS_ORDER, i)
	if not focusable.is_empty():
		(focusable[0] as Control).grab_focus()
	return {
		"ok": true,
		"count": focusable.size(),
		"focus_wired": focusable.size() >= 2,
		"device_matrix_pass": false,
	}


static func apply_reduce_motion_to_label(label: Label) -> Dictionary:
	## Soften presentation-only motion cues on labels under reduce_motion.
	if label == null or not is_instance_valid(label):
		return {"ok": false}
	var on := reduce_motion_active()
	label.set_meta(META_REDUCE_MOTION, on)
	if on:
		## No animated pulse — steady readable modulate.
		label.modulate = Color(1, 1, 1, 1)
		if larger_ui_active():
			label.add_theme_font_size_override("font_size", maxi(14, int(label.get_theme_font_size("font_size")) + 2))
	return {
		"ok": true,
		"reduce_motion": on,
		"larger_ui": larger_ui_active(),
		"device_matrix_pass": false,
	}


static func trials_journey_a11y_contract(mode_id: String) -> Dictionary:
	## Digital Trials a11y contract — Prism markers beyond color; colossus reduce-motion.
	var Prism = load("res://scripts/trials/prism/prism_weave_sim.gd")
	var markers_ok := true
	if mode_id == "prism_weave" and Prism != null:
		var sample: Dictionary = Prism.create(1, 2)
		markers_ok = bool(sample.get("accessibility", {}).get("markers_beyond_color", false))
	var Colossus = load("res://scripts/trials/unbound/colossus_rig.gd")
	var colossus_cam := {}
	if Colossus != null and Colossus.has_method("spawn_for_preset"):
		var rigs: Array = Colossus.spawn_for_preset("colossus_clash", 7)
		if not rigs.is_empty() and Colossus.has_method("camera_profile_for_battle"):
			colossus_cam = Colossus.camera_profile_for_battle(rigs[0])
	return {
		"ok": true,
		"mode_id": mode_id,
		"reduce_motion": reduce_motion_active(),
		"larger_ui": larger_ui_active(),
		"shared_input_grammar": true,
		"prism_markers_beyond_color": markers_ok if mode_id == "prism_weave" else null,
		"colossus_a11y_reduce_motion_respected": bool(colossus_cam.get("a11y_reduce_motion_respected", true)),
		"device_matrix_pass": false,
		"owner_a11y_playtest": false,
		"WCAG_product_audit": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
	}


static func polish_menu_surface(root: Node, surface_id: String, button_labels: Dictionary = {}) -> Dictionary:
	## Label + focus polish for a menu/journey surface. button_labels: node_name → sr_name.
	if root == null or not is_instance_valid(root):
		return {"ok": false, "reason": "no_root"}
	var labeled: Array = []
	var buttons: Array = []
	for child in root.find_children("*", "BaseButton", true, false):
		buttons.append(child)
		var sr := str(button_labels.get(str(child.name), child.text if child.get("text") != null else str(child.name)))
		var desc := "%s control on %s. Digital a11y polish — not device matrix pass." % [sr, surface_id]
		label_control(child, sr, desc)
		labeled.append(str(child.name))
	## Status / body labels get SR names when present.
	for child in root.find_children("*", "Label", true, false):
		var nm := str(child.name)
		if nm in ["JourneyStatus", "RosamereStoryPresentationHook"] or nm.begins_with("RosamerePresentationCardHud"):
			label_control(child, nm, "Status text for %s" % surface_id)
			apply_reduce_motion_to_label(child)
			labeled.append(nm)
	var focus: Dictionary = wire_focus_row(buttons)
	return {
		"ok": true,
		"surface_id": surface_id,
		"labeled": labeled,
		"focus": focus,
		"reduce_motion": reduce_motion_active(),
		"device_matrix_pass": false,
		"HUMAN_ART_APPROVED": false,
	}


static func validate_digital_a11y() -> Dictionary:
	var failures: Array = []
	## Contract: reduce_motion can be toggled via DeviceRoleRuntime without inventing devices.
	var d := device()
	if d == null:
		failures.append("device_role_runtime_missing")
	else:
		var before := bool(d.reduce_motion)
		if d.has_method("set_reduce_motion"):
			d.set_reduce_motion(true)
			if not bool(d.reduce_motion):
				failures.append("reduce_motion_set_true_failed")
			d.set_reduce_motion(before)
	var prism_contract: Dictionary = trials_journey_a11y_contract("prism_weave")
	if not bool(prism_contract.get("prism_markers_beyond_color", false)):
		failures.append("prism_markers_missing")
	var unbound: Dictionary = trials_journey_a11y_contract("convergence_unbound")
	if not bool(unbound.get("colossus_a11y_reduce_motion_respected", false)):
		failures.append("colossus_reduce_motion_flag_missing")
	if bool(prism_contract.get("device_matrix_pass", true)):
		failures.append("must_not_claim_device_matrix_pass")
	if bool(prism_contract.get("WCAG_product_audit", true)):
		failures.append("must_not_claim_wcag_audit")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"reduce_motion_api": d != null,
		"device_matrix_pass": false,
		"owner_a11y_playtest": false,
		"WCAG_product_audit": false,
		"HUMAN_ART_APPROVED": false,
		"SHIPPING_ROLLBACK_ENABLED": false,
		"HitResolver_untouched": true,
	}
