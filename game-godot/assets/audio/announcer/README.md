# Announcer voice slots

This directory is split on purpose.

## `final/`

Reserved for future original or licensed recorded fighter-name reads.

- Empty until rights and performer direction are approved.
- `ANNOUNCER_FINAL_VOICE_ASSETS` and `SELECT_ANNOUNCER_AUDIO_RIGHTS_READY` stay false until then.
- Missing files here are expected and must not crash select.

## `review_only/`

Optional locally generated **REVIEW_ONLY** speech renders.

- Not a final performer.
- Not Smash Bros., not ripped packs, not unlicensed commercial VO.
- Runtime platform TTS is preferred so these files are not needed.
- **Release is forbidden while any rendered review-only voice file remains here.**

## Runtime path

`AnnouncerVoiceProvider` speaks the short lock-in name (Ember, Rook, Juno, Kaia, Nix, Orion, Vesper) on confirmed selection only.
