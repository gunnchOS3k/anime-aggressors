# Projectile clash readability — October 20

The prior CPU observation contained **zero projectile interceptions**. Controlled two-player collisions did occur, but faint shield rings, duplicate endpoint dissipations and overlapping sounds obscured the outcome. Breakthrough feedback could point along the losing shot. Physics, integrity, damage and defense rules remain unchanged.

Cancellation now draws inward mixed-element crescents and a short contact seam; both flight silhouettes retire immediately. Breakthrough fragments the weak side, points along the survivor and removes counted energy shells while keeping its core visible. Major charged collisions get a larger brief mixed-element pulse and bounded surface response. Ordinary shots add no camera impulse, fullscreen flash or hitstop.

Watch the normal-speed [before movie](../../rendered/clash_readability_before1020.mp4) and [refined movie](../../rendered/clash_readability_final1020.mp4), with original game audio. Exact sources are `6105809` and `f566d4f9`; each has 679 native frames at 60fps and 458 verified gameplay frame codes. [Contact sheet](final_short/CONTACT_SHEET.png). Quick cancellation is at native frame295; full-versus-quick breakthrough at554. Integrity4→3, trajectory and damage7.7090112 match the before trace exactly. The intermediate X-shaped candidate is preserved as a diagnostic.

The refined movie predates the latest crowd ornament reduction and Full-major surface layering (`369b3d34`). Inspect their [current native fixture pixels](stress_native_flushed/PIXEL_VERIFICATION.json), including [Full stress](stress_native_flushed/clash_stress_Full.png), [Reduced stress](stress_native_flushed/clash_stress_Reduced.png) and [major collision](stress_native_flushed/clash_major_Full_75.png). These use explicit fixture positions/aura and disabled controls; they are not ordinary-play evidence. A failed watchdog preview and a stale-pixel preview remain preserved and excluded.

Twelve nearby same-frame collisions retain twelve primary cue admissions in each mode. Full/Balanced active meshes fall84→36; Reduced32→29. New one-shot players fall72→25, including normal projectile release sounds; clash-owned voices are separately capped4/3/2 and onset-limited. These are node counts, not loudness or sustained hardware performance. Crowding reduces secondary decoration and compactness, never merges combat events. Full/Balanced/Reduced ordinary two-player runs each verified quick/medium/full cancellation and full-versus-quick breakthrough with identical outcomes.

An additional ordinary repeated-input pass confirmed nine quick cancellations in each mode (27 total), all with primary cues and zero fighter damage. Balanced suppressed decoration on7/9 events; Reduced on9/9; peak clash voice count1. This is headless public-input evidence; the nearby native stress pixels above are separate.

Nine focused regression suites passed on exact runtime `369b3d34`. Native Compatibility fixture passed21 rows/54 events/54 primary admissions; pool cleanup, sound limits, stage layering and major-sound priority passed. Existing exit resource/ObjectDB diagnostics remain. [Results and source bindings](RESULTS.json).

One bounded850-frame public-input run against unchanged active JunoCPU recorded15 player casts,11 CPU moves,18 contacts and **zero projectile interceptions**. It proves no CPU clash visibility claim. [Negative observation](ACTIVE_CPU_OBSERVATION.json). No repeated attempts or AI changes were made.

Launch from the repository:

```sh
tools/v1_closure/play_projectile_review.command --local --clash-indicators
```

Kaia: A/D movement, K shot, L shield; K+L charge. Juno: arrow movement, comma shot, period shield; comma+period charge. Keep both on the same ground facing each other. Fire quick shots together; charge both past50 for medium, both past75 for major, or only Juno past75 against Kaia quick for breakthrough. Watch the survivor lose a shell and continue left. Omit `--local` for active CPU; omit `--clash-indicators` for normal uncluttered play. `--male` selects existing male models. Full/Balanced/Reduced remain available in settings. This isolated review does not write Story saves.

Original analytic geometry/shader and existing original elemental audio only; no new licensed assets, voices or paid services. Media is owner development review, not authorized release. Kaia/Juno is not full-roster matchup acceptance. Human visual/audio approval, physical devices, floor/outer-reach and production choreography remain pending. All human/release gates stay false; PR123 remains draft and stacked on122.
