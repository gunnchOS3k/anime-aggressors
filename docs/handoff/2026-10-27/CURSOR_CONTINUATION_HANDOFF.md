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
- Delayed pass tip SHA (pre-stamp): 9221d1dbe710a2c4e1e7de60b475fdc9ebc5b00c
- This pass adds delayed LanControls correction + shadow LAN observer; tip SHA stamped after commit/push below.
- Runtime evidence: `artifacts/cursor_continuation/CURSOR_CONTINUATION_RUNTIME_EVIDENCE.json`
- Suites (local Godot 4.7.1 headless): FlatCombatReplay PASS, BodyVerticalReplay PASS, AirborneKnockbackResim PASS, DelayedInputSnapshotResim PASS
- Shipping LAN backend remains disabled (`SHIPPING_BACKEND_ENABLED=false`). Host committed snapshots stay `rollback_restorable=false`. Opt-in `LanSession.experimental_input_observer` is observe-only and cleared on stop.

## LAN / parity work this pass

- `lan_resim_bridge.gd`: LanControls ↔ trial input round-trip; late guest packet → owned flat resim correction; asserts shipping contract.
- `DelayedInputSnapshotResim.gd`: 4-frame delayed wrong-open-guard mispredict, then late shield packet restores oracle tip (CI physics scope).
- `lan_session.gd`: optional observe-only Callable hook; default unset → no shipping behavior change.

## Push status (honest)

- Remote branch created successfully (no force): `origin/cursor/continuation-isolated-combat-20261027` @ `2bbab9551016fbc6b1b7af1f86df3d43daf5cdf1`
- Local tip ahead (not yet on remote — auth unavailable for second FF push): `fac4669be37a19477fa46ba9e2af13ad6646951f`
- Engineering commit for delayed resim: `9221d1dbe710a2c4e1e7de60b475fdc9ebc5b00c`
- Remote did not diverge; force-push was not used or needed.
