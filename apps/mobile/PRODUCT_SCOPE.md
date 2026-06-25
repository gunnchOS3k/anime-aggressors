# Mobile App — Product Scope

**Status:** Scaffold / planning — not in required CI quality gate.

## Purpose options (Track D — decide at D0)

| Mode | Description |
|------|-------------|
| Playable game | Full match on phone via shared `game-core` |
| Companion app | Stats, replays, device pairing |
| Controller app | Phone as extra input device |
| All three | Long-term; sequence matters |

**Recommended D0 decision:** Companion + controller research first; playable build after web Track A reaches A3 (training mode).

## Technical path

- **Expo** (SDK 51 scaffold in `apps/mobile/package.json`)
- Share types from `@anime-aggressors/game-core` when Metro bundler path is configured
- EAS builds deferred until cloud credentials and CI policy defined

## CI policy

- No `build` script in workspace — does not run on `npm run quality`
- Future: `typecheck` only when Expo scaffold is valid

## Milestones

See `docs/ROADMAP_FULL_COMPLETION.md` Track D.
