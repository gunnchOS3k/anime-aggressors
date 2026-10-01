# Authority reconciliation — Pack V1 vs doctrine at e15a343

Status: **decision record**. Not runtime evidence. Not art approval.

`HUMAN_ART_APPROVAL=false`
`MERGE_AUTHORIZED=false`

Pack V1 is the creative source of truth. The source authority matrix decides winners. This file records contradictions instead of deleting the earlier docs. Those earlier docs stay in this folder with superseded banners.

Rules used:

1. V4.5 boards are the primary visual authority. They beat runtime toys, block candidates, and mannequins.
2. A **PRODUCTION DECISION V1** in the pack is the build rule. It is an owner-approval candidate for direction. It is not `HUMAN_ART_APPROVAL`.
3. An **OPEN CANON DECISION** stays open. This ingest does not invent it.
4. **IMPLEMENTATION TRUTH** is separate from doctrine. Nothing in the pack makes the current game match the boards.

Runtime code is unchanged since `d94bc095` (parent of the prior doctrine commit `e15a343`). This ingest is documentation only.

## What the pack required

- Treat each fighter as a motion identity, not a mesh with effects pasted on.
- Replace player-facing block, toy, skull, and mannequin art with faithful stylized 3D chibi adaptations of the V4.5 sheets.
- Keep male and female as the same soul and the same competitive authority, with a visible presentation change.
- Give every spectrum fighter normal, Black Puppet, White Puppet, and Prismatic Gray story presentation.
- Lock The Green Between as Kaia's root story, then six Prismatic Routes, then Sevenfold Convergence, then playable Yin and Yang.
- Leave non-Kaia First Loss identities, final screenplay wording, casting, music, shot lists, chapter counts, and difficulty tuning unset.
- Do not claim the game already implements the campaign.

The pack README does not authorize a mesh rebuild in this pass. This change is an authority ingest and an honest gap update.

## Proportion and chibi rules

| Topic | Prior doctrine (`e15a343` chibi bible) | Pack V1 | Winner |
|---|---|---|---|
| Head-to-body ratio | Head is 1/4.5 to 1/5.5 of height. Explicit fail: "toy head." | **PRODUCTION DECISION V1.** About 3.0–3.5 head units. Rook about 2.8–3.1. Nix about 3.0–3.2. Ember, Orion, Yin, Yang about 3.1–3.3. Juno, Kaia, Vesper about 3.2–3.5. Adjustable after Pixel review. The roster stays one family. | Pack. The matrix says these numbers were authored in the pack. They were not measured off the boards and they were not in the prior repo bible. |
| "Not a toy" | Used to reject super-deformed heads and the current hat/cube look. | Used to reject redesigning the cast into generic toys. The numerical range is still the chibi target. | Both sentences can stand. The current hat chibis and boxes still fail. The modeling target is the pack range, not 4.5–5.5. |
| Triangle budget | A 4–8k body with a face was preferred to cubes. | LOD0 18k–35k triangles. Above 45k needs justification. LOD1 8k–18k. LOD2 3k–8k. | Pack. |
| Skin | Palette atlas included a "skin-element" slot. | Ordinary human-skin completion is not the default. Bodies are elemental materials. Faces stay human in structure. | Pack, consistent with the boards. |
| Rig names | Root, pelvis, spine x2, chest, neck, head, clavicle. | Canonical deform list: Root, Hips, Spine, Chest, Neck, Head, Shoulder/arm/hand, leg/foot/toe. Required sockets listed in the model bible and `MODEL_ROSTER_AUTHORITY.json`. | Pack is the export contract. |
| Mesh strategy | Counted 36 unique meshes, including separate puppet and Kaia essence meshes. | Prefer one identity mesh plus material and secondary geometry for puppets and Gray. Separate Gray GLBs are allowed. Do not make seven unrelated Gray meshes. Yin and Yang have `COSMIC_BOSS` and `PLAYABLE` contracts. | Pack. |
| Animation scope | A short state list (idle through victory). | 111 semantic slots per identity. About 90–100 unique clips where aliases exist. `back_air` stays a required current-game extension. Procedural fallback is not authored completion. | Pack. |
| Gray who | Kaia ladder only. | All seven spectrum fighters need a Prismatic Gray story presentation. Competitive Gray keeps base frame data, hitboxes, movement, damage, knockback, and recovery. | Pack. |

## Roster

Player-facing epithets on the boards stay the display names. The pack sometimes uses a philosophical name as a section title. That is a narrative alias, not a rename.

| Fighter | Board epithet (visual authority) | Pack section title | Decision |
|---|---|---|---|
| Ember Vale | The Living Flame | The Living Furnace | Display name stays **The Living Flame**. "Furnace" remains a material metaphor (furnace core), not a new title. |
| Rook Ironside | The Walking Bastion | The Walking Bastion | Agree. |
| Juno Spark | The Arc Courier | The Arc Courier | Agree. |
| Nix Calder | The Crystal Tactician | The Cryolattice Architect | Display name stays **The Crystal Tactician**. Architect/controller is the acceptance read, not a rename. |
| Orion Vell | The Orbital Marshal | The Orbital Marshal | Agree. Spectral name in the story bible is indigo. Older doctrine called the element violet. Hex in the pack is `#5140C8`. |
| Vesper Nyx | The Phase Weaver | The Phase Weaver | Agree. |
| Yin | The Inward Collapse | The Infinite Quiet | Display epithet stays **The Inward Collapse**. Infinite Quiet is the story name for the principle. |
| Yang | The Outward Expansion | The Absolute Radiance | Display epithet stays **The Outward Expansion**. Absolute Radiance is the story name for the principle. |

### Kaia epithet is not uniform on the boards

The matrix lists all four boards as primary visual authority and does not rank them against each other. They do not share one subtitle:

- Character design sheet (`V45_04`): **The Skyflow Duelist**
- Arcade animation study, Kaia section, and the fight move sheet: **The Skyflow Bulwark**
- 3D cartoon style study nameplate: **The Skyflow Oblivion**

The pack uses **The Skyflow Duelist**, matching the character design sheet. The golden-slice playbook locks the production display epithet to **The Skyflow Duelist** for this candidate. Bulwark and Oblivion stay recorded board strings and are not the display name. This lock is not `HUMAN_ART_APPROVAL`.

Other roster locks that agree across the pack, the boards, and the prior doctrine:

- Nine identities. Male and female are presentations, not extra fighters.
- Base roster has human facial structure and no puppet masks.
- Black Puppet is Yin control. White Puppet is Yang control. Masks are allowed there.
- One remnant of the original hue survives under control.
- Essence steps are 0, 1, 2, 4, 6. At 6 the anchor is Prismatic Gray: all seven colors, none in charge.
- A model must read with VFX off, in grayscale, at 25% scale, and in a mirror match.
- Current block, hat, skull, and mannequin art is not approved.

Prior sex-specific silhouette notes (sharper crest, heavier plant, and similar) may inform modeling only when they stay inside the pack's gameplay envelope. They must not make female Rook read as a speed fighter, must not be a scaled-down male, and must not change reach.

The prior note that a Vesper skull may survive as a story-mask echo is not in the pack. It is not canon. Puppet masks are allowed. A generic skeleton is not Vesper's final design.

## Story structure

The prior campaign bible and `story_chapter_outline.md` described a different story. The matrix says the narrative source is The Green Between, the spectral wheel, distinct Gray lessons, First Loss, five puppets, Essence, 2v2 equilibrium, Sevenfold Convergence, and a Yin/Yang unlock. The pack wins.

| Topic | Prior doctrine | Pack V1 | Winner |
|---|---|---|---|
| Shape | One Kaia campaign: prologue, Ember-first Act I, a teaching puppet act, Yin then Yang fights, Gray versus puppet Kaias, epilogue. | Root story **The Green Between**, then six Prismatic Routes, then **Sevenfold Convergence**. | Pack. |
| Recruitment | Ember, Rook, Juno, Nix, Orion, Vesper, then a return. Essence ticks after those fights. | Kaia, then Juno+Nix, Rook+Orion, Ember+Vesper, then the Sevenfold Accord. | Pack. |
| First Loss | Not Rook. Ember is "first ally." The teaching loss-state puppets Ember (Black) and Nix (White). | **CANONICAL:** Rook is Kaia's First Loss. It is the tragic extreme of his virtue, not a mistake. | Pack. |
| Puppet act | One teaching chapter, then masks clear on a win. | Five remaining allies split 3 vs 2. Kaia frees one fighter and restores 2 vs 2. Later releases happen in Yin/Yang pairs. | Pack. |
| Gray | Kaia only. "No secret fighter." | All seven anchors can reach Prismatic Gray. Story Gray may be enhanced. Versus Gray must not change competitive authority. | Pack. |
| Ending | Mixed sky. Yin and Yang stay principles. No unlock and no stat reward. | Equilibrium, then route unlocks. After all seven Grays, Sevenfold Convergence. Then `YIN_PLAYABLE` and `YANG_PLAYABLE`. | Pack for the intended campaign. Not implemented. |
| Yin/Yang in versus | Prior text said they are not unlocked fighters. | Boss contracts (`YIN_COSMIC_BOSS`, `YANG_COSMIC_BOSS`) are cosmic and unfair. Playable contracts are normalized platform-fighter kits. A versus win is not a canonical claim that Ember overpowers cosmic Yang. | Pack. Selectable Yin/Yang rows that already exist in versus are not this story unlock. |
| Other routes' First Loss | Unspecified, because the outline was Kaia-only. | **OPEN CANON DECISION.** Do not assign them. The lost ally must expose that protagonist's flaw. | Leave open. |
| Dialogue | One leftover word per puppet ("burn", "hold", and similar). | Black subtracts language. White over-specifies it. Sample lines are writing guidance, not recorded assets. | Pack. Samples in both files are not a locked script. |

Open on purpose, and still open after this ingest:

- final screenplay wording
- First Loss identity on the six non-Kaia routes
- voice casting
- music
- cutscene shot lists
- exact chapter count after pacing tests
- story difficulty

## Golden-slice pass after the ingest

The ingest above did not change runtime. A later playbook pass on this same draft branch builds one Kaia candidate and a story skeleton:

- Display epithet in that candidate is **The Skyflow Duelist**.
- Shipping Kaia loads `GOLDEN_SLICE_CANDIDATE` male and female meshes. That is a review candidate, not board-matched final art.
- Ember, Rook, Juno, Nix, Orion, and Vesper stay procedural proxies.
- Godot main menu has a Story item. The Green Between is a four-node skeleton through Rook as Kaia's First Loss. `STORY_IMPLEMENTATION_COMPLETE` stays false.
- Other routes' First Loss identities stay unassigned.

## What the ingest itself did not change

- The ingest commit did not rebuild a mesh, rig, animation, scene, or route.
- `human_art_approval` in `MODEL_ROSTER_AUTHORITY.json` stays false.
- `implementation_complete` in `STORY_CAMPAIGN_MANIFEST.json` stays false.
- `HUMAN_ART_APPROVAL=false`. `MERGE_AUTHORIZED=false`.
- Draft PR #118 is not merged. The staging Worker and Pages drafts were not touched. The pack does not ask for a deploy.
