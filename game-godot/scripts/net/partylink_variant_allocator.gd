extends RefCounted
class_name PartyLinkVariantAllocator

## 2/4/6/8-safe duplicate fighter body_variant allocation.


static func allocate(roster_picks: Array) -> Array:
	## roster_picks: [{seat_id, fighter_id, team_id?}]
	var assigned: Array = []
	for raw in roster_picks:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var fighter_id := str(raw.get("fighter_id", ""))
		var seat_id := int(raw.get("seat_id", assigned.size() + 1))
		var team_id := int(raw.get("team_id", 0))
		var variant := BodyVariant.allocate_for_seats(fighter_id, assigned)
		var accent := BodyVariant.seat_accent_required(fighter_id, variant, assigned)
		var payload := BodyVariant.match_payload(fighter_id, variant, seat_id, team_id)
		payload["seat_accent"] = accent
		payload["seat_accent_id"] = seat_id if accent else 0
		assigned.append(payload)
	return assigned
