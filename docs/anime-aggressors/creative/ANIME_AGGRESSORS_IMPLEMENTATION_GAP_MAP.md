# Anime Aggressors — Implementation Gap Map

Status: **honest inventory** after the Kaia golden-slice candidate and Green Between skeleton. Not final art. Not a finished campaign.

Doctrine source of truth: [authority_pack_v1/](authority_pack_v1/README.md).
Contradictions with the `e15a343` docs: [AUTHORITY_RECONCILIATION.md](AUTHORITY_RECONCILIATION.md).

`HUMAN_ART_APPROVAL=false`
`MERGE_AUTHORIZED=false`

Checked for the golden-slice pass. Pixel screenshots of this candidate are a separate device step.

- Kaia shipping path loads `GOLDEN_SLICE_CANDIDATE` male and female GLBs (about 21k triangles, about 3.3 head units). The mesh is a procedural elemental chibi, not a painted match to the V4.5 boards. `FINAL_CHARACTER_ART_PASS` stays false.
- Ember, Rook, Juno, Nix, Orion, and Vesper remain procedural proxies. Yin and Yang remain the V1.6 block candidates.
- Godot main menu has a Story item that opens The Green Between skeleton: Kaia intro, Juno+Nix recruitment, Rook First Loss, campaign map. Copy is `DRAFT_NARRATIVE_COPY`. `STORY_IMPLEMENTATION_COMPLETE` stays false.
- Web `#/story` (`apps/web/src/screens/StoryCampaignScreen.ts`): seven-route scaffold. On-screen copy is `DRAFT_NARRATIVE_COPY`. That web screen is not this Godot skeleton.
- `packages/game-core/src/story/storyDirector.ts` still builds draft encounter graphs. It is not the campaign bible.

Categories: IMPLEMENTED_NOW, PARTIAL_RUNTIME, DOCUMENTED_ONLY, NEEDS_ART_CREATION, NEEDS_MODELING, NEEDS_RIGGING, NEEDS_ANIMATION, NEEDS_WRITING, NEEDS_UI, NEEDS_GAMEPLAY_INTEGRATION, NEEDS_STORY_ROUTING, NEEDS_HUMAN_REVIEW, FUTURE_WORK.

## Models

| Item | Category | Truth |
|---|---|---|
| Nine souls on the versus roster | IMPLEMENTED_NOW | Selectable, including Yin and Yang. Selection is not the story unlock. |
| Male/female button and data path | PARTIAL_RUNTIME | Variant is stored and passed. On the last device look, the silhouette barely changes. |
| Kaia golden-slice candidate | PARTIAL_RUNTIME | Shipping male and female GLBs. Elemental chibi, human-ish face, ribbons and an airfoil. Not the painted board. Not approved. |
| Yin and Yang block bodies | PARTIAL_RUNTIME | Still `ART_DIRECTION_CANDIDATE_V1_6`. Unacceptable as the look. |
| Ember, Rook, Juno, Nix, Orion, Vesper cards | PARTIAL_RUNTIME | Old chibi, skull, and toy meshes. Unacceptable. |
| Board-faithful stylized 3D chibi meshes | NEEDS_MODELING | Kaia is a candidate in the 3.2–3.5 range. It does not match the painted sheets. The other six are not rebuilt. |
| Faces, hair, elemental materials, ribbons, rings | NEEDS_ART_CREATION then NEEDS_MODELING | Boards are in `authority_pack_v1/references/`. Game meshes are not those boards. |
| Canonical deform rig and sockets | PARTIAL_RUNTIME | Kaia candidate uses the pack bone list and the nine sockets. The other fighters do not. |
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
| Godot Story menu | PARTIAL_RUNTIME | Main menu Story opens The Green Between. Not Labs-only. |
| The Green Between skeleton | PARTIAL_RUNTIME | Four nodes, save file, essence, route locks. Not the Prismatic Routes or Sevenfold Convergence. `implementation_complete` stays false. |
| Rook as Kaia's canonical First Loss | PARTIAL_RUNTIME | The skeleton sets the canonical flag on that node. It is not a written chapter. |
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
