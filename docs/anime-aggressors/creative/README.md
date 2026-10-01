# Anime Aggressors creative authority

Status labels for this folder:

| Label | Meaning |
|---|---|
| **DOCTRINE** | Creative target. Not a claim the game already looks or plays this way. |
| **IMPLEMENTED** | Present in the current runtime. See the gap map before calling it done. |
| **FUTURE WORK** | Required by doctrine and not in the game. |

`HUMAN_ART_APPROVAL=false`. `MERGE_AUTHORIZED=false`.

This ingest does not approve art, authorize a merge, or deploy anything. Draft PR #118 stays a draft. Accepted main stays `72e5dada`.

## Source of truth

Creative Authority Pack V1 is the creative source of truth. It lives in [authority_pack_v1/](authority_pack_v1/README.md).

| Pack file | Role |
|---|---|
| [01_FULL_ROSTER_ART_CORRECTION_DIRECTION.md](authority_pack_v1/01_FULL_ROSTER_ART_CORRECTION_DIRECTION.md) | Roster art direction |
| [02_CANONICAL_3D_CHIBI_MODEL_BIBLE.md](authority_pack_v1/02_CANONICAL_3D_CHIBI_MODEL_BIBLE.md) | Modeling, rig, material, and export contract |
| [03_COMPLETE_STORY_MODE_CAMPAIGN_BIBLE.md](authority_pack_v1/03_COMPLETE_STORY_MODE_CAMPAIGN_BIBLE.md) | Campaign structure and voices |
| [04_SOURCE_AUTHORITY_MATRIX.md](authority_pack_v1/04_SOURCE_AUTHORITY_MATRIX.md) | Which source wins |
| [MODEL_ROSTER_AUTHORITY.json](authority_pack_v1/MODEL_ROSTER_AUTHORITY.json) | Machine-readable roster contract. `human_art_approval` stays false |
| [STORY_CAMPAIGN_MANIFEST.json](authority_pack_v1/STORY_CAMPAIGN_MANIFEST.json) | Machine-readable campaign. `implementation_complete` stays false |
| [references/](authority_pack_v1/references/) | V4.5 boards. Primary visual authority |

The V4.5 boards win over current runtime toys, block candidates, and mannequins. They do not mean those meshes are already in the game.

Where this pack and the earlier files in this folder disagree, read [AUTHORITY_RECONCILIATION.md](AUTHORITY_RECONCILIATION.md). Do not implement from the superseded files.

## Honest runtime

[ANIME_AGGRESSORS_IMPLEMENTATION_GAP_MAP.md](ANIME_AGGRESSORS_IMPLEMENTATION_GAP_MAP.md) is the inventory. Current player-facing art is still unacceptable. Story mode is still incomplete. Re-checked at this ingest: Godot's main menu has no Story route, and the web `#/story` screen is still `DRAFT_NARRATIVE_COPY`.

## Prior doctrine, kept on purpose

These files are the `e15a343` pass. They remain in the tree so the contradictions are visible. They are not the active contract.

- [ANIME_AGGRESSORS_FULL_ROSTER_ART_CORRECTION_DOCTRINE.md](ANIME_AGGRESSORS_FULL_ROSTER_ART_CORRECTION_DOCTRINE.md)
- [ANIME_AGGRESSORS_CHIBI_3D_MODEL_BIBLE.md](ANIME_AGGRESSORS_CHIBI_3D_MODEL_BIBLE.md)
- [ANIME_AGGRESSORS_STORY_MODE_CAMPAIGN_BIBLE.md](ANIME_AGGRESSORS_STORY_MODE_CAMPAIGN_BIBLE.md)
- [roster_art_correction.yaml](roster_art_correction.yaml)
- [story_chapter_outline.md](story_chapter_outline.md)
- [dialogue_voice_guide.md](dialogue_voice_guide.md)
- [model_acceptance_checklist.md](model_acceptance_checklist.md)
- [per_fighter_acceptance_checklist.md](per_fighter_acceptance_checklist.md)
