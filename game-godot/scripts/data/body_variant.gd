extends RefCounted
class_name BodyVariant

## First-class presentation field. Never affects combat simulation.

const MALE := "male"
const FEMALE := "female"
const ALLOWED := [MALE, FEMALE]


static func normalize(value: String) -> String:
	var v := value.strip_edges().to_lower()
	if v in ALLOWED:
		return v
	return MALE


static func alternate(value: String) -> String:
	return FEMALE if normalize(value) == MALE else MALE


static func allocate_for_seats(fighter_id: String, existing: Array) -> String:
	## Prefer unused body presentation for duplicate fighter picks.
	var used_male := 0
	var used_female := 0
	for entry in existing:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if str(entry.get("fighter_id", "")) != fighter_id:
			continue
		if normalize(str(entry.get("body_variant", MALE))) == FEMALE:
			used_female += 1
		else:
			used_male += 1
	if used_male == 0:
		return MALE
	if used_female == 0:
		return FEMALE
	# >2: keep cycling but seat accent will distinguish
	return MALE if (used_male + used_female) % 2 == 0 else FEMALE


static func seat_accent_required(fighter_id: String, body_variant: String, existing: Array) -> bool:
	var count := 0
	for entry in existing:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if str(entry.get("fighter_id", "")) == fighter_id and normalize(str(entry.get("body_variant", MALE))) == normalize(body_variant):
			count += 1
	return count >= 1


static func match_payload(fighter_id: String, body_variant: String, seat_id: int, team_id: int = 0) -> Dictionary:
	return {
		"fighter_id": fighter_id,
		"body_variant": normalize(body_variant),
		"seat_id": seat_id,
		"team_id": team_id,
	}
