extends SceneTree

## Headless gate smoke for dual-form roster contract.


func _init() -> void:
	var ok := true
	var roster := ["ember-vale","rook-ironside","juno-spark","kaia-windrow","nix-calder","orion-vell","vesper-nyx"]
	if roster.size() != 7:
		ok = false
	var picks: Array = []
	for i in range(8):
		picks.append({"seat_id": i + 1, "fighter_id": "rook-ironside", "team_id": i % 2})
	var assigned: Array = PartyLinkVariantAllocator.allocate(picks)
	if assigned.size() != 8:
		ok = false
	var males := 0
	var females := 0
	for a in assigned:
		if str(a.get("body_variant", "")) == "female":
			females += 1
		else:
			males += 1
	# first two should differ
	if str(assigned[0].get("body_variant")) == str(assigned[1].get("body_variant")):
		ok = false
	var path := "res://data/dual_form_roster_v4.json"
	if not FileAccess.file_exists(path):
		ok = false
	print("V4_DUAL_FORM_GATES ", "PASS" if ok else "FAIL", " males=", males, " females=", females)
	quit(0 if ok else 1)
