# Animation Authority V1 — Status

Installed from the Fighter Bibles / Animation Authority V1 package onto draft PR #118.

## Truth rules
- Procedural runtime clips are **continuity only** (`PROCEDURAL_FALLBACK`).
- They are **not** authored completion, human feel pass, or final art approval.
- `back_air` is retained as `RETAIN_CURRENT_REQUIRED_EXTENSION`.
- G6 / G8 / G9 remain human-owned and false until owner review.

## Key paths
- `source/ANIME_AGGRESSORS_COMPLETE_CHARACTER_MOVEMENT_ANIMATION_BIBLE_V1.md`
- `docs/bibles/fighters/*.md` (9 production bibles)
- `data/bibles/*`
- `artifacts/animation_authority_v1/*`
- `tools/animation_authority/*`

## Next
`NEXT_ANIME_ACTION=FIX_REMAINING_ANIMATION_AUTHORITY_GAPS` until authored clips replace procedural fallbacks, then owner Pixel movement/feel review.
