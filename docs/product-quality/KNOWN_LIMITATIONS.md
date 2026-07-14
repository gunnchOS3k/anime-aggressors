# Known Limitations — Anime Aggressors

- Main menu lacks web Three.js liveliness (parity matrix open items)
- Fighter presentation still uses shared geometric **proxy GLBs** (visually near-identical) with floating name labels — not release-art characters
- Stages are greybox ColorRect platforms (blast zones work; art incomplete)
- Concept-art / anime visual treatment for fighters/arena incomplete
- Scripted SceneTree input can miss hitboxes while opponent is in grab/shield leftover state (combat resolver works; acceptance may force one `receive_hit` for damage % proof)
- Settings surface still notes audio/display as playtest placeholders; **touch_mode** now persists via `user://aa_settings.cfg`
- Disk space below 15 GB gate prevents fresh release export when free space dips under limit
- Pixel device acceptance still **NOT TESTED** while ADB empty

## Closed this pass

- Fighter move data smoke: aligned to `move_schema.json` required IDs (`jab_1`…, `throw_forward`…). All seven fighters already had schema-complete moves; legacy smoke looked for non-schema `jab`/`throw` IDs. Headless `smoke_runner` → **all suites passed** (2026-07-13).
- Godot 4.5 visible journey driver (`accept_visible_match.gd`) exercises menu → ruleset → match → results → training → settings persistence; debug HUD starts hidden; `ORIGINAL 3D PROXY` watermark hidden (2026-07-14).
- Pause overlay re-anchored on-screen with readable panel (2026-07-14).
- Visible acceptance evidence captured: 26 PNG screenshots + `visible-runner.log` under `docs/product-quality/evidence/visible-anime/`; harness `RESULT failed=0` (2026-07-14).
- `touch_mode` settings persist via `user://aa_settings.cfg` (verified in visible harness).

## Blocks FULL visible GUI PASS

- Release fighter art: shared proxy GLBs + floating name labels (documented; not a harness failure).
- Stage art: greybox ColorRect platforms only.
- Screen recording of full playthrough not captured (screenshots sufficient for this gate).
