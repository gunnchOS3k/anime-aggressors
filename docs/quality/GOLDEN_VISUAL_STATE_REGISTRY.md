# Golden Visual State Registry

Wave020 (PR #95) introduces **GoldenVisualQA v1**: ideal-state screenshots plus semantic/geometry/state contracts.

## Approval levels

| Level | Who may set | Meaning |
| --- | --- | --- |
| `ENGINEERING_REFERENCE` | Cursor / engineering | Useful baseline for diffs; not owner-blessed. |
| `OWNER_CANDIDATE` | Cursor may propose; owner promotes | Candidate for owner golden. |
| `OWNER_APPROVED_GOLDEN` | **Edmund only** | Locked golden. Cursor must never set this. |
| `DEPRECATED` | Engineering or owner | Do not compare against. |

## Two evaluation layers

1. **Golden / reference image comparison** — perceptual / structural diff vs the registered reference when present.
2. **Semantic / geometry / state contracts** — identity, bounds, battle contact/camera, UI safe-area, lifecycle correctness. Never rely on raw pixel delta alone.

## Registered states (minimum)

- `SELECT_INITIAL`
- `SELECT_FIGHTER_EMBER` … `SELECT_FIGHTER_VESPER`
- `SELECT_AFTER_7_TRANSITIONS`
- `SELECT_AFTER_20_SWEEPS`
- `PAUSE_MENU`
- `MOVELIST_SIMPLE` / `MOVELIST_ADVANCED` / `MOVELIST_MOVE_PREVIEW`
- `BATTLE_SPAWN` / `BATTLE_ACTIVE` / `BATTLE_AFTER_PAUSE_RESUME` / `BATTLE_KO` / `BATTLE_RESPAWN`
- `VICTORY`

Machine-readable source of truth: [`artifacts/visual_qa/golden_state_registry.json`](../../artifacts/visual_qa/golden_state_registry.json).

## Command

```bash
make visual-golden-qa
```

Emits `artifacts/visual_qa/latest/` and exits non-zero on material deviations (`MISSING_MODEL`, `MATERIAL_WHITEOUT`, `OVERSCALE`, `CONTEXT_STATE_LEAK`, etc.).

## Non-invasiveness

Harnesses must not mutate live materials, force standard materials, or heal presentation on production paths. Witness stays read-only.
