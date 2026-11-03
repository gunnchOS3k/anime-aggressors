# Anime Aggressors: dialogue and elemental performance development review

Draft stacked PR: [#123](https://github.com/gunnchOS3k/anime-aggressors/pull/123), against preserved [#122](https://github.com/gunnchOS3k/anime-aggressors/pull/122). Base c5f3be23bf7376f2a0b71a8aabc1396415ef8186; prior ordinary-renderer source 83bab0825230154761b39e1a7ff63eeacf66de8d. Exact final source and evidence SHAs are recorded in FINAL_IMPLEMENTATION_REPORT.json and capture_index.json.

## Confirmed causes

Aura charge only set a flag; it did not start sound playback. Projectiles had no launch/travel/dissipation sound path. Collectible candidate sounds took precedence over the v3 resolver, and music stop also stopped effects. Embedded GLB animations took precedence over JSON pose changes. LIVE_AUDIO_ROUTING.md in the production documentation traces the corrected live paths.

## What is implemented

- 145 nodes / 1,025 cue IDs compiled against the current Story graph and CSV. Speaker, scene, event, subtitle, emotion, read time, pronunciation and voice asset identity are stable. Real event hooks cover combat contact, decisions, releases, Essence, Gray, endings and Convergence. Speech uses a persistent presentation director; it never issues outcomes, receipts or unlocks.
- Subtitles include speaker names and memory labeling; Tab advances, F6 skips the current sequence, F7 opens a scrollable transcript. Buttons support pointer/controller focus. Text size, reading pace, voice, element layer and music levels, reduced flashes and reduced shake are available in Settings → Dialogue and elemental audio. Pauses stop timer/audio; retry resets cue deduplication; missing WAVs use readable text. Scene endings only fire after the existing authenticated result succeeds.
- Nine distinct local eSpeak NG formant profiles and 1,025 preview WAVs. Same character voice across male/female presentations. Stable cue IDs support professional replacement through an explicitly cleared asset manifest. Temporary previews are local, excluded from Git and exports; redistribution is not cleared. No paid APIs, recognizable actor imitations or third-party voice models. Full direction sheets are in ../../../docs/anime-aggressors/v1_closure/dialogue_production/VOICE_DIRECTION.md; per-file provenance is in temporary_voice_manifest.json.
- 117 original elemental mixes / 351 body-texture-transient stems. Charge start/loop/ready/release/cancel and projectile launch/travel/impact/dissipation run on actual actors, with owned loop lifetimes. Solid original impacts are byte-preserved. Heavy and signature add elemental layers. Attacker element is preserved when blocked. New mixes have headroom and a -1 dB Master limiter prevents uncontrolled clipping.
- 216 existing gameplay moves across nine fighters have original explicit key-pose studies, using hips, spine, chest, head, both arms, legs and feet. The visible library is prioritized over embedded candidate clips and sought on the existing 60 Hz move timeline; hitstop freezes its presentation. Existing frame data, damage, knockback, hitboxes, progression and save authority are unchanged. These remain candidate studies, not final authored choreography or human taste acceptance.

## Review the captures

Open the links in CAPTURE_REVIEW.md. Current combat clips have native Godot audio and automated ordinary input against real CPU opponents. Before clips use the preserved base scripts through a read-only temporary overlay. These are offline renderer recordings with live gameplay input, not human playthroughs. Each recording has both audio/video stream and non-silence verification, source identity, observed move events and explicit fixture labels.

Kaia/Rook and Juno/Orion clips are read-only First Loss staging in the current renderer, with draft subtitles, camera focus, facial expressions and local synthetic voices. They must not be treated as earned Story play, final acting, completed cinematics or final OVA production. The complete adaptation stays one continuous Kaia OVA plus six variations.

Blind audio files are in audio_ab/. Listen to A and B for each fighter before reading KEY.json. Compare fire/heat/pressure for Ember, electrical snap/arcing/thunder for Juno, and charge start/sustain/ready character. Compare the full combat mix in the videos as well as isolated layers.

## Play the source build

From the repository, run `python3 tools/v1_closure/launch_ordinary_review.py --profile owner_dialogue_performance_20261010 --output artifacts/v1_closure/dialogue_performance/local_media/manual_review`. This opens the current source with a separate owner-review save profile; no staged unlocks are injected. Use Main Menu → Settings → Dialogue and elemental audio to adjust captions, voice and mix. Story progress requires ordinary qualifying play. Use Watch for the read-only adaptation paths. Temporary WAVs are already available locally; other checkouts use subtitles until local previews are generated. No heavy platform export is needed.

## Owner feedback to record

1. Does Ember sound unmistakably fiery and powerful, and Juno electrical and dangerous?
2. Do anticipation, body rotation, contact, follow-through and recovery convey skilled combat rather than sliding toys?
3. Are the nine identities distinct and both presentations compatible?
4. Are attacks fast, responsive, readable and exciting against active opponents?
5. Do sound, impact and movement communicate cause and consequence without obscuring play?
6. Are subtitles and temporary voices readable, coherent and appropriately timed?
7. Are First Losses distinct, with Juno's Last Vector and Orion's unresolved fate preserved?

Record explicit acceptance/rejection and specific timestamps. No automated result assigns a quality rating or passes a human gate.

## Evidence and limits

See dialogue_coverage.json, dialogue_runtime_test.json, temporary_voice_manifest.json, elemental_sound_catalog.json, elemental_runtime_test.json, choreography_matrix.json, integrity_checks.json and regressions/results.json. Isolated cue tests prove presentation/binding coverage; staged FullCampaign proves source objectives/saves; ordinary_kaia evidence uses genuine public inputs and qualifying receipts. Each scope stays labeled.

Production dependencies are detailed in ../../../docs/anime-aggressors/v1_closure/dialogue_production/PRODUCTION_DEPENDENCIES.md. ANI-03 still needs final contact/foot-plant/secondary-motion/transition and cosmic-boss choreography plus owner sound/mix/feel approval. ANI-04 needs approved dialogue, performer recording, acting/lip sync, final shot animation/edit/music/mastering. ANI-05 needs safe exact-head platform verification and release authorization. Human gates and V1_AUTOMATED_READY remain false.

All 33 historical worktrees and owner backups remain preserved. The 18 GiB guard blocks heavy Web/Android/PCK exports. No merge, deploy, tag or publish was performed.
