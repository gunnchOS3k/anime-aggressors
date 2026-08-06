# Manual Device Runbook — Anime Aggressors (Gate 1)

Statuses target: `CORE_LOOP_IMPLEMENTED` · `CORE_LOOP_AUTOMATED_EVIDENCE_PASS` · `PHYSICAL_PLAYTEST_PENDING`

## Preconditions
- Branch: `cursor/gate-1-integrated-development-platform`
- Device charged; screen recording permission granted
- Log collector ready: `gate1/tools/log_collector.*`

## Core loop (must complete — launch alone is insufficient)
1. Boot / title
2. Mode select
3. Character select
4. Stage select
5. Battle start
6. Aura charge
7. Hand-to-hand
8. Projectile/special
9. Defense/recovery
10. KO / end
11. Results
12. Rematch
Note: Prefer Godot build. Do not overwrite Unity PR #51/#52 work.

## Pass criteria
- Every step above observed on device
- JSONL events collected (or manual checklist signed) with schema fields present
- Save/results screen captured; rematch/restart verified
- Accessibility spot-checks completed (`gate1/evidence/accessibility_checks.json`)

## Fail criteria
- Soft-lock, crash, missing results, or inability to rematch/restart
- Using copyrighted ripped audio (Beat Link) or claiming complete species coverage (Archive of Life)
