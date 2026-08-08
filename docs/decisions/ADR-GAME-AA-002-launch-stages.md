# ADR-GAME-AA-002 — Launch stages

**Status:** Accepted (digital Beta content freeze)  
**Date:** 2026-08-08

## Decision

Launch stages = **6** total:

- **5 competitive:** skyline-arena, neon-rooftops, cascade-foundry, void-pier, ember-courtyard
- **1 training:** training-grid

Launch candidates must ship **competitive procedural geometry** (platforms, collision, blast zones, spawns, camera, lighting tiers, hazard sockets, a11y markers, audio beds) — **not** greybox/placeholder ColorRect-only presentation.

Painted environment art overlays may remain `REQUIRES_ART_PRODUCTION`. Geometry/presentation runtime for launch candidates is `PROCEDURAL_FINAL`.

## Consequences

- `production_stages.json` is the canonical launch list.
- Stage smoke must fail if any launch competitive stage still declares `productionStatus: greybox`.
