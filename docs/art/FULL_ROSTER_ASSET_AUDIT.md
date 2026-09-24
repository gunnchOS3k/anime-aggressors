# Full-roster asset audit

`FULL_ROSTER_HUMAN_CANDIDATES_COMPLETE` is computed by `tools/art_pipeline/human_art/audit_full_roster_assets.py`.

Machine-readable: `artifacts/art_pipeline/full_roster_asset_audit.json`

This pass sources **KayKit CC0** characters, adapts them to the existing staging contract, and labels them `HUMAN_CANDIDATE` only. Production still defaults to `CURRENT_ACCEPTED_ART`.

## Provenance rules used

| Label | Meaning |
|-------|---------|
| CURRENT_ACCEPTED_ART | Accepted main procedural proxy / blender source / godot export copy |
| HUMAN_CANDIDATE | Staging asset with real CC0 source evidence |
| HUMAN_APPROVED | Owner-only. Never set by this pass |
| GENERATED_EXPERIMENT | PR #106 V2–V9 / `art_source/generated` |
| PROCEDURAL_FALLBACK | Historical `proxy/` and `procedural_final/` copies |
| UNKNOWN | Unpromotable leftover |

## Source packs (verified)

| Pack | Author | License | Repo redistribution | Used |
|------|--------|---------|---------------------|------|
| [KayKit Character Pack : Adventurers 1.0](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0) | Kay Lousberg | CC0 1.0 | Yes (GitHub publish) | Ember, Rook, Juno, Kaia, Orion |
| [KayKit Character Pack : Skeletons 1.0](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0) | Kay Lousberg | CC0 1.0 | Yes (GitHub publish) | Nix, Vesper |
| Kenney Mini / Blocky / Prototype | Kenney | CC0 1.0 | Yes | Inspected only; 8-bone / no-skin rigs cannot meet the 22-bone deform contract without fabricating bones |
| Quaternius Ultimate Animated Character Pack | Quaternius | OGA 2021 listing said CC0; current [QAL v1.0](https://quaternius.com/license.html) forbids redistributing assets as assets | Unclear | **Not used** |

## Per fighter

| Fighter | Source character | License | Mesh/rig/materials | Min clips | Complete | Resolver label |
|---------|------------------|---------|--------------------|-----------|----------|----------------|
| Ember Vale | KayKit Mage | CC0 1.0 | Adapted GLB + 1 material | 9/9 mapped | yes | HUMAN_CANDIDATE |
| Rook Ironside | KayKit Barbarian | CC0 1.0 | Adapted GLB + 1 material | 9/9 mapped | yes | HUMAN_CANDIDATE |
| Juno Spark | KayKit Rogue | CC0 1.0 | Adapted GLB + 1 material | 9/9 mapped | yes | HUMAN_CANDIDATE |
| Kaia Windrow | KayKit Rogue Hooded | CC0 1.0 | Adapted GLB + 1 material | 9/9 mapped | yes | HUMAN_CANDIDATE |
| Nix Calder | KayKit Skeleton Mage | CC0 1.0 | Adapted GLB + 2 materials | 9/9 mapped | yes | HUMAN_CANDIDATE |
| Orion Vell | KayKit Knight | CC0 1.0 | Adapted GLB + 1 material | 9/9 mapped | yes | HUMAN_CANDIDATE |
| Vesper Nyx | KayKit Skeleton Rogue | CC0 1.0 | Adapted GLB + 2 materials | 9/9 mapped | yes | HUMAN_CANDIDATE |

Identity is **silhouette / gear / palette approximation**. None of these are custom lore-accurate originals.

Clip mapping (source name → contract id) is in each `candidate_manifest.json` and `tools/art_pipeline/human_art/cc0_roster_map.json`.

## Honest adaptations

- Rename KayKit deform bones to the canonical contract names.
- Insert empty `Neck`, `Shoulder_L`, `Shoulder_R` because KayKit has no separate neck/shoulder deform bones.
- Add required socket empties.
- Keep only the nine min-review clips and rename them.
- Tint imported materials for lane color. Textures remain KayKit atlas/gradient textures.
- IK/control bones from the source pack remain; they are not claimed as the deform contract.

## Rights matrix

| Fighter | SOURCE_KNOWN | RIGHTS_DECLARATION_PRESENT | COMMERCIAL_USE_STATUS | GENERATED_EXPERIMENT | HUMAN_CANDIDATE_RIGHTS_READY |
|---------|--------------|----------------------------|-----------------------|----------------------|------------------------------|
| all seven | true | true | commercial_use_allowed | false | true |

Attribution is not required. Credit Kay Lousberg if convenient.
