# Anime Aggressors — PartyLink Product Flow (8P V2)

## Decision
`MAX_PLAYER_SEATS = 8`, `MIN_PLAYER_SEATS = 2`, spectator capacity is separate.

## Authority
Party Mode uses `HOST_AUTHORITATIVE_PARTY` for same-room/LAN.
Competitive online continues to use deterministic rollback/netplay.

## Modes
- FFA 2–8
- Teams: 2v2, 3v3, 4v4, 2v2v2v2
- Duplicate fighters allowed (palette/outline/badge/HUD/seat label)

## Flow
1. Party Mode → Create Room (QR + code on Arena View)
2. Players join from phone/browser controllers
3. Optional spectators join read-only (never consume seat 9)
4. Ready → host starts → Arena View frames all active fighters
5. Results / rematch

## V1 network scope
Same-room/LAN required. `PARTYLINK_PUBLIC_RELAY_PASS=false` until hosted relay is deployed.
