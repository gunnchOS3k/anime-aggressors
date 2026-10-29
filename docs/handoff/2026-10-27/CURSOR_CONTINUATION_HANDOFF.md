# Cursor continuation handoff — Anime Aggressors (temporary ownership)

**Not a restart, merge, tag, deploy, Pages publish, RC2, or V1 release.**
`RC2_READY=false`. `V1_0_0_RELEASE_AUTHORIZED=false`.

## Authority

| Field | Value |
| --- | --- |
| Temporary owner | Cursor (Codex exhausted) |
| Source branch (verified remote tip) | `integration/v1-preserved-candidate-20261025` |
| Source SHA | `b4f9808b4e52b8a6b80fdb1cc286d56ec3f94c91` |
| Cursor continuation branch | `cursor/continuation-isolated-combat-20261027` |
| Cursor worktree | `repos/anime-aggressors/.worktrees/cursor-continuation-isolated-combat-20261027` |
| Codex integrated worktree (DO NOT WRITE) | `repos/_anime_v1_integrated_20261025` @ same SHA + dirty `?? outputs/` |
| Main checkout (DO NOT WRITE) | `repos/anime-aggressors` on `release/v1-in-app-feedback` — heavily dirty Codex/local evidence |

## No-concurrent-write rule

1. **All Cursor engineering writes happen only in the Cursor continuation worktree/branch above.**
2. **Do not modify** the Codex integrated tree, the dirty main checkout, or any other registered Anime worktree while this ownership window is active.
3. Preserve newer commits and all dirty/untracked/ignored Codex evidence in place (including `outputs/` under `_anime_v1_integrated_20261025`).
4. No force-push, reset, clean, or discard of uncommitted work in any Anime tree.
5. Do not touch Pedestrian, BeatLink, Archive, WAIKE, or MLV.

## Recovered / verified starting point

- Local and `origin/integration/v1-preserved-candidate-20261025` both resolve to `b4f9808b4e52b8a6b80fdb1cc286d56ec3f94c91`.
- Tip already contains isolated flat combat trial + `BodyVerticalReplay` (body hits + jump/double-jump/landing restore/replay) and shipping host-authoritative LAN left disabled for the experimental backend.
- Codex tip evidence under `_anime_v1_integrated_20261025/outputs/` and `docs/handoff/2026-10-27/*.json` left untouched; FlatCombat CI receipt at `8079ac6e` remains historical for the grounded shield/parry subset.

## Continuation focus (engineering, not report)

- Verify `BodyVerticalReplay` / exact-head physics suites from this tip.
- Continue **isolated** combat backend: rollback-safe contacts, airborne knockback, world snapshot restoration, corrected remote inputs, side-effect reconciliation, real LAN resimulation.
- Scale toward validated **2 human seats** first; bots/CPU/spectators never count as human seats.
- Do not implement 8p as non-deterministic visual approximation.
- Preserve 216 BASE moves, 46 authored combinations, story assets, nine fighters, elemental/shield/parry systems. No generic mannequin replacement.
- Prefer GitHub free runners / headless Godot for heavy proof. Commit only on the Cursor continuation branch with exact SHA + runtime evidence.

## Machine-readable twin

See `artifacts/cursor_continuation/CURSOR_OWNERSHIP_PROVENANCE.json`.

## Cursor continuation commit / push

- Parent/source tip: `b4f9808b4e52b8a6b80fdb1cc286d56ec3f94c91`
- First remote-recoverable push: `2bbab9551016fbc6b1b7af1f86df3d43daf5cdf1` → `origin/cursor/continuation-isolated-combat-20261027` (new branch; fast-forward create, no force)
- Engineering baseline (prior runtime): `3062cdf47742a1c0e60de3bb22c4758e4d66e481`
- Delayed-resim engineering commit: `9221d1dbe710a2c4e1e7de60b475fdc9ebc5b00c`
- Requested publish tip: `89817629ee14e15dba12ee12ff49bc1e592eab9e` (FF-pushed from `2bbab955`)
- Current remote tip (includes handoff + CI URL stamps): `57489380716ba1e45028b3889a59feec7a2afc35`
- Runtime evidence: `artifacts/cursor_continuation/CURSOR_CONTINUATION_RUNTIME_EVIDENCE.json`
- Suites (local Godot 4.7.1 headless): FlatCombatReplay PASS, BodyVerticalReplay PASS, AirborneKnockbackResim PASS, DelayedInputSnapshotResim PASS
- Shipping LAN backend remains disabled (`SHIPPING_BACKEND_ENABLED=false`). Host committed snapshots stay `rollback_restorable=false`. Opt-in `LanSession.experimental_input_observer` is observe-only and cleared on stop.

## LAN / parity work this pass

- `lan_resim_bridge.gd`: LanControls ↔ trial input round-trip; late guest packet → owned flat resim correction; asserts shipping contract.
- `DelayedInputSnapshotResim.gd`: 4-frame delayed wrong-open-guard mispredict, then late shield packet restores oracle tip (CI physics scope).
- `lan_session.gd`: optional observe-only Callable hook; default unset → no shipping behavior change.

## Push status (published)

- Requested tip published: `89817629ee14e15dba12ee12ff49bc1e592eab9e`
- Remote tip SHA: `57489380716ba1e45028b3889a59feec7a2afc35`
- Branch: `origin/cursor/continuation-isolated-combat-20261027`
- Push: fast-forward `2bbab955` → `89817629` → `82243ad9` (no force)
- Auth: git push succeeded (ConnectScm not required)
- Engineering delayed-resim commit: `9221d1dbe710a2c4e1e7de60b475fdc9ebc5b00c`
- CI: workflow_dispatch Authored Animation Production, `lan_battle_runtime=true`, `lan_battle_scope=physics`
- Run: https://github.com/gunnchOS3k/anime-aggressors/actions/runs/40610562424


## First Bloom + 30-stage pass (Cursor)

- Working fighter: `rosamere` / The First Bloom — **NOT owner-finalized** (name/design/gameplay flexible)
- Secret tenth registered; training/command-guide hooks; Pink revelation stub after Kaia `prismatic_gray`
- Pink systems in-game (deterministic IDs + retirement): FirstPermission, BloomSeed, PetalConstellation, OriginationScript, FirstDawn, GentleReversal, QuietEmbrace (+ supers incl. Mythic Everything Again labeled)
- Competitive self-limited can lose; Everlasting Origin story/mythic only — **no invincible ranked character**
- Art: `art_status.cel_shaded_glb=false` / `NOT_AUTHORED_THIS_PASS` (honest; no fake finished GLB)
- Dedication credits text: `docs/fighters/ROSAMERE_DEDICATION_OWNER_REVIEW.json` — OWNER_REVIEW
- Stages: expanded 30 registered; canonical launch 6 preserved
- **Playable batch1 (procedural working):** titans-divide, the-last-horizon, sunburst-highlands, nightveil-city, the-furnace-between
- Remaining 25: `REGISTERED_PENDING` (JSON + stubs only — not claimed finished)
- StageManager owns registry/build/hazard snapshots; shipping rollback still off
- Tests (Godot 4.7.1 headless): PinkBloomSystemsDeterminism PASS (33), ExpandedStageLoadSmoke PASS (47), FlatCombatReplay PASS (24)
- Evidence: `artifacts/cursor_continuation/BLOOM_STAGE_RUNTIME_EVIDENCE.json`
- Engineering commit: `8ee6e1915e630c38e148f8101012d604057780f0`
- Requested publish tip: `8f26f9f565cee813eb4d7be723b08a4ff40664dd` (FF-pushed from `4568e3e1`; ancestor check OK)
- Remote tip before this docs stamp: `a5a26ab3987515cc34495ba03c78268b51dbec1f` (branch tip advances with this commit; includes requested `8f26f9f5` + eng `8ee6e191`)
- Gates remain false: RC2_READY, V1_0_0_RELEASE_AUTHORIZED, HUMAN_ART_APPROVED
- Pre-commit tip (parent of this work): `4568e3e1eb4bc8d4bd4bc90f22e3aadbff857c66`


## Rosamere three-form canon confirmation

- Name **Rosamere** + title **The First Bloom**: OWNER FINAL
- Three-form canon + high-level mythology: OWNER APPROVED
- Forms (UI/story): I Familiar Rose (`FAMILIAR_ROSE`) · II First Bloom (`FIRST_BLOOM`) · III Everlasting Origin (`EVERLASTING_ORIGIN`)
- `COMPETITIVE_SELF_LIMITED` = Familiar Rose gameplay contract (NOT a fourth story form); technical IDs preserved
- Everlasting: Story + opted-in Mythic Party only; never invincible ranked
- Final art / balance / cinematics / V1 / RC2: still false; `art_status` honest
- Dedication credits: OWNER_REVIEW for publication
- Pink revelation remains after Kaia breakthrough; First Permission systems + Everything Again (Mythic) preserved
- Hooks: `data/forms/rosamere.json`, `rosamere_form_selection.gd`, training/versus apply paths
- Tests: RosamereThreeFormCanon PASS, PinkBloomSystemsDeterminism PASS, FlatCombatReplay PASS
- Evidence: `artifacts/cursor_continuation/ROSAMERE_THREE_FORM_CANON_EVIDENCE.json`
- Engineering tip: `e06d0cf7` (three-form confirmation)
- Requested tip FF-published: `6004a1df1db49ca40c657fb7c90da4c9e05491f7` (eng `e06d0cf7`; from `695a9dd9`)
- Remote HEAD after handoff stamp: `a4bfe14328843f5aec7c3166eda47831d8c05e45`


## Shift — presentation / ordinary controls / batch2 stages

- Owner canon recorded as **OWNER_APPROVED** (not WORKING_CANDIDATE): Rosamere / The First Bloom / three forms; `COMPETITIVE_SELF_LIMITED` remains Familiar Rose contract only.
- Three-form presentation production: runtime pose/VFX/audio/transition hooks + `rosamere_form_presentation.gd`; honest `art_status=THREE_FORM_PRESENTATION_PRODUCTION_IN_PROGRESS`; final art still false.
- Ordinary Training/combat wiring: restored `aura_charge`/`aura_burst` move IDs; PinkBloomSystems activates from specials/grab/charge/burst; Quiet Embrace no longer steals grab.
- Stage batch2 authored layouts playable (5): the-concord-guildhall, hermits-tide-retreat, celestial-observatory, the-infinity-chamber, the-convergence-tournament-grounds. Launch six preserved. 20 still REGISTERED_PENDING.
- Shipping rollback still off. RC2_READY / V1_0_0_RELEASE_AUTHORIZED / HUMAN_ART_APPROVED remain false.
- Local Godot 4.7.1 evidence: PinkBloomSystemsDeterminism PASS (50), RosamereThreeFormCanon PASS (38), ExpandedStageLoadSmoke PASS (99), RosamereOrdinaryControlsTraining PASS (28), FlatCombatReplay PASS (24).
- Evidence: `artifacts/cursor_continuation/SHIFT_PRESENTATION_CONTROLS_STAGES_EVIDENCE.json`

- Engineering tip: `b2b9efa75422bc157bd5feefeb34c6ebf20eb7e3`
- Docs stamp tip (pre-push): `6e4e2bb9ee2ff28d7dec490548bcb73e3ea88cd2`
- Requested publish tip: this commit after FF push.
