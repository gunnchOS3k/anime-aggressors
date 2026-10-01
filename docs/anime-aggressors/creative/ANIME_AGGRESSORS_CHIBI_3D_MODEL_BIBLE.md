# Anime Aggressors — Chibi 3D Model Bible

> **Superseded on conflict by Creative Authority Pack V1.** This file is the prior doctrine pass at `e15a343`. Where it disagrees with [authority_pack_v1/](authority_pack_v1/README.md), the pack wins. The disagreement is recorded in [AUTHORITY_RECONCILIATION.md](AUTHORITY_RECONCILIATION.md). This file is not runtime evidence and it is not art approval.
>
> `HUMAN_ART_APPROVAL=false`. `MERGE_AUTHORIZED=false`.


Status: **DOCTRINE**. No model described here exists as an approved game asset. The V1.6 bodies are procedural boxes. They fail this bible.

`HUMAN_ART_APPROVAL=false`

“Chibi” in this bible means a **handheld-readable stylized human**, translated from the V4.5 boards:

- Head about 1/4.5 to 1/5.5 of total height. Bigger than a realistic human, smaller than a toy mascot.
- Hands and feet enlarged enough to read a jab at match camera.
- Legs long enough to sell a dash and a jump arc.
- Face, hair, and element are modeled. They are not decals on a cube.

Low poly is allowed. **Low poly does not mean a box proxy.** A 4–8k triangle body with a real face beats a 200-triangle stack of cubes. If a silhouette can be described as “rectangles,” it is not in this bible.

## 1. Global proportions

| Measure | Target | Fail |
|---|---|---|
| Height in the match camera | Body fills roughly 18–28% of frame height at neutral zoom | Speck on Training Grid |
| Head / height | 1 : 4.5 to 1 : 5.5 | Toy head, or mannequin pinhead |
| Shoulder width | Identity-specific (Rook widest, Juno and Kaia narrowest) | One shared torso |
| Hand size | Readable fist at the match camera | Sticks |
| Neck | Short, never a floating head | Head glued to a box |
| Feet | Planted, identity boots or elemental feet | Missing |

Male and female share the skeleton and the gameplay capsule. They do not share the mesh. Shoulder, hip, hair, and costume volume are modeled differences. A material tint is not a sex variant.

## 2. Topology

- One body mesh plus hair/cloth cards plus element accents that are allowed to be separate meshes (ribbons, rings, crystal plates, vents).
- Face loops: eyes, mouth, brow. Closed eyelids for hurt and blink. No faceless abstract head on the corrected roster. Older wave notes that banned faces are superseded by the V4.5 boards for this correction.
- Element accents are modeled geometry or layered cards, not a single emissive sphere.
- UVs support a small palette atlas: skin-element, cloth, metal, emissive trim.
- LOD0 is the gameplay mesh. LOD1 may drop hair cards. There is no LOD that becomes a cube.

## 3. Materials and shading

- Stylized toon / cel. Two or three light bands. Hard shadow terminator.
- Rim light in the element color so the body separates from the stage.
- Emissive only on the element (flame core, current, crystal edge, ring, void aperture, gold line). The whole body does not glow.
- Palette is per fighter and per form. Do not drive identity by hue-shifting one material.
- Puppet masks are a second head material or a mask mesh, used only on Black Puppet and White Puppet.

## 4. Rig

Shared rig for all nine, both sexes, and story forms:

- Root, pelvis, spine x2, chest, neck, head
- Clavicle, upper arm, forearm, hand per side
- Thigh, shin, foot, toe per side
- Hair/cloth bones or physics: Ember crest, Kaia ribbons, Vesper veil, Yin inward cloth, Yang crest
- Prop bones: Nix plates, Orion ring, Rook pauldron, Ember vents

Story forms reuse the rig. They swap meshes and constraints. They do not add gameplay bones.

Deformation: elbows and knees keep volume. Ribbons trail the chest, they do not clip through the face on idle. A T-pose export is not a finished idle.

## 5. Animation requirements

Every base presentation needs the move-sheet states, not a single sway:

Idle, dash, run, jump, light, heavy, aerial, special, super, hurt, tumble, launch, victory.

Grammar, from the movement bible: anticipation, contact, follow-through, recovery. Contact is a held pose. Yin’s follow-through may be a held stillness. Yang’s follow-through is an expansion that returns before the next input.

Same clip set for male and female. The mesh difference carries the sex. Do not author a second moveset.

Representative procedural poses are not this list. On `d94bc095`, 285 of 392 traced clips are still procedural JSON. Those rows stay `PROCEDURAL_JSON_NOT_VISUALLY_COMPLETE` until an authored clip exists.

## 6. Camera and presentation

| Context | Rule |
|---|---|
| Select | Large turntable. Full body. Both sexes switch the mesh, not only the button. |
| Showcase | One signature pose from the move sheet, then idle. |
| Versus | Both bodies, names, elements. No telemetry chrome. |
| Match | Bodies in the readability band above. Stage does not shrink them to icons. |
| Results | Winner’s form, not a mannequin. |
| Story | Same mesh family, plus essence or puppet form when the chapter says so. |

The “ART SOURCE / owner approved” overlay is dev chrome. It stays off unless a developer flag is set.

## 7. VFX

VFX supports the body. It does not hide it.

- Ember: short flame on the striking limb, pillar only on super.
- Rook: dust at the plant foot.
- Juno: a thin rail, not a yellow fog.
- Kaia: ribbon-following wind, stronger per essence step.
- Nix: crystal grows from a posed hand.
- Orion: one ring readable, extra rings on super.
- Vesper: afterimage of the leaving pose.
- Yin: inward dark, a held aperture.
- Yang: outward gold lines.

Party and 8-player views drop extra ribbons and extra rings before they drop the body.

## 8. Variants to model

Per spectrum fighter (Ember, Rook, Juno, Kaia, Nix, Orion, Vesper):

1. Base male
2. Base female
3. Black Puppet (story)
4. White Puppet (story)

Kaia also:

5. Essence 1
6. Essence 2
7. Essence 4
8. Essence 6 Prismatic Gray

Yin and Yang:

1. Base male
2. Base female
3. Their own deeper story forms (campaign bible), not a puppet of themselves

Count for a complete visual roster: 7×4 + 4 Kaia steps + 2×2 bases = 36 meshes, plus two Yin/Yang story deep forms when those chapters are boarded. None of these 36 are approved today.

## 9. Per-character modeling sheet

| Fighter | Must model | Must not model |
|---|---|---|
| Ember | Flame crest, vents, gauntlets, lit face | Hat, wooden toy, floating fireball with no body |
| Rook | Mass, strata, helm with a face, heavy plant | Cube torso, tiny head on a rectangle |
| Juno | Rails, nodes, slender limbs, braid or crest | Yellow mascot, bolt stickers on a sphere |
| Kaia | Ribbons, airfoil costume, calm face, essence steps | Green blocks, missing hair |
| Nix | Faceted plates, visible face, brace pose | Blue blob |
| Orion | Human body, one gameplay ring, gold nodes | Orb instead of a person |
| Vesper | Asymmetric cloth, human face, split tail | Base-form skull |
| Yin | Inward cloth, quiet face, small void accent | Gray boxes, purple orb, mannequin |
| Yang | Outward crest, gold lines, readable face in light | White mannequin, yellow boxes |

## 10. Acceptance checklist

A presentation may be called a candidate only when all of these are true. It may be called final art only after a human sets approval. This document does not do that.

- [ ] Silhouette names the fighter with the color removed
- [ ] Face is a modeled elemental human
- [ ] Male and female are different meshes on the same rig
- [ ] Match camera keeps the body in the readability band
- [ ] Idle, dash, light, heavy, special, super, hurt, and victory are authored poses or clips
- [ ] Element VFX does not cover the contact limb
- [ ] Black/White puppet and Kaia Gray are separate meshes or clearly separate materials, story-only
- [ ] No dev art-source overlay in the player build
- [ ] Side-by-side with the V4.5 board, a person who did not build it recognizes the fighter

Current block candidates fail the first three items. They are not candidates for ship. They are evidence that routing works and the art does not.

`HUMAN_ART_APPROVAL=false`
