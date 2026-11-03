# CODEX MASTER TASK — ANIME AGGRESSORS V1.0.0
## ANI-02 Owner Canon Approval → ANI-01 Full Campaign Implementation
**Owner authority date:** October 9, 2026  
**Release target:** October 23, 2026 — gunnchOS fourth anniversary  
**Repository:** `gunnchOS3k/anime-aggressors`  
**Execution mode:** Serial, no subagents

## 0. Mission

Execute the Anime Aggressors V1.0.0 Story implementation workstream.

Complete two phases in order:

1. **ANI-02:** Integrate the owner's approved seven unique First Loss identities and their narrative consequences.
2. **ANI-01:** Implement the full seven-route Story campaign, Puppet encounters, Essence progression, Prismatic Gray transformations, Sevenfold Convergence, endings, and legitimate Yin/Yang unlocks.

These instructions supersede the earlier proposed First Loss matrix **only where explicitly changed below**.

Do not conduct another ecosystem-wide release audit, redo character-model generation, or recreate completed preservation work.

This task requires **actual game implementation**, not merely another planning document.

---

## 1. Exact continuation authority

Continue from the preserved Anime Aggressors development branch:

`codex/anime-v1-closure-2026-10-06`

Starting checkpoint:

`e063b13bcb293ad3ac7b8673c82d8830f8e0b24d`

Before editing:

- Fetch and inspect current remote branch and exact commits.
- Check all relevant Git worktrees, branches and pending changes.
- Preserve every unique Cursor/Codex file and unfinished worktree.
- Do not use `git clean`, destructive resets or force pushes.
- If the branch has advanced since the checkpoint, inspect its changes and reconcile rather than resetting it.
- Use one focused implementation branch, such as `release/anime-v1-canon-and-campaign`.
- Check available disk capacity before expensive Godot/Blender operations.

Read and respect:

- `CODEX_HANDOFF.md`
- `artifacts/v1_closure/authority_lock.json`
- `artifacts/v1_closure/first_loss_owner_options.json`
- Creative Authority Pack
- Fighter and Story Campaign Bibles
- Existing owner character-art/hairstyle/OVA overrides
- `game-godot/data/story/v1_campaign.json`
- `game-godot/scripts/story/v1_campaign_runtime.gd`
- `tests/v1_closure/CampaignCheckpoint.gd`
- `artifacts/v1_closure/campaign_completion_matrix.json`

Use the October 9 release ledger and its ANI-01/ANI-02 requirements as the release acceptance authority.

Preserve existing accepted mechanics, narrative contracts, original art assets, runtime work and test evidence.

---

# PHASE 1 — ANI-02: APPROVED FIRST LOSS CANON

## 2. Owner-approved First Loss identities

The owner explicitly approves the following **working V1 Story canon**:

| Protagonist | First Loss character | Central lesson |
|---|---|---|
| Kaia Windrow | Rook Ironside | Balance without passivity |
| Ember Vale | Nix Calder | Conviction without domination |
| Rook Ironside | Juno Spark | Strength without control |
| Juno Spark | Orion Vell | Action with purpose |
| Nix Calder | Vesper Nyx | Order without imprisonment |
| Orion Vell | Kaia Windrow | Understanding without detachment |
| Vesper Nyx | Ember Vale | Uncertainty without deception |

**These seven pairings are authoritative for the current working V1 Story.**

Critical correction:

`Juno Spark → Orion Vell`

**replaces** the earlier proposal:

`Juno Spark → Rook Ironside`

Do not implement Juno → Rook as the approved First Loss.

Kaia → Rook is existing established canon and must remain unchanged.

## 3. Seven unique lost-character identities

The seven campaigns must involve exactly seven distinct First Loss identities:

- Rook Ironside
- Nix Calder
- Juno Spark
- Orion Vell
- Vesper Nyx
- Kaia Windrow
- Ember Vale

Implement validation that ensures:

1. Every protagonist has exactly one approved First Loss.
2. No two protagonist campaigns assign the same lost character.
3. All seven main fighters appear exactly once as a lost character.
4. Kaia → Rook remains unchanged.
5. Juno → Orion is the active selection.
6. Unapproved earlier candidates cannot silently replace the selected mapping.
7. Campaign JSON, decision records, runtime routing and story-authority files agree.

This uniqueness requirement applies to the owner-approved V1 First Loss matrix.

Do not change competitive character identities or roster availability globally as a side effect of Story losses.

## 4. Route-specific continuity

Treat the seven Story campaigns as distinct protagonist-centered narrative routes with their own consequences.

A character's First Loss in one route does not automatically mean that character is permanently dead or unavailable in all other routes.

Do not establish:

- Seven universal permanent deaths.
- A single global timeline where incompatible route-specific losses all occur simultaneously.
- Unapproved resurrection rules.
- Permanent character removal from Versus or Training.
- Contradictions with existing Yin/Yang, Puppet or Prismatic Gray canon.

Represent each loss and its consequences within the appropriate route-specific Story state.

## 5. Make every First Loss genuinely unique

The seven events must differ in:

- Character relationship.
- Pre-loss disagreement.
- Encounter circumstances.
- Emotional consequence.
- Player objectives and interactions.
- Cinematic framing.
- Aftermath dialogue.
- Essence progression emphasis.
- Prismatic Gray resolution.
- Final character growth.

Do not take one generic loss scene and simply swap character names, models or dialogue.

Use the Creative Authority Pack as the primary lore boundary.

### Kaia loses Rook

Kaia confronts the cost of passive balance and learns that equilibrium sometimes requires decisive intervention.

Preserve the already established Kaia → Rook story authority.

### Ember loses Nix

Ember's overwhelming conviction and force cannot protect someone who needs her to listen and exercise restraint.

The emotional lesson is conviction without domination.

### Rook loses Juno

Rook discovers that protecting someone is not the same as controlling their choices.

His transformation must express strength without control.

### Juno loses Orion

Orion's deliberate sacrifice forces Juno to confront the difference between moving quickly and acting with purpose.

See the detailed scene contract below.

### Nix loses Vesper

Nix's pursuit of certainty and containment cannot guarantee trust or safety.

The route must express order without imprisonment.

### Orion loses Kaia

Orion confronts the limitation of detached prediction when a real person's choices, emotions and agency matter.

The route must express understanding without detachment.

### Vesper loses Ember

Vesper's concealment prevents honest connection when truth matters most.

The route must express uncertainty without deception.

---

# 6. SPECIAL STORY AUTHORITY — JUNO AND ORION

## Working scene title: The Last Vector

The owner approves the following **narrative direction**, subject to later final Story/cinematic review.

### Act I — Contrasting philosophies

Juno trusts instinct, improvisation and speed.

Orion trusts calculation, trajectories and deliberate planning.

Their relationship should establish that each possesses something the other needs.

Juno sometimes treats hesitation as weakness.

Orion sometimes treats emotion and uncertainty as inconvenient variables.

### Act II — The impossible escape

During the catastrophe, Orion determines that the escape route is collapsing.

He evaluates multiple possible paths.

His assessment reveals that Juno can protect the remaining team only if the passage is stabilized long enough for them to escape.

Someone must stay behind.

Juno initially believes she can simply move faster, improvise another route or return for everyone.

### Act III — Orion's deliberate sacrifice

Orion chooses to hold the route open.

This is not merely a mechanical calculation performed without emotion.

For perhaps the first time, Orion deliberately prioritizes personal connection and another person's freedom to act over the detached optimization of an abstract model.

His choice expresses his own lesson:

**Understanding without detachment.**

He gives Juno enough time and opportunity to protect the people still within reach.

### Act IV — Juno's defining choice

Juno's immediate impulse is to turn back.

However, turning back would squander Orion's sacrifice and jeopardize those he chose to protect.

For the first time, Juno's greatest act of courage is not moving faster.

It is deliberately choosing where her speed is needed most.

The sacrifice teaches:

**Action with purpose.**

This must be communicated through playable objectives and decisions as well as cinematics.

Do not resolve the entire sequence through a noninteractive cutscene if gameplay is required by the Story contract.

### Act V — The First Loss

The escape passage collapses or becomes inaccessible.

Orion is lost from Juno's route.

His precise ultimate fate remains subject to later owner narrative approval.

Do not independently establish permanent death.

### Act VI — Prismatic Gray resolution

During Juno's later transformation, Orion's sacrifice changes her relationship to speed.

Her movement becomes purposeful, deliberate and emotionally grounded.

Her powers remain hers; this is character growth, not a replacement of Juno's elemental identity.

Connect the loss to her later decision-making, animation, cinematic expression, Essence progression and Prismatic Gray payoff.

### Dialogue authority

New dialogue may be drafted and implemented with explicit `DRAFT_OWNER_REVIEW` status.

Do not treat unreviewed lines as final owner-approved screenplay.

Do not copy dialogue, cinematics, characters or protected designs from existing franchises.

---

# 7. Record owner canon correctly

Update:

- Approved First Loss decision record.
- Source-derived Story authority.
- Campaign relationship data.
- Relevant route graph references.
- Narrative consequence and dialogue dependencies.
- Automated canonical-uniqueness checks.
- Supporting provenance/evidence reports.

Record:

- Owner approval date: October 9, 2026.
- Scope: seven specific First Loss identities and the Juno/Orion sacrifice direction.
- Status: approved working V1 narrative canon.
- Superseded proposal: Juno → Rook.
- Current selected canon: Juno → Orion.
- Remaining owner gates: final Story presentation, dialogue, art, animation, VFX, SFX and gameplay feel.

Preserve revision history so explicit future owner decisions can revise the selected canon without erasing earlier evidence.

**Finish and checkpoint ANI-02 before proceeding to ANI-01.**

---

# PHASE 2 — ANI-01: COMPLETE FULL STORY CAMPAIGN

## 8. Required scope

Starting development evidence:

- 145 declared Story nodes.
- 71 nodes previously implemented.
- 0/7 fully completed Prismatic Gray routes.
- 0/5 completed Sevenfold Convergence nodes.
- Yin/Yang Story unlock not yet legitimately earned.

These are baseline figures, not completion claims for this run.

Implement the entire declared Story graph through correct playable systems.

Target:

- 145/145 implemented, reachable and validated Story nodes.
- Seven genuinely playable complete protagonist routes.
- Seven actual Prismatic Gray route completions.
- All five Sevenfold Convergence nodes.
- Legitimate story-based Yin/Yang unlock.
- Valid route endings, return navigation and next-route selection.
- Correct persistence and replay.

## 9. Complete the campaign encounter mechanics

Implement and integrate:

1. All remaining First Loss consequences.
2. Five-Puppet 3v2 encounter conditions.
3. Actual player-influenced release decisions.
4. Equilibrium 2v2 battles.
5. Opposite-force paired releases.
6. Essence progression through required states, including 1 → 2 → 4 → 6.
7. The second impossible Yin/Yang encounter.
8. Prismatic Gray transformation gameplay and cinematics.
9. Route-specific final objectives and endings.
10. Sevenfold Convergence progression.
11. Legitimate Yin/Yang unlock and next-route behavior.

Reuse shared encounter machinery where appropriate, but preserve distinct route objectives, character responses and visual storytelling.

A menu selection must never masquerade as a completed battle.

A declared JSON node must never be counted as implemented solely because its ID exists.

## 10. Runtime correctness

Maintain real BattleScene-driven outcomes.

Verify:

- Encounter entry and correct fighter/form selection.
- Legitimate player controls.
- Collision, hit, block, damage and KO outcomes.
- Correct battle-result receipts.
- Loss, retry and replay.
- Atomic saves.
- Resume after process restart.
- Contiguous-prefix progression enforcement.
- Idempotent receipts.
- Resistance to forged or malformed save data.
- No unintended unlock from debugging/review modes.
- No accidental campaign advancement through menu navigation.
- No character-model/form mismatch after Story transitions.
- Correct distinction between watchable Story progression and playable Story progression.

Where test fixtures stage a KO or simulate player input, label them as staged automation.

A scripted encounter is not evidence of human gameplay acceptance.

## 11. Preserve the character and combat authorities

Preserve all nine fighters:

- Ember Vale
- Rook Ironside
- Juno Spark
- Kaia Windrow
- Nix Calder
- Orion Vell
- Vesper Nyx
- Yin
- Yang

Preserve the existing:

- Male/female presentation direction.
- Unique female hairstyles.
- Owner-directed Yin/Yang crowns and hair.
- Original articulated collectible visual style.
- Distinct facial/body identities.
- Existing male-hair checkpoint preservation.
- Puppet/Prismatic/Cosmic form definitions.
- Character-specific lore and elemental identities.
- Completed hit/block/recovery and battle-behavior corrections.

Do not restart Blender character generation merely because the Story graph is advancing.

If a missing animation, VFX, voice, SFX or cinematic prevents a truly complete scene, implement the most appropriate authorized integration and record what remains under ANI-03/ANI-04.

Do not claim procedural candidates are final authored assets.

## 12. Story and OVA relationship

Keep the playable Story and watchable Story consistent with the approved shared narrative graph.

The creative direction remains:

- One primary continuous Kaia OVA.
- Six protagonist Campaign Variations.
- Route-specific relationships, emotional responses and Prismatic Gray consequences.

Do not create seven unrelated full anime productions.

Do not automatically claim ANI-04 or the complete OVA merely because ANI-01's underlying graph is functional.

Watch-only playback must not grant gameplay achievements, battle receipts or character unlocks.

## 13. Required validation and evidence

Run the repository's meaningful existing validation paths, including where applicable:

- Godot project import and script checks.
- Story graph schema/consistency.
- First Loss uniqueness and approved mapping.
- Campaign checkpoint tests.
- Real BattleScene encounter transitions.
- Player input and battle outcomes.
- Save/resume/restart.
- Negative/forged-save cases.
- Prismatic Gray transformation/route state.
- Convergence requirements.
- Yin/Yang unlock state.
- Existing roster/model regression tests affected by the edits.
- Scoped packed/exported-runtime checks when artifacts are generated.

Keep evidence types separate:

**Source-scene tests ≠ packed-runtime tests ≠ exported Web/Android tests ≠ human playthroughs.**

Never invent a successful result for a test that could not run.

Update the campaign-completion matrix with objective per-route evidence, including implemented nodes, exercised transitions, authentic receipts, unresolved failures, and exact source SHA.

If the full 145-node implementation cannot be completed within this task or usage window, commit a truthful partial implementation and preserve the remaining work as an exact continuation checklist.

Do not weaken tests to obtain a green CI result.

---

# 14. Git and execution discipline

- Work serially, without subagents.
- Complete ANI-02 before ANI-01 mutations.
- Use one focused implementation branch unless a verified workflow requires another.
- Do not overwrite dirty Cursor worktrees.
- Commit small, logically meaningful checkpoints.
- Push work before usage approaches exhaustion.
- Update `CODEX_HANDOFF.md` as meaningful milestones complete.
- Preserve source hashes separately from exported PCK/Web/Android artifacts.
- Preserve source artwork and owner backups.
- Respect existing disk-space guards.
- Open a draft pull request with implementation evidence.
- Do not merge, deploy, tag or publish without separate owner approval.

Avoid unnecessary full repository rebuilds when a focused regression is sufficient.

Do not begin Archive, Passport, Invites or another release workstream after Anime checkpoint completion.

---

# 15. Acceptance gates

The owner has approved **the seven First Loss pairings and the Juno/Orion narrative direction only**.

Do not infer any of the following approvals:

```text
FINAL_CHARACTER_ART_PASS=false
ANIMATION_TASTE_HUMAN_PASS=false
GAME_FEEL_HUMAN_PASS=false
VFX_TASTE_HUMAN_PASS=false
SFX_MIX_HUMAN_PASS=false
STORY_HUMAN_PASS=false
V1_ANIME_HUMAN_PASS=false
```

`V1_AUTOMATED_READY` and all broader V1 release gates must remain false until complete qualifying evidence supports their change.

ANI-02 canon approval must not automatically pass ANI-01, ANI-03, ANI-04 or ANI-05.

---

# 16. Final response format

Return:

**A. Canon integration**
- Exact seven approved First Loss pairings.
- Confirmation of zero duplicate identities.
- Juno → Orion correction.
- Canon files changed.
- Owner decision record.

**B. Implementation**
- Starting branch and SHA.
- Final branch and SHA.
- Draft PR URL.
- Actual campaign systems completed.
- 145-node completion matrix.
- Seven Gray-route results.
- Five Convergence-node results.
- Yin/Yang unlock evidence.

**C. Technical validation**
- Godot tests.
- Real runtime encounter receipts.
- Save/restart/negative tests.
- Source and artifact SHAs.
- Exported runtime evidence, if produced.
- Explicit tests not yet run.

**D. Remaining work**
- Exact unfinished gameplay/story implementation.
- ANI-03 art/movement/VFX/SFX dependencies.
- ANI-04 OVA/cinematic dependencies.
- ANI-05 Web/Android/PartyLink dependencies.
- Owner-only review decisions.
- Recommended next implementation task.

**E. Release integrity**
- No unauthorized merge/deploy/publication.
- All unearned gates remain false.
- Preserved original worktrees and backups.
- No false V1 completion claims.

**BEGIN WITH ANI-02 CANON INTEGRATION, THEN EXECUTE ANI-01 ENGINEERING. DO NOT REPEAT THE PREVIOUS AUDIT.**
