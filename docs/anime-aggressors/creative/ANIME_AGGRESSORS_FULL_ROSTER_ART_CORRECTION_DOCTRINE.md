# Anime Aggressors — Full Roster Art Correction Doctrine

> **Superseded on conflict by Creative Authority Pack V1.** This file is the prior doctrine pass at `e15a343`. Where it disagrees with [authority_pack_v1/](authority_pack_v1/README.md), the pack wins. The disagreement is recorded in [AUTHORITY_RECONCILIATION.md](AUTHORITY_RECONCILIATION.md). This file is not runtime evidence and it is not art approval.
>
> `HUMAN_ART_APPROVAL=false`. `MERGE_AUTHORIZED=false`.


Status: **DOCTRINE**. This file tells artists and implementers what the roster is supposed to be. It is not a screenshot of the current build, and it is not owner art approval.

`HUMAN_ART_APPROVAL=false`

Observed runtime this doctrine corrects (Pixel, exact-head `d94bc095`, watermark `AA d94bc0950779`):

- Kaia, Yin, and Yang large select previews are **block candidates** (`ART_DIRECTION_CANDIDATE_V1_6`). They are not the V4.5 boards.
- Male/Female mostly changes the button. The silhouette change is slight.
- The other roster cards are still old chibi hats, a purple skull, and a white mannequin.
- A match shows tiny figures on Training Grid.
- Those presentations are **not** the visual endpoint. Retire them from player-facing once a board-faithful mesh exists. Until then they may remain only as an explicit dev fallback, never as `FINAL_ART`.

## 1. What “the look” is

Anime Aggressors is a premium, readable, **stylized 3D fighter** for handheld screens, faithful to the V4.5 boards:

- 3D cartoon style study V4.5
- arcade animation study
- spectrum + Yin/Yang character design sheets
- fight move sheet

House rule when words conflict: **the boards win**.

The product may be called a stylized chibi fighter only in this sense: heads, hands, and hair read large at phone distance; limbs stay long enough to sell anticipation and contact; the body is still an elemental human, not a toy. It is not the current KayKit hat silhouette, not a super-deformed cube, not a mannequin, and not a stack of boxes.

Shared art law, from the in-repo production bibles and the V4.5 sheets:

- Same soul, same moves, same hitboxes. Male and female are different authored forms.
- Base roster faces are elemental humans. Masks belong to Black Puppet and White Puppet story forms only.
- Color is identity. Do not recolor one mesh across the roster.
- Element lives in the body and costume, not as a floating orb that replaces the person.
- Combat camera must still show intent, contact, and recovery. Beauty that hides the hit is a fail.

Quality bar used below:

| Band | Meaning |
|---|---|
| Unacceptable | Current player-facing result. Must not ship as the look. |
| Prototype | Routing or a color cue exists. Shape is still a proxy. |
| Near-ship | Board-faithful modeled form, both sexes, readable at match camera. Not claimed for anyone today. |

## 2. Roster order

Nine gameplay identities. Eighteen base presentations. Story adds Black Puppet, White Puppet, and Kaia’s essence ladder through Prismatic Gray. Puppets and Gray are story forms, not extra fighters and not balance changes.

| ID | Board name | Element | Archetype | Runtime distance from the boards |
|---|---|---|---|---|
| ember-vale | The Living Flame | Combustion / red | Rushdown | Farthest class: hat chibi card |
| rook-ironside | The Walking Bastion | Mass / orange | Grappler | Farthest class: toy block card |
| juno-spark | The Arc Courier | Lightning / yellow | Speed | Farthest class: small toy card |
| kaia-windrow | The Skyflow Duelist | Wind / teal | Aerial / flow | Prototype only: green blocks, not ribbons or a face |
| nix-calder | The Crystal Tactician | Ice / cyan | Zoner | Farthest class: generic crystal toy |
| orion-vell | The Orbital Marshal | Gravity / violet | Setup | Farthest class: orb toy |
| vesper-nyx | The Phase Weaver | Phase / magenta | Trickster | Farthest class: purple skull |
| yin | The Inward Collapse | Reduction / black | Null | Prototype only: gray blocks, not inward human |
| yang | The Outward Expansion | Definition / white-gold | Radiance | Prototype only: white-gold blocks; match still a speck |

No current model is near-ship. Kaia, Yin, and Yang are the only ones that even changed the large preview off the old hat/skull. They are still the wrong art. Retire the hat, the skull, the mannequin, and the V1.6 boxes together.

## 3. Per fighter

### Ember Vale — combustion

- Identity: pressure becomes forward fire. Rushdown. Verbs: ignite, lunge, drive, burst.
- Visual: flame anatomy in hair, vents, and gauntlets. Red, orange, black. Aggressive forward silhouette. Human face lit from inside the fire, not a hat on a wooden doll.
- Chibi translation: big readable gauntlets and a flame crest. Torso stays narrow enough that the forward lean reads. Do not shorten the legs into stubs; the dash has to travel.
- Male / female: same furnace core. Male reads broader vents and a heavier plant. Female reads a sharper crest and a longer flame trail. Neither is “the real Ember.”
- Combat: light is a short brand, heavy is a full-body lunge, super is a pillar. Contact hand or foot must be outside the torso silhouette.
- Select: live turn, name, Rushdown, one flame accent. No art-source telemetry.
- Quality now: unacceptable on the card. No V1.6 body.
- Story: Black Puppet banks the fire inward until one coal remains. White Puppet forces the flame into a perfect repeating torch. Ember does not become Gray; Kaia does.

### Rook Ironside — mass

- Identity: a fortress that walks. Grappler. Verbs: brace, plant, crush.
- Visual: massive grounded silhouette, rock and plate, orange, brown, charcoal. Weight is in the stance, not a cube torso.
- Chibi translation: widest shoulders on the roster, short neck, heavy boots. Head is smaller in proportion than Juno’s, still a designed face under a helm, not a block.
- Male / female: male is the broader bastion. Female keeps the mass in the hips and pauldrons with a different helm crest. Same command grabs.
- Combat: heavies occupy more screen than lights. Super is a collapsing wall, body still readable inside the dust.
- Quality now: unacceptable toy card.
- Story: Black Puppet cracks the stone and pulls the cracks inward. White Puppet seals every crack into a flawless white bastion.

### Juno Spark — current

- Identity: a living accelerator. Speed. Verbs: snap, route, chain.
- Visual: slender, yellow, gold, white electric lines. Motion-ready, not a yellow mascot.
- Chibi translation: longest limb-to-torso ratio after Kaia. Small nodes at joints, not a round toy head with bolt stickers.
- Male / female: male has sharper rail shoulders. Female has a longer conductor braid. Same dash data.
- Combat: lights are snaps, heavies are launched rails. Silhouette must change on dash startup or the speed fantasy fails.
- Quality now: unacceptable toy card.
- Story: Black Puppet shorts the current into a dark loop. White Puppet locks the arcs into a perfect circuit.

### Kaia Windrow — flow

Priority fighter. The boards give her the clearest human, ribbons, and essence ladder.

- Identity: aerial mediator. Wind. Verbs: flow, curve, spiral, glide.
- Visual: teal, green, white. Aerodynamic body, ribbon hair, wind cloth that follows the pose. Face is designed and calm. She is not a green rectangle with stick arms.
- Chibi translation: keep the ribbon length. Compress the torso slightly so the ribbons still clear the HUD. Hands and the leading foot must read at match size.
- Male / female: same soul. Male: shorter wind crest, broader airfoil shoulders. Female: long ribbon hair and a narrower waist, as on the design sheet. Current Pixel build does not show this. The female button can highlight while the figure stays a green block. That is a fail.
- Combat: arcs, not jabs copied from a generic skeleton. Super is a horizon tempest with the body inside the spiral.
- Select: large live preview, both forms, ribbons moving on idle. Card art must be the same person as the preview.
- Quality now: prototype color only. Unacceptable as the look. Retire the block body.
- Story forms, in order, from the boards:
  1. Base — sky seed, teal human.
  2. Essence 1 — sacrificial power, longer ribbons.
  3. Essence 2 — imbalance, dual-color wind traces.
  4. Essence 4 — sky and earth, elements begin to agree.
  5. Essence 6 — Prismatic Gray. All colors, one flow. Not a gray mannequin.
- Black Puppet: circulation dragged inward, one green current left, mask on.
- White Puppet: wind forced into perfect repeated spirals, white mask.

### Nix Calder — ice

- Identity: builds structure. Control. Verbs: measure, place, lock.
- Visual: crystal armor, cyan, blue, white, sharp silhouette. Face visible between plates.
- Chibi translation: facets on shoulders and shins, not a blue blob. The lattice should change the outline when she braces.
- Male / female: male reads taller crystal walls. Female reads a sharper hood and narrower lattice skirt. Same traps.
- Combat: specials place structure. The body pose points at the construct.
- Quality now: unacceptable toy card.
- Story: Black Puppet frosts the lattice inward until it cages her. White Puppet grows a perfect crystal monument she must stand inside.

### Orion Vell — orbit

- Identity: mass, vectors, consequence. Verbs: orbit, pull, suspend, release.
- Visual: violet, navy, gold rings. Martial stance. Rings orbit the body; they do not replace the body.
- Chibi translation: one readable ring at gameplay size, plus a second only on specials and super. Head and hands stay human.
- Male / female: male carries heavier orbital nodes on the shoulders. Female carries a longer ring ellipse at the hips. Same gravity data.
- Combat: heavies are wide geometric arcs. Super suspends, then releases.
- Quality now: unacceptable orb-toy card.
- Story: Black Puppet collapses the orbits into a tight dark well. White Puppet freezes them into a perfect clock.

### Vesper Nyx — phase

Priority fighter. The current skull is the clearest wrong turn.

- Identity: the opponent trusts the wrong moment. Trickster. Verbs: misdirect, vanish, slip.
- Visual: magenta, purple, black, asymmetric phase cloth, a human face that can half-leave the light. Not a cartoon skull. The skull may survive only as a story-mask echo, never as the base head.
- Chibi translation: offset shoulders and a split tail. One side of the silhouette is “late.” That is the read.
- Male / female: male is the sharper assassin cut. Female is the longer phase veil. Same mix-ups.
- Combat: a phase step must show a body leaving and a body arriving. A fade with no pose is not Vesper.
- Quality now: unacceptable. The purple skull on the card is retired as base art.
- Story: Black Puppet finishes the vanish and leaves a mask. White Puppet forces both phases to occupy one perfect outline, which she hates.

### Yin — reduction

Priority fighter. Not “the purple orb,” and not a gray box.

- Identity: peace by subtracting difference. Verbs: absorb, fold, collapse, still.
- Visual: black, graphite, inward curves, a small absence at the chest, controlled minimal light. Human face, quiet. The inward shape is the costume and the pose, not a hole where the person should be.
- Chibi translation: compact preparation, then a reach that pulls inward. Head slightly smaller than Yang’s radiance, still designed.
- Male / female: male folds into a narrower column. Female’s hair and cloth spiral inward. Same null tools. Pixel evidence: both read as the same gray block.
- Combat: lights compress, heavies erase space, super is a collapse with a held negative-space pose. Follow-through is the absence of motion, held on purpose, not a snap to idle.
- Select and results: the winner portrait is this form, not a mannequin. The old “Yin Wins!” mannequin is retired.
- Quality now: prototype color only. Unacceptable as the look.
- Story role: the principle that rewrites fighters into Black Puppets. Yin’s own story form is deeper quiet, not a second costume of the base roster. See the campaign bible.

### Yang — definition

Priority fighter. Not a white mannequin and not a yellow box.

- Identity: peace by imposing order. Verbs: emit, expand, declare, construct.
- Visual: white, gold, outward rings, luminous edges, a human face that stays readable inside the light.
- Chibi translation: compact windup, then a radial extension that clears the body. One ring reads at match size.
- Male / female: male is the broader constructed frame. Female is the longer radiant crest. Same expansion tools. Pixel evidence does not show two forms.
- Combat: lights draw lines, heavies throw geometry, super builds a boundary and the body stands at its center.
- Quality now: prototype color only. Match scale still shows a speck. Unacceptable as the look.
- Story role: the principle that rewrites fighters into White Puppets.

## 4. Story forms that are not extra fighters

### Black Puppet — Yin control

Used on spectrum fighters in story mode only. Masked. Palette collapses toward black and graphite. One elemental accent survives. Motion is pulled inward. Not part of the versus base roster. Not a gameplay buff.

### White Puppet — Yang control

Masked. Palette collapses toward white and gold. Motion is forced into perfect repetition. Same rules: story only, no balance change.

### Kaia essence ladder

Base, Essence 1, Essence 2, Essence 4, Essence 6 / Prismatic Gray. Each step must change ribbons, color load, and silhouette. A data flag with the same mesh is not a transformation. Gray is every spectrum color held in one flow.

## 5. What to retire

Player-facing, as soon as a replacement exists:

- KayKit / hat chibis (Ember and the same family of cards)
- Purple skull base Vesper
- White mannequin Yang, including the results mannequin
- V1.6 box bodies for Kaia, Yin, and Yang
- Tiny unreadable match sprites as the normal camera

Keep the move data, hitboxes, Yin/Yang roster slots, and the male/female routing. Replace the meshes those systems display.

## 6. Acceptance for this doctrine

A form is not “corrected” until a human can put the V4.5 board beside the select preview and the match camera and recognize the same person, the same element, and the chosen sex. Automation may check paths and bone counts. It may not set art approval.

`HUMAN_ART_APPROVAL=false`
