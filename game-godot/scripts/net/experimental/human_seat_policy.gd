extends RefCounted
## EXPERIMENTAL seat policy for validated 2-player combat proofs.
## Bots, CPU dummies, and spectators never count as human fighting seats.
## Does not authorize 8p approximation or shipping LAN enablement.

const HUMAN := "human"
const CPU := "cpu"
const BOT := "bot"
const SPECTATOR := "spectator"
const ALLOWED_ROLES := [HUMAN, CPU, BOT, SPECTATOR]

static func normalize_seat(raw: Dictionary) -> Dictionary:
	var role: String = str(raw.get("role", "")).strip_edges().to_lower()
	if role == "player":
		role = HUMAN
	return {
		"seat_id": int(raw.get("seat_id", -1)),
		"role": role,
		"fighter_id": str(raw.get("fighter_id", "")),
		"peer_id": int(raw.get("peer_id", 0)),
		"name": str(raw.get("name", "")),
	}

static func is_human_fighting_seat(seat: Dictionary) -> bool:
	var row: Dictionary = normalize_seat(seat)
	return str(row.role) == HUMAN and int(row.seat_id) > 0 and not str(row.fighter_id).is_empty()

static func human_fighting_seats(roster: Array) -> Array:
	var humans: Array = []
	var seen: Dictionary = {}
	for raw in roster:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var seat: Dictionary = normalize_seat(raw)
		if str(seat.role) not in ALLOWED_ROLES:
			continue
		if not is_human_fighting_seat(seat):
			continue
		if seen.has(int(seat.seat_id)):
			continue
		seen[int(seat.seat_id)] = true
		humans.append(seat)
	humans.sort_custom(func(a, b): return int(a.seat_id) < int(b.seat_id))
	return humans

static func spectator_count(roster: Array) -> int:
	var count: int = 0
	for raw in roster:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		if str(normalize_seat(raw).role) == SPECTATOR:
			count += 1
	return count

static func non_human_fighter_count(roster: Array) -> int:
	var count: int = 0
	for raw in roster:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var role: String = str(normalize_seat(raw).role)
		if role in [CPU, BOT]:
			count += 1
	return count

static func validated_two_human_fighters(roster: Array) -> Dictionary:
	var humans: Array = human_fighting_seats(roster)
	var ok: bool = humans.size() == 2
	return {
		"ok": ok,
		"human_seats": humans,
		"human_count": humans.size(),
		"spectator_count": spectator_count(roster),
		"non_human_fighter_count": non_human_fighter_count(roster),
		"bots_and_spectators_excluded_from_human_seats": true,
		"validated_2p": ok,
		"eight_player_authorized": false,
	}

static func self_test() -> Dictionary:
	var mixed: Array = [
		{"seat_id": 1, "role": "human", "fighter_id": "kaia-windrow", "peer_id": 1},
		{"seat_id": 2, "role": "human", "fighter_id": "juno-spark", "peer_id": 2},
		{"seat_id": 3, "role": "cpu", "fighter_id": "ember-vale", "peer_id": 0},
		{"seat_id": 99, "role": "spectator", "fighter_id": "", "peer_id": 9, "name": "Spec"},
		{"seat_id": 4, "role": "bot", "fighter_id": "nix-calder", "peer_id": 0},
	]
	var result: Dictionary = validated_two_human_fighters(mixed)
	var only_bots: Dictionary = validated_two_human_fighters([
		{"seat_id": 1, "role": "bot", "fighter_id": "kaia-windrow"},
		{"seat_id": 2, "role": "cpu", "fighter_id": "juno-spark"},
	])
	var ok: bool = bool(result.get("ok", false)) and int(result.get("human_count", 0)) == 2 \
		and int(result.get("spectator_count", 0)) == 1 and int(result.get("non_human_fighter_count", 0)) == 2 \
		and not bool(only_bots.get("ok", false)) and not bool(result.get("eight_player_authorized", true))
	return {"ok": ok, "validated_2p": result, "bots_alone_rejected": only_bots}
