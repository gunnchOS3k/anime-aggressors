# ANIME AGGRESSORS V1 — ORDINARY PLAYABILITY & RENDERED REVIEW
## Continue ANI-01/02 from PR #122

Continue `gunnchOS3k/anime-aggressors` from existing draft PR #122.

Expected branch: `release/anime-v1-canon-and-campaign`

Expected PR head: `175e178ad583638603b92f5ea9a333239d419796`

Tested gameplay source: `30ea37f5e653357bc4ca2b6867d05cc221429b19`

**Do not restart ANI-01 or ANI-02.** The seven First Loss choices, 145-node graph, seven Gray routes, five Convergence nodes and staged source-progression tests are already implemented.

### Mission

Convert the staged source-level campaign success into evidence of real, ordinarily controlled gameplay and rendered Story quality.

The priority is one genuinely playable and reviewable Kaia campaign, including the Rook First Loss, Puppet battles, Essence progression, Prismatic Gray, final confrontation and ending.

Also inspect Juno's approved **The Last Vector** sacrifice involving Orion.

This is implementation and verification work, not another broad audit.

### Phase 1 — Safe continuation

1. Inspect PR #122, current worktree, branch, CI and disk state.
2. Preserve all 33 original worktrees, owner backups and previous test evidence.
3. Keep ANI-02 canon fixed. Do not reopen the seven approved First Loss choices.
4. Use the existing candidate roster and campaign graph.
5. Work serially; no subagents.
6. Preserve all owner save files and use separate test profiles.
7. Make small, recoverable commits.

### Phase 2 — Real ordinary gameplay

Launch the actual Godot game in its ordinary player-facing mode, beginning with a fresh nonprivileged test save.

Verify the Kaia route using normal keyboard/controller/game inputs with:

- Active opponent AI and genuine enemy aggression.
- Normal health, damage, knockback, blocking and KO rules.
- Real movement, attacks, collision and traversal.
- No protected or invulnerable automated player.
- No frozen enemies.
- No manually positioned collision targets or pre-injected KOs.
- No forced battle-result receipts.
- No direct save edits or debug-based unlocks.

An input-driving automation is acceptable as **ordinary-input automation**, but it must use the same gameplay rules available to a human player. Label that evidence accurately; it does not replace human playtesting.

Identify and fix any objective that is impossible, trivial, confusing or inaccessible through normal play.

Verify:

- Recruitment and first encounters.
- First Loss objective and aftermath.
- Five-Puppet encounter.
- Release choices and visible consequences.
- Equilibrium 2v2.
- Paired releases.
- Essence 1→2→4→6.
- Gray transformation.
- Second cosmic confrontation.
- Ending and next-route navigation.
- Loss/retry/save/restart.
- Objective discoverability and on-screen feedback.

Make sure a player understands what to do without reading source code or test documentation.

If the route becomes blocked, fix the actual gameplay mechanic instead of staging another successful result.

### Phase 3 — Convergence verification

Validate Sevenfold Convergence's ordinary-play prerequisites and gameplay.

Do not pretend Kaia's route alone legitimately unlocks Convergence if all seven routes are required.

A separate explicitly labeled seeded-prerequisite test may exercise individual Convergence mechanics, but it must not be recorded as a fully earned ordinary campaign completion.

Preserve the distinction among staged tests, normal-input automation and genuine human playthroughs.

### Phase 4 — Current rendered captures

Capture actual current Godot renderer output, not historical October 6 footage or an HTML evidence diagram.

Prioritize:

1. Kaia and Rook's First Loss.
2. Juno and Orion's Last Vector sacrifice/escort sequence.
3. Five-Puppet battle and release mechanic.
4. Essence progression.
5. Prismatic Gray transformation.
6. Final confrontation and route ending.
7. Convergence and earned cosmic unlock, where legitimately reachable.

Provide short video captures if technically available, plus representative screenshots. If reliable recording cannot be performed, produce an immediately usable owner launch/review procedure and record the limitation.

Include shots showing actual character bodies, facial expression, hair, animations, VFX, combat readability, camera framing and environment.

Do not replace real renderer evidence with mockups or source-structure screenshots.

All presentation remains subject to owner taste approval.

### Phase 5 — Technical quality

Run targeted regressions for:

- Active combat and hit/block/KO outcomes.
- Campaign objectives and receipts.
- Save persistence and legitimate progression.
- Seven unique First Loss mappings.
- Story/watch isolation.
- Gray transformations.
- Yin/Yang unlock prerequisites.
- Existing roster/model behavior.

Investigate headless shutdown warnings where practical without weakening safety or tests.

Check the latest GitHub CI status, including Windows Pilot 0, and distinguish completed, pending and failing jobs.

### Phase 6 — Disk safety

Recheck free disk space.

The prior checkpoint reported ~7.3 GiB free against an 18 GiB heavy-export guard.

Do not run large Web/Android/PCK builds below the documented guard.

Identify only provably disposable, reproducible caches or temporary build outputs. Preserve all source, Git history, original art, owner backups, unique worktrees, evidence and irreplaceable artifacts.

If recovering enough space requires deleting uncertain files, stop and ask the owner for approval.

Current exported-platform acceptance remains ANI-05, not this task.

### Phase 7 — Owner review delivery

Produce an owner-facing review package with:

- Exact launch commands or accessible preview instructions.
- Current source SHA and candidate identity.
- Kaia ordinary-playability findings.
- Objective-by-objective pass/fail matrix.
- Genuine normal-input automation evidence.
- Actual rendered screenshots/videos.
- Juno/Orion Last Vector review.
- Remaining gameplay blockers.
- Separate ANI-03, ANI-04 and ANI-05 work.
- Safe disk-recovery options.
- Explicit human review checklist.

The owner must be able to see and play the actual work, not just read a test report.

### PR and release boundaries

Update existing draft PR #122 with logical implementation commits and truthful evidence.

Do not merge, deploy, tag, publish or create a false V1 completion claim.

Keep:

`V1_AUTOMATED_READY=false`

`V1_ANIME_HUMAN_PASS=false`

All unearned final art, animation, gameplay feel, VFX, SFX and Story gates remain false.

If usage, storage, tooling or playability blocks the task, checkpoint and push the exact current work with a continuation handoff.

**Stop after the ordinary-playability and rendered-review package. Do not start another repository or V1 workstream.**