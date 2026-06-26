# Online multiplayer plan

## Current gate: PROVEN BY TEST (local loopback)

`packages/netplay` provides:

- `NetplayTransport` interface
- `LocalLoopbackTransport` with optional drop simulation
- `NetplaySession` integrated with `RollbackSession`
- Tests proving two peers reach identical final hash

## SHIP BLOCKED: public online

Blockers:

1. WebSocket relay server (authoritative input fan-out)
2. Lobby / matchmaking UI
3. NAT traversal or TURN for P2P fallback
4. Desync reporting in production

## Next implementation steps

1. Deploy minimal relay (`wss://`) forwarding `RemoteInputMessage` frames
2. Wire `WebSocketTransport` (stub throws today)
3. Add lobby shell in `apps/web/src/shell/onlineLobby.ts`
4. Run loopback tests against recorded production traces
