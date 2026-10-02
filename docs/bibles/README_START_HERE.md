# Anime Aggressors — Fighter Bible + Animation Authority Package V1

This package converts the master Character, Movement & Animation Bible into:

- **9 individual fighter production bibles**
- machine-readable animation/state/movement/reaction/aura/presentation/story manifests
- a verified live-repository audit baseline for Anime PR #118
- an exhaustive Cursor implementation/audit prompt

## Important source truth

The source master says the intended product is broader than a move list and defines each fighter as a motion identity.

The master also:
- targets roughly 90–100 authored clips per gameplay identity;
- enumerates a broader set of state/move/presentation requirements;
- defines G0–G9 completion gates;
- keeps human feel and final-art approval separate from technical completion.

## Explicit discrepancy preserved

The source prose lists 23 move-specific entries and omits `back_air`.

The verified live #118 repository currently has **24 moves per spectrum fighter**, including `back_air`.

This package **does not silently rewrite the source master**.

Machine policy:
```text
back_air = RETAIN_CURRENT_REQUIRED_EXTENSION
```

## Verified PR #118 baseline

At package creation:
- PR #118 open/draft/mergeable
- head `93cf7150e2a958f73391d654489ee4c9121d9ae0`
- all workflow runs returned completed/success
- 22 action directories per spectrum fighter
- WAVE_A = 98 entries, 0 authored complete, 98 `PROCEDURAL_FALLBACK`
- 24 move IDs per spectrum fighter
- current runtime still has coarse state aliases/fallbacks

This baseline is an audit starting point, not a claim about future live state.

## Run order

1. Put this package beside the Anime repo or copy its relative `docs/`, `data/`, `source/`, and audit files into the repo.
2. Run `CURSOR_FULL_COMPLETION_ANIMATION_MOVEMENT_AUTHORITY_AUDIT.md`.
3. Continue existing draft PR #118; do not open a replacement PR.
4. Cursor must first census current state, then implement against the new authority.
5. Review the final Pixel movement packet yourself before G6/G8/G9 can pass.
