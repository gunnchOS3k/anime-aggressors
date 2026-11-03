# Anime Aggressors — Requirements-to-Evidence Matrix

**Contract:** `GUNNCHOS3K_PVS@1.0.0`  
**Source SHA pin:** `935eb3a20548b1a4b726f2ba305df94ff496be16` (gunnchos-site `docs/gunnchos3k-product-verification-standard-v1`; ancestry includes `45b4566`)  
**Schema:** `artifacts/cursor_continuation/rtm/requirements_to_evidence_matrix.schema.json`  
**JSON:** `artifacts/cursor_continuation/rtm/ANIME_REQUIREMENTS_TO_EVIDENCE_MATRIX.json`

## Honesty

- `HUMAN` / `RC2` / `V1` = **false**
- `SHIPPING_ROLLBACK_ENABLED` = **false**
- Every row: `independent_review_status` = **not_started**
- Not a certification artifact

## Tip honesty (Trials CI vs doc stamp)

- **Branch tip (post-commit)** is the SHA that must match FF-pushed HEAD.
- **Trials CI coverage tip** = the commit SHA that GitHub Actions ran for `trials-of-convergence` (BodyVariant clean-env + suite).
- **Doc tip stamps** (e.g. `TRIALS_RTM_DEEPEN_TIP_STAMP.json`) may lag or lead by a docs-only stamp commit. Report both SHAs; do not claim CI green on a tip that was never covered.

## Validate

```bash
PYTHONPATH=/path/to/venv/site-packages python3 scripts/validate-anime-rtm.py
```
