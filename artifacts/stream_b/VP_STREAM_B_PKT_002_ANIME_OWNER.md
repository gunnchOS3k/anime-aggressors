# STREAM-B-PKT-002 — Anime Aggressors owner tip (playtest rotation)

## Tip
- Base: `9770674` (main / GAME-RC-003 merged)
- Branch: `stream/b-pkt-002-playtest-polish`
- Choice: **anime-aggressors** (highest digital impact; Pedestrian already done; Godot — avoid Unity #51/#52)

## Verify
```bash
test -f release/playtest/PLAYTEST_PACKET_STREAM_B_PKT_002.json
python3 - <<'PY'
import json
p=json.load(open('release/playtest/PLAYTEST_PACKET_STREAM_B_PKT_002.json'))
assert p['HUMAN_PLAYTEST_VALIDATED'] is False
assert p['game']=='anime-aggressors'
assert len(p['sessions'])==4
print('PASS')
PY
rg -n "fade|slide|_play_in" game-godot/scripts/ui/achievement_toast.gd
test -f release/playtest/TELEMETRY_SCHEMA_STREAM_B_PKT_002.json
test -f release/playtest/A11Y_CHECKLIST_STREAM_B_PKT_002.md
test -f release/playtest/FEEDBACK_FORM_STREAM_B_PKT_002.md
test -f artifacts/stream_b/visual_perf/PACK_MANIFEST.json
```

## Claims
- Playtest scaffolding + toast fade/slide polish only
- `HUMAN_PLAYTEST_VALIDATED=false`
- Not FEATURE_COMPLETE_RC / POLISHED_RELEASE_CANDIDATE
- Cursor NEVER merges
