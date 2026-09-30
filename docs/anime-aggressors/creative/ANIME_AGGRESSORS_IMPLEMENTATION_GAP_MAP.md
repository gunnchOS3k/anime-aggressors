# Anime Aggressors — Implementation Gap Map

Status: **honest inventory** as of exact-head `d94bc095` (Pixel watermark `AA d94bc0950779`). Doctrine files in this folder are not evidence that a row is done.

`HUMAN_ART_APPROVAL=false`
`MERGE_AUTHORIZED=false`

Categories: IMPLEMENTED_NOW, PARTIAL_RUNTIME, DOCUMENTED_ONLY, NEEDS_ART_CREATION, NEEDS_MODELING, NEEDS_RIGGING, NEEDS_ANIMATION, NEEDS_WRITING, NEEDS_UI, NEEDS_GAMEPLAY_INTEGRATION, NEEDS_STORY_ROUTING, NEEDS_HUMAN_REVIEW, POST_V1.

## Models

| Item | Category | Truth |
|---|---|---|
| Nine souls on the versus roster | IMPLEMENTED_NOW | Selectable, including Yin and Yang |
| Male/female button and data path | PARTIAL_RUNTIME | Variant is stored and passed. On device the silhouette barely changes |
| Kaia/Yin/Yang block bodies | PARTIAL_RUNTIME | `ART_DIRECTION_CANDIDATE_V1_6`. Unacceptable as the look |
| Ember, Rook, Juno, Nix, Orion, Vesper cards | PARTIAL_RUNTIME | Old chibi / skull / toy meshes. Unacceptable |
| Board-faithful meshes, 18 base forms | NEEDS_MODELING | Not started as real meshes |
| Faces, hair, ribbons, rings | NEEDS_ART_CREATION then NEEDS_MODELING | Boards exist. Game meshes do not |
| Shared production rig on those meshes | NEEDS_RIGGING | Rig-candidate labels on old assets are not this |
| Match scale | PARTIAL_RUNTIME | Figures are too small on Training Grid |
| Dev art-source overlay | IMPLEMENTED_NOW | Hidden unless `AA_DEV_UI=1`. Do not show it to players |

## Male / female

| Item | Category |
|---|---|
| Presentation JSON records for 18 forms | IMPLEMENTED_NOW |
| Visible sex difference a player can see | NEEDS_MODELING |
| Same moveset across sexes | IMPLEMENTED_NOW as policy; do not split hitboxes |

## Animation versus the move sheets

| Item | Category | Truth |
|---|---|---|
| Move data and combat | IMPLEMENTED_NOW | Matches run |
| Move-sheet performances | NEEDS_ANIMATION | 285 of 392 traced clips are procedural JSON |
| Representative poses on the three block bodies | PARTIAL_RUNTIME | A few poses. Not the sheet |
| Victory, hurt, launch as board poses | NEEDS_ANIMATION | Results still showed a mannequin on the prior build; block victory is not the board |

## Story

| Item | Category | Truth |
|---|---|---|
| Web `#/story` director, 7 routes, essence numbers, QA | PARTIAL_RUNTIME | Draft copy. Not a campaign |
| Godot Android Story menu | NEEDS_STORY_ROUTING | Confirmed absent |
| Prologue through epilogue | DOCUMENTED_ONLY | This folder |
| Dialogue | NEEDS_WRITING | Voice guide is a law, not a script |
| Cutscenes | NEEDS_ART_CREATION | None exist |
| Black/White puppet meshes | NEEDS_MODELING | |
| Kaia essence 1 / 2 / 4 / 6 meshes | NEEDS_MODELING | |
| Essence and puppet applied in a real chapter | NEEDS_GAMEPLAY_INTEGRATION | Web can set flags. Android cannot enter the mode |
| Story stages | POST_V1 | Training Grid is not a story place |

## UI

| Item | Category |
|---|---|
| Versus, select, stage, results flow on Android | IMPLEMENTED_NOW |
| Select chrome worthy of the boards | NEEDS_UI |
| Large preview that matches the card | NEEDS_MODELING |
| Story chapter select on device | NEEDS_STORY_ROUTING and NEEDS_UI |

## Review

| Item | Category |
|---|---|
| Side-by-side of any new mesh against the V4.5 boards | NEEDS_HUMAN_REVIEW |
| Setting art approval or merge | NEEDS_HUMAN_REVIEW | Automation must leave both false |

## What not to call done

- Final art
- A chibi model bible implemented in-engine
- Story mode
- Male and female as a visible pair
- Move-sheet animation
- G6, G8, G9, or merge

`HUMAN_ART_APPROVAL=false`
`MERGE_AUTHORIZED=false`
