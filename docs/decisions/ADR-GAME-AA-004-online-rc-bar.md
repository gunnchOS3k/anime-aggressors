# ADR-GAME-AA-004 — Online RC digital bar

**Status:** Accepted (digital RC architecture freeze)  
**Date:** 2026-08-08

## Decision

Online RC digital bar (private/dev only):

1. Private lobby 1v1 with host-authoritative sync + rollback session
2. Unranked DEV matchmaking queue
3. Ranked DEV ladder (rating + pairing) — no public deploy
4. Spectator join
5. Replay record + checksum verify
6. Disconnect / reconnect / forfeit policy
7. Net fault injection (latency / jitter / loss)
8. Tournament room create / join / bracket seed (private)

## Out of scope

Public matchmaking deploy, store distribution, and WAN soak tests.
