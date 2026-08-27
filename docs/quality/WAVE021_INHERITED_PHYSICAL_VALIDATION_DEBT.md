# Wave021 Inherited Physical Validation Debt

## Context

PR #95 (Wave020 presentation isolation) merged at `0d094349e2aa6a7bbb4e7cdec4694ab33e585593`.

Wave021 branch builds on that merge tip. **PR95 Pixel gates 0–4 were not re-verified on the exact Wave021 HEAD** during this engineering pass.

## Inherited from PR95

| Gate | PR95 status | Wave021 re-run |
|------|-------------|----------------|
| Gate A — Select lifecycle | PASS at PR95 merge | NOT re-verified on Wave021 tip |
| Gate B — Move preview | PASS at PR95 merge | NOT re-verified on Wave021 tip |
| Gate C — Battle visibility | PASS at PR95 merge | NOT re-verified on Wave021 tip |
| Gate D — Victory | Partial / blocked offline | NOT re-verified on Wave021 tip |
| Gate 4 — Owner soak | Pending device | NOT re-verified on Wave021 tip |

## Physical block reason (Wave021 run)

- Pixel 6a (`com.gunnchos.animeaggressors`) **not attached** during Wave021 desktop campaign.
- `PIXEL_WAVE021_VALIDATION=BLOCKED`
- Desktop engineering gates continued honestly; `READY_FOR_OWNER_MERGE=false`.

## Debt policy

This debt **does not block** Wave021 desktop engineering. It **does block** owner merge readiness until Edmund re-runs Pixel gates on Wave021 HEAD or delegates physical validation.

## Required follow-up (owner)

1. Attach authorized Pixel 6a
2. Run `make engineering-wave021` with device online
3. Review `artifacts/engineering_wave021/PIXEL_WAVE021.json`
4. Complete `docs/quality/WAVE021_OWNER_VISUAL_REVIEW.md`
