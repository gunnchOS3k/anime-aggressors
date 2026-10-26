# @anime-aggressors/partylink

3k PartyLink session plane for Anime Aggressors (8-player V2).

- `MAX_PLAYER_SEATS = 8`, spectators use separate capacity
- Party Mode authority: `HOST_AUTHORITATIVE_PARTY` (LAN / same-room)
- Competitive rollback/netplay remains in `@anime-aggressors/netplay`
- BeatLink is reference-only for room/QR/token patterns — no scoring coupling

HTTP `/start` and `/rematch` require an explicit valid `ownerToken`; the public
room code and player/spectator tokens do not confer host authority. Rejected
requests preserve lobby configuration, queued inputs and the running simulation.
An authorized rematch retires the old simulation and resets round-local input
sequence/rate windows; reconnecting within a round retains replay protection.
The local display-host `startMatch()` API remains trusted and uses its own owner
credential internally.

Loopback session/input tests do not establish physical LAN or native Godot
combat acceptance. `HostAuthoritativePartySim` currently advances movement and
bookkeeping; it does not resolve the committed BattleScene combat rules.

```bash
npm run test -w @anime-aggressors/partylink
```
