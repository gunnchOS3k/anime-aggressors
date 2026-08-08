# ADR-GAME-AA-003 — Launch modes

**Status:** Accepted (digital Beta content freeze)  
**Date:** 2026-08-08

## Decision

Required launch modes (Godot path):

| Mode | Notes |
|------|-------|
| Local Versus | P1 human, P2 human or CPU |
| CPU Versus | Ruleset CPU tiers 1–5 |
| Training | Dummy modes + frame tools |
| Tutorial | First-run interactive path |
| Arcade Ladder | Sequential CPU bouts |
| Team | 2v2 stocks / team-attack ruleset |
| Items / Hazards | Stage hazards + pickups |
| Challenges | Timed / stock / damage challenge set |
| Online Unranked | Private/dev queue architecture |
| Online Ranked | Private/dev ranked ladder architecture |
| Spectator | Join private room as spectator |
| Replay | Record + checksum verify |
| Tournament Rooms | Bracket/lobby rooms (private/dev) |

## Consequences

Mode Select must expose every mode. Online remains **private/dev** — not a public deploy claim.
