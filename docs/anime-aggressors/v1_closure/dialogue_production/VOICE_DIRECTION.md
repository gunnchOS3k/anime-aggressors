# Temporary voice direction

Development previews only. Formant synthesis is intentionally temporary; emotional intent is metadata, not completed acting. Each character retains one profile across presentation variants. Stable cue IDs and subtitle text remain unchanged when actors replace these files.

## ember-vale

Forward, warm and decisive; controlled heat.

Generic formant en-us+f3; 174 wpm, pitch 59, gap 1. Grief/soft slows 14%; strained slows 6%. No actor or copyrighted character performance reference.

## juno-spark

Fast precision; clear snaps, space after decisions.

Generic formant en-us+f4; 195 wpm, pitch 65, gap 1. Grief/soft slows 14%; strained slows 6%. No actor or copyrighted character performance reference.

## kaia-windrow

Fluid, reflective breath and purposeful resolve.

Generic formant en-us+f2; 154 wpm, pitch 53, gap 5. Grief/soft slows 14%; strained slows 6%. No actor or copyrighted character performance reference.

## nix-calder

Measured, precise and restrained.

Generic formant en-gb+f1; 150 wpm, pitch 51, gap 4. Grief/soft slows 14%; strained slows 6%. No actor or copyrighted character performance reference.

## vesper-nyx

Quiet, deliberate misdirection with honest grief.

Generic formant en-gb+f5; 165 wpm, pitch 45, gap 4. Grief/soft slows 14%; strained slows 6%. No actor or copyrighted character performance reference.

## rook-ironside

Grounded weight, short commitments; never caricature.

Generic formant en-us+m3; 135 wpm, pitch 32, gap 6. Grief/soft slows 14%; strained slows 6%. No actor or copyrighted character performance reference.

## orion-vell

Patient, spatial clarity; Last Vector is unresolved fate.

Generic formant en-gb+m2; 140 wpm, pitch 41, gap 5. Grief/soft slows 14%; strained slows 6%. No actor or copyrighted character performance reference.

## yin

Subtraction, space and deep controlled silence.

Generic formant en-gb+m1; 116 wpm, pitch 25, gap 6. Grief/soft slows 14%; strained slows 6%. No actor or copyrighted character performance reference.

## yang

Structured definition and exact harmonic conviction.

Generic formant en-us+m4; 154 wpm, pitch 52, gap 3. Grief/soft slows 14%; strained slows 6%. No actor or copyrighted character performance reference.

Pronunciations: {"Kaia": "Kai ah", "Juno": "Joo no", "Nix": "Nicks", "Orion": "Oh rye un", "Vesper": "Ves per", "Yin": "Yin", "Yang": "Yang"}.

License: eSpeak NG GPL-3.0-or-later, unmodified local execution. Generated audio remains local and is excluded from public distribution pending explicit output clearance. See the per-cue provenance manifest. Cost: zero.

## Replacement pipeline

`import_actor_voices.py --manifest <owner-provided manifest.json>` validates every cue before copying any file. Each asset row requires cue_id, file, exact subtitle, distribution_cleared=true, owner_asset_authorized=true, license_provenance, performer_consent and rights_holder. PCM16 WAV mono/stereo replaces the stable cue binding through voice_assets.json. Subtitle, emotion and speaker metadata remain attached; campaign logic is unchanged. Missing or uncleared replacements retain the local preview or text fallback. These asset permissions do not pass final dialogue, acting, Story or release gates.
