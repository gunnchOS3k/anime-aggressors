# Known Runtime Risks

Living register of risks after PR #46/47 implementation. Updated PR #48.

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| KR-001 | Godot editor playtest unsigned | P1 | Complete `GODOT_EDITOR_PLAYTEST_SIGNOFF.md` |
| KR-002 | Godot CLI absent on CI/agent | P1 | `aa-verify-project.mjs` records `GODOT_CLI_MISSING` |
| KR-003 | Area2D hit overlap not final hurtbox polish | P1 | Functional for training; polish later |
| KR-004 | Proxy animations not final choreography | P2 | Labeled PROXY in HUD |
| KR-005 | Legacy PauseMenuScene vs in-battle pause | P2 | Document both paths |
| KR-006 | CPU tier 4 heuristic, not esports-tuned | P2 | Balance pass later |
| KR-007 | No rollback/netplay in Godot runtime | P3 | TS oracle only |
| KR-008 | Full ledge grab not implemented | P3 | Edge teeter only |
| KR-009 | Status JSON could overclaim without verify loop | P1 | PR #48 validation + verify script |

**Do not remove KR-001** until a signed file exists under `docs/manual-playtests/`.
