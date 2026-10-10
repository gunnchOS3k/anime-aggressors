# ANI-03 spectral feedback implementation

Owner direction: October 10, 2026. This continues draft #123 stacked on preserved draft #122 at c5f3be23bf7376f2a0b71a8aabc1396415ef8186. Owner-reported reference moments are design direction. Neither reference MP4 is attached/available in this conversation; no footage was personally analyzed and no recording, Nintendo asset, decompiled code or reel content was imported.

Confirmed resolution owns contact. HitResolver emits a unique event with attacker/defender/move IDs, physics frame, move frame, monotonic timestamp, intersecting world-space shape position (or actual projectile contact), direction, element, hit/shield/armor result, damage, hitstop, launch, airborne state, prior combo count, counterhit and defender pre-contact state. MoveRunner/projectile target ledgers reject duplicate resolutions; the renderer also rejects repeated event IDs. Animation activation emits attack_swing only. Parry and clash are unsupported by current collision rules; this implementation does not invent their gameplay authority.

The scene-owned SpectralFeedback renderer uses original analytic distance fields on pooled MeshInstance2D/QuadMesh objects under Godot gl_compatibility. It contains no raster assets or imported shader code. Contact has a brief core, directional crescent, distinct elemental structure and bounded secondary motes. Light clears in 0.18 s; heavy in 0.26 s. Hurt accents follow the actual defender for 0.2 s. Shield is an open defensive pressure crescent; armor retains angular elemental compression. Charge is a single evolving owned emitter. Projectiles have release, persistent flight, intermittent wake, confirmed collision and short dissipation. Environment contact is a separate physical callback, never fighter damage. Launch smoke is emitted only after actual displacement during hitstun, scaled to authentic speed. Confirmed stock loss alone creates finishing geometry; a critical-launch prediction is not a KO.

Nine original grammars:

| Fighter | Geometry and motion |
| --- | --- |
| Ember | Turbulent flame tongues, combustion corona and warm smoke |
| Rook | Angular compression planes and radial fractures |
| Juno | Seeded irregular segmented arcs with short lateral branches |
| Kaia | Nested open crescents and pressure ribbons |
| Nix | Six faceted crystalline lances and a formation ring |
| Orion | Elliptical orbit and inward-moving satellite nodes |
| Vesper | Offset interrupted phase seams |
| Yin | Contracting aperture and inward subtraction, no bright contact core |
| Yang | Expanding hexagonal construction with ordered radial rays |

Budget: at most 96 mesh objects per scene, 32 in reduced-density mode. Primary confirmation/charge can replace decorative smoke, whiff or dissipation when saturated. Reuse avoids repeated node allocation; scene ownership disposes the pool on exit. Secondary motes are analytic shader lobes, not GPU particle objects: ten normally, two at reduced density. Reduced flashes remove the bright core, lower opacity and slow electrical topology changes. Reduced shake immediately clears camera offset. High-contrast ink preserves geometric differences. These settings are available through the existing presentation settings panel and persisted in the isolated/user presentation config.

No move manifests, damage formulas, hitstun durations, competitive form parity, collision geometry, AI, netcode, Story graph, receipt qualification or saves were tuned. One verified gameplay defect is corrected: after a confirmed body hit, the defender's ongoing MoveRunner is cancelled and its hitbox disabled. Baseline fixture at 48df724e failed because the victim remained in an active move while launched; its later active/end callbacks could overwrite hurt recovery. Shield and armor contacts keep their existing rules. InterruptedMove verifies the correction independently of combo success. Existing punch assets, elemental synthesized audio and facial/hurt animation paths remain. Existing critical-predictor hitstop behavior is retained. The earlier explicit key-pose studies remain development animation, with foot planting, refined contact choreography and secondary motion still open.

Evidence distinguishes direct contact/lifecycle fixtures, public-input whiff tests, uninterrupted idle-P2 charge fixtures, and public-input active-CPU matches. Medium/high combo fixtures set starting opponent percent once (50/110), label that setup, and never assign damage, velocity, positions, attack results or KOs during play. A follow-up counts only if natural resolution observes the defender still in a hurt/hitstun/launch state before the next contact.

60 fps MovieWriter AVI contains the actual Godot mixed PCM audio, then is encoded to H264/AAC without dubbing. Fixed recording cadence is not a claim of sustained hardware 60 fps. Mac CPU update/render timings are recorded; GPU timing reported as zero by this backend is unavailable. Windows/Web/Android/Pixel acceptance remains unearned. The 18 GiB platform-export guard remains active; only bounded native source recordings are allowed with a separate 2 GiB reserve.

GAME_FEEL_HUMAN_PASS=false
VFX_TASTE_HUMAN_PASS=false
ANIMATION_TASTE_HUMAN_PASS=false
SFX_MIX_HUMAN_PASS=false
V1_ANIME_HUMAN_PASS=false

Development implementation is authorized. Final art, audio redistribution, acting, OVA, platform, human quality and release gates are not earned. No merge, deploy, tag or publication.
