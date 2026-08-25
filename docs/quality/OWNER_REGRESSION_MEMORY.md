# Owner Regression Memory

**Authority:** Edmund taste + player-visible failures.  
**Scope:** Every future player-facing engineering wave must reference and preserve these.

| ID | Name | Failure | Wave019 adversarial coverage |
|----|------|---------|------------------------------|
| OWNER-REG-001 | HUD without body | Nameplate/HUD visible while fighter body absent | Battle visibility invariant + Pixel body counts |
| OWNER-REG-002 | Select preview ghost | Rapid character cycling causes preview models to disappear | Select preview stress (≥ Wave018 levels) |
| OWNER-REG-003 | Invisible after select | Battle begins with invisible selected fighter after select cycling | Select→battle continuity per fighter |
| OWNER-REG-004 | Generic animation | Gameplay move exists but generic animation appears | Motion identity + move preview authenticity |
| OWNER-REG-005 | Placeholder projectile | Projectile looks like moving rectangle/capsule placeholder | Power identity v2 + intentional poly audit |
| OWNER-REG-006 | Debug labels | Development/proxy labels visible in player build | Player-build debug label scan |
| OWNER-REG-007 | Mannequin sameness | Character models too similar / procedural-mannequin-like | Proportion/silhouette fingerprints + owner blind sheet |

## Rules

1. Do not close a player-facing wave that reintroduces any OWNER-REG without an explicit regression note.
2. Wave018 visibility telemetry and tests remain the floor for 001–003.
3. Wave019 raises the floor for 004–007 via motion/power/identity convergence + move list authenticity.
4. Cursor must not mark human taste PASS for these; only automation evidence + owner review.

## Status entering Wave019

| ID | Accepted Wave018 status | Wave019 goal |
|----|-------------------------|--------------|
| OWNER-REG-001 | Guarded (invariants) | Preserve |
| OWNER-REG-002 | Guarded (stress=0 ghosts) | Preserve |
| OWNER-REG-003 | Guarded (select→battle) | Preserve |
| OWNER-REG-004 | Partially improved (Wave016 mapping) | Strengthen visible personality |
| OWNER-REG-005 | Partially improved (Wave018 polys) | Strengthen beyond color-only |
| OWNER-REG-006 | Guarded (player-build scan) | Preserve |
| OWNER-REG-007 | Open (uplifted proxies) | Material distinctness toward STRONGLY_DISTINCT_NONFINAL_CANDIDATES |
