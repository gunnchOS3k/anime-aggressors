#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
GODOT="${GODOT_BIN:-$(command -v godot || echo /Applications/Godot.app/Contents/MacOS/Godot)}"
echo "=== Wave020 battle body diagnostic ==="
LOG="tmp/wave020-battle-body-diagnostic.log"
mkdir -p tmp artifacts/engineering_wave020
set +e
"$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020BattleBodyDiagnostic.gd 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
set -e
if [[ $code -ne 0 ]]; then
  echo "FAIL battle body diagnostic (exit $code)"
  tail -40 "$LOG" || true
  exit "$code"
fi
if [[ ! -f artifacts/engineering_wave020/BATTLE_BODY_DIAGNOSTIC_RESULT.json ]]; then
  echo "FAIL battle body diagnostic (missing result JSON)"
  tail -40 "$LOG" || true
  exit 1
fi
if grep -q '"ok":false\|"ok": false' artifacts/engineering_wave020/BATTLE_BODY_DIAGNOSTIC_RESULT.json; then
  echo "FAIL battle body diagnostic (ok=false)"
  exit 1
fi
echo "PASS wave020-battle-body-diagnostic"
