# Anime Aggressors — Implementation Gap Map

Status: **honest inventory** after Creative Authority Pack V1 ingest.

Doctrine source of truth: [authority_pack_v1/](authority_pack_v1/README.md).
Contradictions with the `e15a343` docs: [AUTHORITY_RECONCILIATION.md](AUTHORITY_RECONCILIATION.md).

`HUMAN_ART_APPROVAL=false`
`MERGE_AUTHORIZED=false`

Checked again for this ingest. Not a new Pixel screenshot pass.

- Player-facing meshes and scenes are the same code as `d94bc095` (watermark family `AA d94bc0950779`). Commit `e15a343` and this ingest are documentation. They do not add a board-faithful mesh.
- Godot main menu (`game-godot/scenes/menus/MainMenuScene.tscn`): Fight, Training, Rulesets, Roster, Stages, Controls, Settings, Achievements, Credits, Labs, Mobile Playtest. **No Story route.**
- Web `#/story` (`apps/web/src/screens/StoryCampaignScreen.ts`): seven-route scaffold. On-screen copy is `DRAFT_NARRATIVE_COPY`. That is not The Green Between, not the Prismatic Routes, and not Sevenfold Convergence.
- `packages/game-core/src/story/storyDirector.ts` still builds draft encounter graphs. It is not the campaign bible.

Categories: IMPLEMENTED_NOW, PARTIAL_RUNTIME, DOCUMENTED_ONLY, NEEDS_ART_CREATION, NEEDS_MODELING, NEEDS_RIGGING, NEEDS_ANIMATION, NEEDS_WRITING, NEEDS_UI, NEEDS_GAMEPLAY_INTEGRATION, NEEDS_STORY_ROUTING, NEEDS_HUMAN_REVIEW, FUTURE_WORK.

## Models

| Item | Category | Truth |
|---|---|---|
| Nine souls on the versus roster | IMPLEMENTED_NOW | Selectable, including Yin and Yang. Selection is not the story unlock. |
| Male/female button and data path | PARTIAL_RUNTIME | Variant is stored and passed. On the last device look, the silhouette barely changes. |
| Kaia, Yin, Yang block bodies | PARTIAL_RUNTIME | `ART_DIRECTION_CANDIDATE_V1_6`. Unacceptable as the look. Pack says replace player-facing. |
| Ember, Rook, Juno, Nix, Orion, Vesper cards | PARTIAL_RUNTIME | Old chibi, skull, and toy meshes. Unacceptable. |
| Board-faithful stylized 3D chibi meshes | NEEDS_MODELING | Not started. Pack target is about 3.0–3.5 heads, not the retired 4.5–5.5 note. |
| Faces, hair, elemental materials, ribbons, rings | NEEDS_ART_CREATION then NEEDS_MODELING | Boards are in `authority_pack_v1/references/`. Game meshes are not those boards. |
| Canonical deform rig and sockets | NEEDS_RIGGING | Pack bone list is the contract. Old assets are not that rig. |
| Puppet and Prismatic Gray presentation for all seven spectrum fighters | NEEDS_MODELING | Doctrine. Not in the game. Prior "Kaia ladder only" count is retired. |
| Yin/Yang cosmic boss versus normalized playable presentation | DOCUMENTED_ONLY | Two contracts. Not built. |
| Match scale | PARTIAL_RUNTIME | Figures are too small on Training Grid. Pack forbids a colored-dot camera. |
| Dev art-source overlay | IMPLEMENTED_NOW | Hidden unless a dev flag is set. Keep it off for players. |

Current block and proxy direction: **NOT APPROVED.**

## Male / female

| Item | Category |
|---|---|
| Presentation records for 18 forms | IMPLEMENTED_NOW |
| A player can tell the presentation without reading the label | NEEDS_MODELING |
| Same moves, frame data, damage, and hitboxes across presentations | IMPLEMENTED_NOW as policy |

## Animation

| Item | Category | Truth |
|---|---|---|
| Move data and combat | IMPLEMENTED_NOW | Matches run. |
| 111 semantic slots, authored, per identity | NEEDS_ANIMATION | Pack target. Procedural JSON does not count. Prior trace: 285 of 392 clips were procedural. That code did not change in this ingest. |
| Move-sheet performances | NEEDS_ANIMATION | Not the arcade or fight boards. |
| `back_air` as a current required extension | IMPLEMENTED_NOW as a slot requirement | Not evidence of board-faithful motion. |

## Story

| Item | Category | Truth |
|---|---|---|
| Web `#/story` director, 7 routes, essence numbers, QA controls | PARTIAL_RUNTIME | Draft copy only. It does not implement The Green Between. |
| Godot Android Story menu | NEEDS_STORY_ROUTING | Confirmed absent on this tree. |
| The Green Between, Prismatic Routes, Sevenfold Convergence | DOCUMENTED_ONLY | Pack bible and `STORY_CAMPAIGN_MANIFEST.json` (`implementation_complete: false`). |
| Rook as Kaia's canonical First Loss | DOCUMENTED_ONLY | Not a playable chapter. |
| First Loss on Ember, Rook, Juno, Nix, Orion, and Vesper routes | OPEN CANON | Do not assign in code. |
| Dialogue and puppet language law | NEEDS_WRITING | Guidance, not a script and not recorded voice. |
| Scene types (cinematic, walk-and-talk, objective battle, transformation, aftermath) | FUTURE_WORK | None of these scenes exist. |
| Black/White puppet and Gray presentation in a real chapter | NEEDS_GAMEPLAY_INTEGRATION | Web can set flags. Android cannot enter Story. |
| Playable Yin and Yang story unlock | FUTURE_WORK | Versus already lists them. That is not the convergence unlock. |
| Story stages | FUTURE_WORK | Training Grid is not a story place. |

## UI

| Item | Category |
|---|---|
| Versus, select, stage, results flow on Android | IMPLEMENTED_NOW |
| Select preview a person can match to the V4.5 board | NEEDS_MODELING and NEEDS_UI |
| Story chapter select on device | NEEDS_STORY_ROUTING and NEEDS_UI |

## Review

| Item | Category |
|---|---|
| Side-by-side of any new mesh against the V4.5 boards | NEEDS_HUMAN_REVIEW |
| Setting art approval or merge | NEEDS_HUMAN_REVIEW | Both stay false. |

## What not to call done

- Final art, G6, G8, G9, or merge
- A chibi model bible implemented in-engine
- Story mode, The Green Between, or Sevenfold Convergence
- Male and female as a visible pair
- Move-sheet animation
- Board match. The references are the target. The runtime is not the references.

`HUMAN_ART_APPROVAL=false`
`MERGE_AUTHORIZED=false`
