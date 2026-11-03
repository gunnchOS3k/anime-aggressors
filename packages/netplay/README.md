# Netplay package

Local loopback transport + `NetplaySession` integration with `RollbackSession`.

## Status

| Capability | Gate |
|------------|------|
| Loopback transport | PROVEN BY TEST |
| Public WebSocket relay | SHIP BLOCKED |

## Next step

See `docs/ONLINE_MULTIPLAYER_PLAN.md` for relay/lobby server.

## Input ownership

`advanceLocal()` accepts only this transport's seat at the current simulation
frame. Remote inputs retain their original frames: late inputs go through the
existing combat rollback engine, current/future inputs wait for their frame.
`pumpRemoteInputs()` reconciles packets without advancing combat or sending a
new input; use it while waiting and when draining the end of a test/session.

The restore/future window is 120 frames. Identical duplicates are idempotent;
conflicting confirmations, invalid seats/frames and missing history fail
explicitly. Transport errors propagate after retiring an already simulated
frame. Reconnection, retransmission and state resynchronization remain required.
The transport must establish authenticated participants; payload consistency
checks do not provide authentication.

The software receipt is `docs/handoff/2026-10-26/NETPLAY_SESSION_ENGINE.json`.
It covers actual TypeScript combat resimulation, not Godot BattleScene/LAN or
online acceptance. Godot still needs its own real transport, combat snapshots,
replication, restoration and resimulation integration. Private original art and
physical-device/audio/visual acceptance are separate open requirements.
