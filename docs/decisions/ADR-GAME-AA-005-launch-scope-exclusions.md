# ADR-GAME-AA-005 — Launch-scope exclusions (GAME-RC-003)

## Status
Accepted for digital launch-scope honesty (GAME-RC-003).

## Context
Anime Aggressors launch content is digitally complete for the intended modes and roster.
Several items remain intentionally outside launch-required scope.

## Decision
The following are **explicitly excluded** from launch-required content (not silently ignored):

| Item | Decision |
|------|----------|
| Painted hero remasters | OUT OF LAUNCH SCOPE — procedural-final presentation is the launch bar |
| Studio-recorded audio stems | OUT OF LAUNCH SCOPE — procedural/synthesized bank is the launch bar |
| Public ranked / unranked matchmaking | OUT OF LAUNCH SCOPE — private/dev online architecture only |
| Console native SDK packaging | EXTERNAL_PENDING — abstractions only until SDK access |

## Consequences
- `ANIME_CONTENT_FEATURE_COMPLETE_DIGITAL` may be earned against the closed launch checklist.
- `FEATURE_COMPLETE_RC` / `POLISHED_RELEASE_CANDIDATE` remain false without human polish + broader RC bar.
- CONTENT_MANIFEST keeps excluded items listed OPEN with notes, not counted as launch placeholders.
