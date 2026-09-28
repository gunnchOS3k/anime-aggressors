#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
python3 tools/combat_v3/validate_161_matrix.py
GODOT="${GODOT_BIN:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "godot not found; skipping headless harness"
  exit 0
fi
"$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/combat_v3/WaveV3MoveContentCompletion.gd
python3 - <<'PY'
import json
from pathlib import Path
p = Path("artifacts/combat/v3/MOVE_EXECUTION_HARNESS.json")
if p.is_file():
    d = json.loads(p.read_text())
    print("HARNESS", {k: d.get(k) for k in [
        "MOVE_EXECUTION_PASS","MOVE_ANIMATION_PASS","MOVE_VFX_PASS",
        "MOVE_PARTICLE_PASS","MOVE_SFX_PASS","DIRECTIONAL_THROW_CONTENT",
        "NON_MOVE_ANIMATION_STATE_COVERAGE"
    ]})
    for key in [
        "OWNER_MOVESET_COMPLETENESS_PASS","OWNER_ANIMATION_QUALITY_PASS",
        "OWNER_VFX_QUALITY_PASS","OWNER_AUDIO_QUALITY_PASS","OWNER_COMBAT_FEEL_PASS",
        "HUMAN_ORIGINALITY_REVIEW_PASS","MERGE_AUTHORIZED"
    ]:
        assert d.get(key) is False, key
PY
