# Staging instructions

1. Place `<fighter-id>.glb` in `game-godot/content/human_art_staging/<fighter-id>/`.
2. Fill `candidate_manifest.json` with real source, license, and paths. Leave `owner_approved` false.
3. Run `npm run art:validate-human-roster`.
4. Run `npm run art:review-human-roster` (optional `--render` if Blender is available).
5. Production resolver stays on accepted art unless `HUMAN_ART_STAGING=1` or `HUMAN_ART_FULL_ROSTER_REVIEW=1`.
6. Generated V2–V9 files are rejected.
