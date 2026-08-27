# Wave022 Engineering Contract

## Scope

Wave022 propagates Wave021 form/ascension architecture across the full 7-fighter roster: faceless heads, aura tiers 0–3, Ascended runtime, move overrides, fighting-game UI presentation, and GoldenVisualQA full-roster ideal states.

## Hard rules

- Edmund sole merge authority — Cursor NEVER merges
- Branch: `eng/wave022-full-roster-ascension`
- ONE draft PR only
- Preserve Wave021 + PR95: FighterDefinition, FormDefinition, PresentationContext, FighterPresentationCache, GoldenVisualQA v2
- Do NOT rewrite Ember — use as reference baseline
- Cursor MUST NOT set `OWNER_APPROVED_GOLDEN`
- Pixel blocked → continue desktop honestly

## Prerequisites

- PR95 merged (`0d094349e2aa6a7bbb4e7cdec4694ab33e585593`)
- PR96 merged (`419c5fc3a500445c21b24f730d2162ff6cffbc38`)
- MAIN_CONTAINS_WAVE021=true

## OWNER-REG gates

| ID | Area |
|----|------|
| OWNER-REG-027 | Full-roster form JSON + ascension_runtime |
| OWNER-REG-028 | Roster ascension propagation (6 fighters beyond Ember) |
| OWNER-REG-029 | Full-roster GoldenVisualQA ideal states |
| OWNER-REG-030 | Cross-roster regression matrix (Wave020 + Wave021 preserved) |
| OWNER-REG-031 | Full-roster transform digital gate (≥30 per fighter, ≥210 total) |

## Desktop pass criteria

- `FULL_ROSTER_TRANSFORM_ACTIVATIONS >= 210`
- Per-fighter `TRANSFORM_ACTIVATIONS >= 30` (digital)
- All failure counters 0
- GoldenVisualQA full-roster semantic layer PASS or PARTIAL
- Wave020 + Wave021 regressions preserved

## Batch order (§32)

1. Clean-start + generic propagation plumbing
2. Rook → Juno → Kaia → Nix → Orion → Vesper
3. Full-roster UI / Move List / Versus / Victory
4. GoldenVisualQA full-roster ideal states
5. Cross-roster regression matrix
6. Pixel fast validation if available
7. Exact-head CI

## Out of scope (STOP §41)

- Merge / human approval claims
- Wave023
- Generic recolor ascensions (each fighter must have distinct identity)
