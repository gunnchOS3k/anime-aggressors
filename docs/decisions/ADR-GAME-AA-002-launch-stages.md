# ADR-GAME-AA-002 — Launch stages

**Status:** Accepted (digital Beta content freeze)  
**Date:** 2026-08-08

## Decision

Launch stages = **6** total:

- **5 competitive:** skyline-arena, neon-rooftops, cascade-foundry, void-pier, ember-courtyard
- **1 training:** training-grid

Launch candidates must ship **competitive procedural geometry** (platforms, collision, blast zones, spawns, camera, lighting tiers, hazard sockets, a11y markers, audio beds) — **not** greybox/placeholder ColorRect-only presentation.

Launch shippable stage art is `PROCEDURAL_FINAL` (procedural previews + runtime set-dressing). Optional painted remasters are out of digital token scope.

## Consequences

- `production_stages.json` is the canonical launch list.
- Stage smoke must fail if any launch competitive stage still declares `productionStatus: greybox`.
