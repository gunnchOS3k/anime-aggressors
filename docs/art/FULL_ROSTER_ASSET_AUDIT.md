# Full-roster asset audit

`FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE=false`

No human-authored candidate meshes exist in this checkout. Automation did not invent them.

Machine-readable: `artifacts/art_pipeline/full_roster_asset_audit.json`

## Provenance rules used

| Label | Meaning |
|-------|---------|
| CURRENT_ACCEPTED_ART | Accepted main procedural proxy / its blender source / godot export copy |
| HUMAN_CANDIDATE | Staging asset with real human-source evidence |
| HUMAN_APPROVED | Owner-only. Never set by this pass |
| GENERATED_EXPERIMENT | PR #106 V2–V9 / `art_source/generated` |
| PROCEDURAL_FALLBACK | Historical `proxy/` and `procedural_final/` copies |
| UNKNOWN | Unpromotable leftover |

## Per fighter

All seven: `ember-vale` `rook-ironside` `juno-spark` `kaia-windrow` `nix-calder` `orion-vell` `vesper-nyx`

| Slot | Candidate | Rights | Approved | Fallback shown in Mode A |
|------|-----------|--------|----------|--------------------------|
| Ember Vale | MISSING | undocumented | false | CURRENT_ACCEPTED_ART |
| Rook Ironside | MISSING | undocumented | false | CURRENT_ACCEPTED_ART |
| Juno Spark | MISSING | undocumented | false | CURRENT_ACCEPTED_ART |
| Kaia Windrow | MISSING | undocumented | false | CURRENT_ACCEPTED_ART |
| Nix Calder | MISSING | undocumented | false | CURRENT_ACCEPTED_ART |
| Orion Vell | MISSING | undocumented | false | CURRENT_ACCEPTED_ART |
| Vesper Nyx | MISSING | undocumented | false | CURRENT_ACCEPTED_ART |

Typical accepted files per fighter:

- `game-godot/content/fighters/<id>/model/<id>_procedural_proxy.glb`
- `assets/blender/fighters/<id>/<id>.blend`
- `assets/exports/godot/fighters/<id>.glb`

Generated experiment on this branch (not selected):

- `art_source/generated/procedural/<id>/<id>_procedural_proxy.glb`

Generated production GLBs exist only on frozen PR #106 (`8cd3e135…`) as `<id>_generated_production.glb`. They are `GENERATED_EXPERIMENT` and stay off this resolver.

`UNKNOWN` leftovers (repo-root `content/fighters/...` copies) are classified as current accepted art after path-normalization. Nothing UNKNOWN is promoted.

## Rights matrix

| Fighter | SOURCE_KNOWN | RIGHTS_DECLARATION_PRESENT | COMMERCIAL_USE_STATUS | GENERATED_EXPERIMENT | HUMAN_CANDIDATE_RIGHTS_READY |
|---------|--------------|----------------------------|-----------------------|----------------------|------------------------------|
| all seven | false | false | undocumented | false | false |

## Missing for Pixel Mode B

Every fighter is missing the production mesh/rig and the minimum review actions:
`idle walk run charged_idle heavy hurt_heavy launch super clash_lock`
