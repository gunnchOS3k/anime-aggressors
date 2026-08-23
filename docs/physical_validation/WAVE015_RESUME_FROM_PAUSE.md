# Wave015 Resume From Owner Pause

Paused at owner request (`OWNER_REQUESTED_GRACEFUL_PAUSE`).
Do **not** resume until Edmund explicitly asks.

## Checkpoint location

`artifacts/engineering_wave015/pause_checkpoint/PAUSE_CHECKPOINT.json`

## Exact resume command (copy/paste)

```bash
cd /Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/anime-aggressors/.worktrees/wave015-pixel6a-crash-census && \
export GODOT_BIN="$HOME/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot" && \
adb start-server && adb devices -l && \
python3 -c "import json; print(json.load(open('artifacts/engineering_wave015/pause_checkpoint/PAUSE_CHECKPOINT.json'))['resume']['exact_command'])" && \
# Then execute remaining incomplete gates only (see PAUSE_CHECKPOINT stage_statuses):
# - WAVE_REGRESSIONS_011_015 (IN_PROGRESS_PAUSED)
# - PR_PUSH_CI (NOT_STARTED)
# - Re-confirm owner smoke / human-path only if evidence requires re-run
make engineering-wave011 && \
make engineering-wave012 && \
make engineering-wave013b && \
make engineering-wave014 && \
make engineering-wave015 && \
git status -sb && \
git push -u origin HEAD && \
gh pr checks 85 --repo gunnchOS3k/anime-aggressors --watch
```

## Rules on resume

- Do **not** merge
- Do **not** claim `PHYSICAL_STABILITY_PASS` until Section 21 gates are all met
- Preserve `.partial` files and `pause_checkpoint/`
- Pause/force-stop marked `EXPECTED_TERMINATION=true` — do not cluster as crash
- Keep `HUMAN_PLAYTEST_COMPLETE=false` and `HUMAN_ART_DIRECTION_APPROVAL=false`

## Branch / head at pause

- Branch: `eng/wave015-pixel6a-physical-repairs`
- Worktree: `.worktrees/wave015-pixel6a-crash-census`
- See `PAUSE_CHECKPOINT.json` for `HEAD_SHA_AT_PAUSE` and APK SHA
