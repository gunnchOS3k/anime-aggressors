# Native projectile interaction review

Runtime tests: `cf46897045611a46b5c4d9b6c55a83f276e37c4d`. Draft PR123 remains stacked on122.

Launch `tools/v1_closure/play_projectile_review.command` for normal Kaia versus an active Juno CPU. Close the older review window first if you want to avoid two games. This launcher uses an isolated profile and preserves Story saves. Add `--local` for two human players or `--male` for existing male models. Each launch preserves separate logs.

Kaia uses A/D movement, J attack, K Special, L Shield. Juno uses arrow movement, M attack, comma Special, period Shield. Neutral Special casts. Special+Shield charges using actual aura. Around50 aura gives medium integrity2;75 gives full integrity4. Quick integrity1. Values are provisional authored data.

In local play, approach without overlapping bodies and release movement before firing. Fire neutral Special toward each other: equal shots cancel; stronger shots lose integrity and damage. A full shot can intercept three quick shots, then a fourth cancels it. A surviving shot keeps its existing trajectory and lifetime; normal shields/dodges remain available. No clash input sequence.

The1534-frame ordinary-input two-player test earned aura normally: quick/quick and medium/medium canceled; Juno full/Kaia quick resolved4vs1→3vs0 and the surviving shot subsequently damaged Kaia6.6577824. A separate active-CPU850-frame test made15 player casts and observed11CPU moves but no projectile collision; it is not clash acceptance. Four-shot, defensive, same-team, fast-sweep and near-fighter cases are declared fixtures.

Nine affected suites passed. Eighteen medium/full emitter comparisons preserved exact native trajectory and lifetime across all nine fighters. Both review body variants load their actual model paths. New native video was not recorded; existing recordings retain their historical source identities. Resource-exit diagnostics remain.

Review the immediate collision, mixed elemental identity, surviving shot weakening, combat readability and defensive options. Full/Balanced/Reduced remain available. Floor placement, outer-reach physical contact, complete authored choreography and owner artistic acceptance remain unfinished. No human or release gate passes automatically.

Evidence: `PROJECTILE_IMPLEMENTATION_RESULTS.json`, `projectile_regressions/results.json`, `archetype_continuity/`, `projectile_public_latched/`. No merge, deploy, tag or release.
