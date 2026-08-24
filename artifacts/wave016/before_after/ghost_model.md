# Before / After — Ghost nameplate

## Before
- Failure mode: nameplate Label visible while 3D/proxy model absent (TASTE-002 / Q0).

## After
- `Fighter.ensure_visible_presentation()`: if model missing, show ColorRect body fallback; nameplate only when a body representation exists.
- Called on configure, animation play, KO, and respawn.

Harness: `TasteGateModelVisibility.gd` + Ember lifecycle in Wave016 E2E.
