# Elemental grab and throw source direction — 8A

Status: `SOURCE_CANDIDATE`. Owner approved: **false**. Dedicated hold and victim reaction acting: **pending** for all nine identities. This document and `game-godot/data/combat/elemental_grab_throw.json` specify production direction; they do not establish final animation, material, audio, performance, native-device or human-feel acceptance.

The source authorities are the nine production bibles indexed by `data/bibles/FIGHTER_BIBLE_INDEX.json`, especially each bible's Identity, State-by-state motion language, Attack-pose law, Male / female presentation contract, Rig/deformation contract and Final production gates. Existing visual families are in `game-godot/scripts/visual/elemental_vfx_family.gd` and `game-godot/shaders/spectral_feedback.gdshader`. Source direction preserves their body → contact → defender → primary effect → trail → particles read order.

## Phase ownership and timing

The inspected gameplay baseline releases a held target when `fighter.gd::execute_throw()` runs: it clears the grab relationship, resolves the throw, starts its move and applies the hit without waiting for an animation release marker. `tools/v1_closure/build_combat_choreography.py::make_clip()` therefore defines throw contact at frame zero and explicitly places preparation in grab hold. Preserve that event authority. Author anticipation during `grab_hold`; start the directional release pose at the existing release event and fit follow-through/return to existing move authority. Do not delay damage, change frame data, retune launch, introduce root motion or move collision to accommodate late acting.

- **Acquire:** begin the elemental catch only after a successful grab. The grip and victim must read with VFX disabled. Startup and whiff gestures must remain distinguishable from confirmed acquisition.
- **Hold:** the attacker owns a restrained persistent family contour and a deliberate supported pose; the victim needs distinct held acting. The phase must survive its real duration without becoming an idle attack loop. Preparation must not promise a chosen throw direction before the player has chosen one.
- **Release:** one transition per confirmed throw, using the actual direction and facing. Break the restraint before showing travel. The four directions require different poses, silhouettes and follow-through, with the same gameplay release authority.
- **Travel:** accompany the released victim's real velocity and trajectory. Element identity belongs to the throw owner; victim body identity and directional reaction stay legible. Decoration must not steer or delay the victim.
- **Landing:** the actual supported victim contact owns the landing response. A release above a platform does not prove a later landing. Preserve stage queries, contact deduplication and existing reaction authority; do not manufacture a surface beneath an airborne victim.
- **Escape / interruption:** retire held visuals and any owned audio on mash escape, invalid target, hurt interruption, KO, actor removal and scene teardown. Escaping is not a successful release or landing.

The pre-8A recovery accent used shader kind `6`, which replaces family shape with a common crescent. Its direct caller chose up or right only. The source direction requires each family's own geometry and actual directional context; the contract file does not itself prove that runtime integration.

## Nine distinct shape, motion and audio grammars

| Fighter / spectral family | Grab and hold | Release and travel | Actual landing | Audio direction |
|---|---|---|---|---|
| Ember Vale / `turbulent_combustion` | Forward wedge clinch, furnace-jaw gauntlets, rear-heel load and restrained vent pressure. | One ignition wedge; torn tongues and granular embers oppose actual travel. | Low scalloped heat crown cools into fragments. | Ignition thump, fuel crackle, pressured exhaust, cooling hiss. |
| Rook Ironside / `compression_fractures` | Broad low block brackets, locked plates, hip support and carried mass. | Compression opens into strata/fracture planes; sparse stone chips lag behind the body. | Low seismic fractures and separate chips settle. | Stone lock, armor compression, dense low impact, debris rattle. |
| Juno Spark / `branching_voltage` | Compact forked rails, routing nodes, open grip center and poised redirection. | Polarity snap; broken rails and a brief arc ghost stretch and terminate. | Seeded floor branches travel outward and end cleanly. | Tight chirp, clipped snap, short current tail. No long thunder wash. |
| Kaia Windrow / `open_pressure_crescents` | Open crescents cradle a curved physical clinch with counterbalancing hand/ribbon. | Spiral unspools; open slipstream banks around the honest trajectory. | Pressure escapes sideways through an open spiral and leaf/ribbon curl. | Inhaled pressure, control-surface flutter, exhale and soft sweep. |
| Nix Calder / `faceted_crystal_lances` | Cryolattice clamp assembles in chosen facets; measured lock and brace. | Crystal latch fractures once; ordered frost facets follow with clear gaps. | Structured frost branches organize and dissolve. | Crystal ticks, ice compression, brittle release and frost hiss. |
| Orion Vell / `collapsing_orbit_nodes` | Elliptical nodes contract around an implied center of mass and composed hands. | Orbit tightens and releases; stretched ellipses and satellites align with real knockback. | Elliptical gravity field compresses inward and nodes settle. | Orbital hum, gravitational pitch bend, pressure release and settled resonance. |
| Vesper Nyx / `dislocated_phase_seams` | Offset seam pairs surround an honest grip; secondary hand echoes arrive out of phase. | Seam splits; separated echoes stretch beside and collapse onto the real body. | Offset seams close onto the real contact point. | Reversed transient, phase flutter, one short spatial echo. |
| Yin / `subtractive_aperture` | Aperture draws inward around economical stillness; white seed and negative space remain readable. | Aperture closes; short inward strokes disappear behind the real trajectory. | Pale enclosing rim contracts and strokes shorten inward. | Texture subtraction and sub-bass pressure; muted release and shortened tail. |
| Yang / `constructed_hex_radiance` | Symmetric hard-light braces construct around declarative hands; black seed remains visible. | Ordered rays and separated geometric segments define the real trajectory. | Exact hard-light hexagon constructs outward. | Clear harmonic assembly, firm construction transient and ordered decay. |

These contracts differ in contour, negative space, build/break direction, body support, timing and audio envelope. Nix is crystal/frost, Orion is gravity, Vesper is phase, Yin is void/subtraction and Yang is radiance/construction. A shared disc or crescent with nine colors does not satisfy this direction.

## Reused audio provenance and limits

The JSON selects existing source events only:

| Phase | Reused event | Existing path for each canonical fighter ID |
|---|---|---|
| Acquire | `block` | `game-godot/assets/audio/elemental_v1/<id>/block.wav` |
| Release | `charge_release` | `game-godot/assets/audio/elemental_v1/<id>/charge_release.wav` |
| Landing | `projectile_impact` | `game-godot/assets/audio/elemental_v1/<id>/projectile_impact.wav` |
| Escape | `charge_cancel` | `game-godot/assets/audio/elemental_v1/<id>/charge_cancel.wav` |

All 36 selected WAV files were verified present while authoring this source candidate. They are **reused original elemental source audio**, not dedicated authored grab/throw phase production audio and not a human-approved mix. `tools/audio/generate_elemental_performance.py` defines all nine synthesis families; its body/texture/transient source stems are under `art_source/audio/elemental_v1/<id>/<event>/`. `artifacts/v1_closure/dialogue_performance/elemental_sound_catalog.json` records the original synthesis provenance and unapproved mix status.

No sustained hold/travel audio is specified by this JSON. Dedicated loops, transitions, short phase cues, loudness/overlap decisions and human listening review remain production work. Yin's bible requests ambience removal; the reused one-shots do not establish a scoped ambience-ducking implementation or acceptance. Existing V3 per-move grab/throw audio rows cover the seven spectrum fighters, so they do not establish all-nine phase coverage.

## Exact preserved source and model dependencies

There are nine identities and two body presentations: **18 existing source rigs**, each with its actual skin/rest transforms. These paths were verified present. The table names each original `.blend` and existing `BASE.glb`; it does not authorize rebuilding or replacing either asset.

| Identity / body | Preserved Blender source | Existing runtime model |
|---|---|---|
| Ember / male | `art_source/collectible_v1/ember-vale/male/candidate.blend` | `game-godot/assets/characters/collectible_v1/ember-vale/male/BASE.glb` |
| Ember / female | `art_source/collectible_v1/ember-vale/female/candidate.blend` | `game-godot/assets/characters/collectible_v1/ember-vale/female/BASE.glb` |
| Rook / male | `art_source/collectible_v1/rook-ironside/male/candidate.blend` | `game-godot/assets/characters/collectible_v1/rook-ironside/male/BASE.glb` |
| Rook / female | `art_source/collectible_v1/rook-ironside/female/candidate.blend` | `game-godot/assets/characters/collectible_v1/rook-ironside/female/BASE.glb` |
| Juno / male | `art_source/collectible_v1/juno-spark/male/candidate.blend` | `game-godot/assets/characters/collectible_v1/juno-spark/male/BASE.glb` |
| Juno / female | `art_source/collectible_v1/juno-spark/female/candidate.blend` | `game-godot/assets/characters/collectible_v1/juno-spark/female/BASE.glb` |
| Kaia / male | `art_source/collectible_v1/kaia-windrow/male/candidate.blend` | `game-godot/assets/characters/collectible_v1/kaia-windrow/male/BASE.glb` |
| Kaia / female | `art_source/collectible_v1/kaia-windrow/female/candidate.blend` | `game-godot/assets/characters/collectible_v1/kaia-windrow/female/BASE.glb` |
| Nix / male | `art_source/collectible_v1/nix-calder/male/candidate.blend` | `game-godot/assets/characters/collectible_v1/nix-calder/male/BASE.glb` |
| Nix / female | `art_source/collectible_v1/nix-calder/female/candidate.blend` | `game-godot/assets/characters/collectible_v1/nix-calder/female/BASE.glb` |
| Orion / male | `art_source/collectible_v1/orion-vell/male/candidate.blend` | `game-godot/assets/characters/collectible_v1/orion-vell/male/BASE.glb` |
| Orion / female | `art_source/collectible_v1/orion-vell/female/candidate.blend` | `game-godot/assets/characters/collectible_v1/orion-vell/female/BASE.glb` |
| Vesper / male | `art_source/collectible_v1/vesper-nyx/male/candidate.blend` | `game-godot/assets/characters/collectible_v1/vesper-nyx/male/BASE.glb` |
| Vesper / female | `art_source/collectible_v1/vesper-nyx/female/candidate.blend` | `game-godot/assets/characters/collectible_v1/vesper-nyx/female/BASE.glb` |
| Yin / male | `art_source/collectible_v1/yin/male/candidate.blend` | `game-godot/assets/characters/collectible_v1/yin/male/BASE.glb` |
| Yin / female | `art_source/collectible_v1/yin/female/candidate.blend` | `game-godot/assets/characters/collectible_v1/yin/female/BASE.glb` |
| Yang / male | `art_source/collectible_v1/yang/male/candidate.blend` | `game-godot/assets/characters/collectible_v1/yang/male/BASE.glb` |
| Yang / female | `art_source/collectible_v1/yang/female/candidate.blend` | `game-godot/assets/characters/collectible_v1/yang/female/BASE.glb` |

For every exact `<id>_<body>` pairing above, existing rig-specific runtime keys are in `game-godot/data/animation/combat_choreography/<id>_<body>.json` and `game-godot/data/animation/combat_performance/<id>_<body>.json`. All 36 JSON dependencies were verified present. The controller loads performance amendments over choreography and resolves the same action IDs for both presentations. This is one identity/action contract evaluated on the actual rig, not a new male/female moveset or duplicated creative library.

The seven spectrum identities additionally have `BLACK_PUPPET.glb`, `WHITE_PUPPET.glb` and `PRISMATIC_GRAY.glb` beside each `BASE.glb`; Yin and Yang have `COSMIC_BOSS.glb`. Their material/form continuity needs review when the same acting is reused. Masks belong to puppet story variants, not the base spectrum roster.

## Existing WIP versus required source acting

All 18 choreography documents contain `grab`, `throw_forward`, `throw_back`, `throw_up`, `throw_down` and their `_left` counterparts. That blocking coverage does not prove dedicated hold or victim acting. There is no dedicated `grab_hold` in those choreography documents; runtime has procedural fallback clips for that state.

Only **four rigs** currently have the inspected directed Blender-source grab/throw amendments: Kaia male/female and Juno male/female. Their source scores and receipts are under:

- `art_source/animation/fighters/kaia-windrow/directed_performance/score_v1.json`
- `art_source/animation/fighters/juno-spark/directed_performance/score_v1.json`
- The corresponding `male_source_actions.json`, `female_source_actions.json`, `male_runtime_export.json` and `female_runtime_export.json` in those same directories.

Those source/runtime correspondence receipts explicitly measure saved Blender evaluated poses against rig-specific keys, not visual quality. The score status is authored WIP and human approval is false. The all-nine JSON source direction does not promote the remaining 14 rigs to this four-rig WIP coverage, and none of the four establishes completed dedicated hold/reaction acting.

Required authored work on the actual 18 rigs:

1. Deliberate attacker acquire, supported `grab_hold`, direction-neutral preparation, whiff, break/escape and interrupted return. Author hands, wrists, elbows, shoulders, head/eyes, hips and support feet; the grasp must read without a particle enclosure.
2. Distinct forward/back/up/down release and follow-through in both facings. Preserve frame-zero release and existing gameplay timing; fix late acting at source.
3. Victim acquisition, held restraint/mash, escape, direction-specific released reaction, readable airborne travel/tumble, supported landing and interrupted/KO exits. Existing simulation decides whether landing, bounce or another reaction occurs.
4. Separate source treatment for each fighter's power structures and secondary forms: Ember vents, Rook plates, Juno nodes/rails, Kaia ribbons/control surfaces, Nix facets, Orion orbit nodes, Vesper offsets, Yin aperture/white seed and Yang constructs/black seed.

`tools/authored_animation/blender/aa_support_controls.py` provides non-deforming source objects for measured sole/ball/heel pivots, knee poles and pelvis support on the preserved 22-bone rigs. `artifacts/v1_closure/parity_foundation/rig_controls_in_memory.json` records all 18 exercised in memory, source install/save deferred, owner approval false. Rigid accessory-offset objects preserve existing Head weights; independent deforming hair/cloth controls, weighting and export are still required. Installing a source control is not completed secondary animation.

Preserve source geometry, rest bones, weights, anatomical bone lengths, original actions and NLA strips. `tools/authored_animation/blender/aa_directed_performance.py::export_runtime()` is the established saved-action evaluation → rig-specific JSON boundary, without a model/GLB export. Acting on existing bones can follow that path. New articulated accessory weights/bones, material changes or object animation outside that boundary require separately reviewed source and GLB export work; the contract file does not complete it.

## Production and acceptance gates still required

- **Source / rig:** saved source actions on all 18 actual rigs, support-foot and hand-contact review, preserved original-action/mesh/rest/weight evidence, source-to-runtime correspondence, both facings and all four throws. Dedicated hold and victim reactions remain pending until authored and inspected.
- **Material / form:** elemental material completion and human facial structure; readable silhouette and contact under the actual stage lighting; consistent bases, puppet/prismatic forms and cosmic forms. Nix facets must read as frost/crystal, Orion as gravity, Vesper as phase, and Yin/Yang must retain their opposing seeds. Source direction is not material approval.
- **VFX / audio:** confirmed event ownership, interruption cleanup, real direction/facing, actual landing, bounded effects, no phantom impact on whiff, no unreadable nine-recolor treatment, dedicated phase mix/listening review and overlap checks. Reused source audio remains explicitly labeled.
- **Readability / human feel:** bible silhouette, three-pose anticipation/contact/recovery, VFX-off, grayscale, duplicate-fighter, quarter-scale and freeze-frame contact checks. Inspect attacker and victim together, all 18 presentations, both facings and four throw directions. PartyLink readability must survive overlapping players and effects.
- **Performance / native:** run the affected gameplay scenarios in the actual native runtime, measure effect/audio lifetime and pool/overlap behavior under the established intensity and accessibility settings, and collect the required target-device evidence. Existing source/JSON checks do not establish native timing, frame pacing, physical-Pixel acceptance or perceived impact.
- **Approval:** retain the bibles' separate G0–G9 boundaries. Structural data or source parity does not imply G5 VFX/SFX, G6 visual readability, G7 physical Pixel, G8 human feel or G9 final art. Owner/human approvals remain false until those reviews occur.

This source-authoring increment did not run Godot or Blender, render or export models, change gameplay values, or establish any native/device or final-art pass.
