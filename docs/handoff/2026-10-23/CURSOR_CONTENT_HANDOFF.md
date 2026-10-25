# Anime content handoff — source candidates, no shipping authorization

PR #123 remains draft on #122. Codex owns the original character/cinematic source lane; Cursor may integrate reviewed content on an isolated engineering branch. No live Cursor message, branch merge, model installation, web deployment or new art-job dispatch is implied by this document.

## Exact content available

The last produced eighteen-body model candidate is the **8D-3 hand-interface build**, producer `42baaab8cc5167798aea7f3aebb22edae9f21007`, successful run `39910149332`. Its exact per-body source/export hashes, preservation and native scope are in `artifacts/v1_closure/production_8d/hand_integration_8d3/SOURCE_NATIVE_MATRIX.json`. All nine fighters have male/female records and both-facing native import fixtures. These are WIP originals, not final character art. No new 8D-4 scene, paired-body GLB or shipping asset build exists.

Existing optional runtime contract:

- Resource: `res://assets/characters/hands_8d3/{fighter}/{body}/BASE.glb`.
- Companion: `res://data/animation/hands_8d3/{fighter}_{body}.json`, schema `saved_original_hands_8d3.v1`.
- `source_controls_8d.gd::candidate_document` checks fighter/body, exact GLB SHA-256, prior input provenance, `human_approved=false` and `paired_3d_verified=false`.
- `fighter_model_3d.gd::_try_load_collectible` selects this lane only through the explicit `source_hands_8d3` review metadata. Do not silently replace the default lane.
- The saved `D8_` digit/accessory layer is sampled by the existing control helper. Original canonical body tracks, 60 Hz move ownership, roots, proportions, damage and Story authority stay unchanged. The digit release is not a newly authored full-body paired throw.
- `play_party_review.py` currently exposes the older 8D/8D-2 options, not a general 8D-3 owner-play option. Existing 8D-3 source fixtures select the newer metadata directly. Do not advertise an unsupported launcher flag.

Cursor must verify raw GLB loading, imported clips/materials/bones, both bodies/facings and target renderer behavior on the eventual exact package. Historical Linux staged imports do not certify browser delivery, real-device performance, normal-speed art quality or paired mesh contact.

## New private cinematic source and public reader

Seven individually authored native camera Animation resources now cover the seven canonical First Loss scenes (114 cue bindings). These source files, detailed inventory and validation results stay outside this public checkout. They change camera direction only; no new fighter-body acting, light rig, score, voice recording or rendered film is implied.

The non-sensitive reader is `game-godot/scripts/story/ova_private_camera_take.gd`; watch integration is in `ova_watch_scene.gd`. This reader:

- is opt-in through `--private-cinematic-camera=ABSOLUTE_EXTERNAL_MANIFEST` on native developer review only; the web branch does not load it;
- accepts schema `anime.private_camera_library.v1`, candidate-only/private-disclosure policy, exact canonical cue hash and per-node cue order;
- loads SHA-bound, self-contained native Animation value tracks for `Camera:focus_mix`, `Camera:zoom` and `Camera:offset` only; no methods, scripts, audio or gameplay callbacks;
- uses **cue ordinal plus actual within-cue progress**, not gameplay frames. Slow reading/voice playback holds the current shot. Pause, advance, skip and chapter replacement retain dialogue ownership;
- leaves the default watch camera unchanged when no valid private take is selected, and never grants receipts or unlocks.

`tools/authored_animation/review_private_camera.py --library ABSOLUTE_PRIVATE_MANIFEST --route kaia-windrow --body female` validates the source and prints the isolated review command. `--launch` is separately guarded by **18 GiB plus 800 MiB import forecast**. It uses the existing isolated review launcher and `PrivateCameraPlayableReview.gd`, opens watch mode at the chosen canonical First Loss, and does not seed or earn Story progress. Both bodies and all seven route takes are selectable. No actual new normal-speed review has been recorded below the storage reserve.

Native verification: seven camera-text resources imported, all 114 canonical bindings sampled, 147 checks passed (including cue easing, reduced-motion holds and cancel isolation). Watch-source compilation with lightweight placeholder dependencies passed. These results do not prove full BattleScene integration, body framing, physical contact, final animation or owner visual approval.

## Cinematic delivery truth

`tools/authored_animation/inventory_story_media.py` maps the canonical director to twelve Kaia sequences, six acts for each of six variations, and five separate Convergence sequences: **53 editorial sequences / 145 source nodes**. Detailed output must be written privately, not committed here.

The existing Kaia movie is a 131.6-second, 7.5 fps technical preview at `ce2775f1`, with a reconstructed candidate event mix. The two retained First Loss dialogue movies at `09f2a651` are staged private reviews containing uncleared temporary voices. They are neither final films nor public web media. Legacy ce2775f1's First Loss still is labeled Rook but visibly shows Juno; retain it as unsuitable casting evidence, not current-canon acceptance. Current source correctly maps Kaia's First Loss opponent to Rook.

No final continuous Kaia OVA, six completed variation films or finished Convergence finale has been verified. Final body/facial acting, source-space contact, feet/floor, costumes/hair/materials, camera/lighting/VFX, cleared dialogue/music, missing shots and editorial assembly remain production work. Orion's Last Vector fate is unresolved. Later lost-character dialogue is memory, never evidence of a restored physical teammate. Watch mode cannot satisfy earned campaign completion.

## Private versus public payload boundary

Keep editable Blender sources, original rigs, art-stage scenes, animation projects (including the new camera takes), private measurements and unapproved review media PRIVATE. Do not copy them to public Git, public Actions artifacts, frontend static folders, CDN buckets or web bundles.

A future public-client candidate may contain only owner-authorized optimized exports and media, accompanied by exact file SHA-256, origin/provenance, import mappings, animation-event manifests, rights/disclosure receipts and runtime/device evidence. **No such new shipping package was created or authorized here.** Earlier scoped public technical-artifact approvals do not authorize a new playable client asset disclosure.

A browser client downloads resources it uses; those resources can be extracted. A private production repository does not make resources in the delivered client private. Owner approval must explicitly cover the exact game-ready exports/media and this disclosure before Cursor publishes them. Do not package uncleared temporary voices or treat a preview as a finished OVA.

## Next interfaces and blocked execution

The latest owner explicitly requires the private Actions job to remain disabled and prohibits paid usage or new infrastructure. Do not request quota/budget changes or use a public art job instead. The prepared job is preserved. Neither Anime repository has a registered self-hosted runner. The implemented local recipe `run_metric_stage_8d4_local.py` uses existing archived inputs and installed tools without any network service, download or upload; actual execution remains blocked by internal free space below22GiB and incompatible local Blender3.3.1. The exact preserved source producer Blender4.0.2 and the unchanged18GiB-after4GiB-allocation reserve are required. No local art production has started. Local production now requires one explicit case; no batch mode/automatic acceptance is available. A separate tiny headless watch/dialogue fixture reproduced pause loss on chapter navigation and now passes15 checks after preserving pause on the new scene/model/voice clock. Synthetic actors/silent audio do not prove shipping body or audio quality. Reference pair production must pass actual source-mesh contact, penetration, reach, floor support, save/reopen and side/three-quarter review before full-roster paired acting. Offline staging remains distinct from unverified shipping renderer calibration across the two SubViewports.

After authorized private production, use the existing restricted recovery/provenance path. Provide Cursor a newly reviewed, hash-bound export candidate; Cursor should validate it in its own branch without overwriting this art checkout. Runtime projection calibration, web import/packaging, LAN/controllers and physical-device acceptance remain separate engineering interfaces. No human art/gameplay/balance/mix/OVA/release gate is promoted by this handoff.
