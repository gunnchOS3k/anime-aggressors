# CODEX — integrate original V1 screenplay drafts and temporary TTS without changing story authority

## Purpose
This is an ORIGINAL screenplay handoff drafted October 9, 2026 after inspecting the approved Creative Authority Pack V1, game-godot/data/story/v1_campaign.json, Story manifest and ANI-02 First Loss decision record. This package was authored outside the repository; NOTHING in this ZIP has been merged, tested in Godot, spoken by TTS, or approved as final dialogue. It covers all 145 source graph node IDs and one Kaia OVA + six Campaign Variations + Sevenfold finale.

## Input assets
- `ANIME_V1_DIALOGUE_PRODUCTION_DRAFT.json`: structured lines/events indexed by exact source graph node IDs.
- `ANIME_V1_FULL_CAMPAIGN_SCREENPLAY.md`: human-readable 145-node script and performance cues.
- `ANIME_V1_OVA_VARIATIONS_DIRECTOR_SCRIPT.md`: camera, progression and adaptation/voice guidance.
- `ANIME_V1_TTS_CUE_MANIFEST.csv`: line IDs, speakers, draft text, temporary sound file paths, clearance columns.
- `README.md`: source/provenance and validation manifest.

## First inspect / do not overwrite
Use existing draft PR #122 at `175e178ad583638603b92f5ea9a333239d419796`, tested gameplay source SHA `30ea37f5e653357bc4ca2b6867d05cc221429b19`, and existing preserved worktree. The original Creative Authority Pack remains primary; October 9 ANI-02 overrides historical open First Loss identities. Maintain no forced permanent deaths; Orion ultimate fate open. Preserve seven Gray routes, six Essences and five Convergence nodes; keep all final human gates false.

## Import and integration (focused draft PR on top of existing line)
1. Compare dialogue JSON `node_id`s with the live Story graph and validate exactly 145 matches, exactly seven unique approved First Losses, all referenced speakers, and no missing/duplicate cue IDs. Correct script mismatches by explicit evidence, not silently changing accepted game nodes.
2. Stage the files in a proposed `data/story/dialogue/v1/` directory or equivalent repo-native authority location. Do not replace existing Story graph JSON wholesale. Build an additive dialogue loader reading cue ID/phase/speaker/subtitle safely with a clear draft status.
3. Bind PRE/MID/POST to real Story objective hooks/cinematic stages, not wall-clock or menu shortcuts. No audio or watch interactions may mint gameplay receipts. On loss/retry/restart, subtitle and TTS events must be deduplicated and sequenced correctly.
4. Implement interruptible subtitle presentation, skip/replay, accessibility controls, disabled-audio fallback, language-ready keys, transcript view and profanity/content safety review as needed. Ensure combat is not blocked by long speech or a missing file.
5. For local TTS preview use an existing licensed synthesizer if available. On Mac, `say` can generate *non-shipping private evaluation only* until Apple/system-voice distribution rights are independently established. Provider/voice licensing and consent must be recorded. Do not impersonate real persons. Prefer deterministic local synthesis with explicit model/version/voice assignment and exact per-cue hashes. If unable to lawfully ship generated audio, retain subtitle-only public builds and mark VO_PENDING.
6. Capture current renderer scenes for Kaia and Juno's The Last Vector and conduct audio/subtitle/battle/OVA synchronization checks. Preserve synthetic voices as TEMP, label all script lines DRAFT_OWNER_REVIEW, and prepare one reviewer packet with voiced previews and transcripts.
7. Make small commits and focused tests. Keep PR #122 draft (or focused stacked draft PR), never merge/deploy/publish until separate owner authorization. Preserve 33 historical worktrees/backups and all disk guards.

## No shortcuts
Do not claim the script is implemented merely from 145 JSON keys; validate playback within real scenes. Do not claim the full OVA is animated because a written adaptation is complete. ANI-03 bespoke combat, ANI-04 cinema/OVA, ANI-05 exported hardware remain open.

## Final report
Exact branch/head/PR, number of dialogue cues imported and audible with evidence, source/hash/policy, real launch instructions, 7 First Loss reviews, continuous Kaia OVA preview status, six variation status, subtitle accessibility, TTS license status, zero regressions, and remaining owner-only decisions.
