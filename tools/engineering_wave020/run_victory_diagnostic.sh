#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
GODOT="${GODOT_BIN:-$(command -v godot || echo /Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot)}"
echo "=== Wave020 victory presentation diagnostic ==="
LOG="tmp/wave020-victory-diagnostic.log"
mkdir -p tmp artifacts/engineering_wave020
set +e
"$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020VictoryDiagnostic.gd 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
set -e
if [[ $code -ne 0 ]]; then
  echo "FAIL victory diagnostic (exit $code)"
  tail -40 "$LOG" || true
  exit "$code"
fi
if [[ ! -f artifacts/engineering_wave020/VICTORY_PRESENTATION_DIAGNOSTIC_RESULT.json ]]; then
  echo "FAIL victory diagnostic (missing result JSON)"
  exit 1
fi
if grep -q '"ok":false\|"ok": false' artifacts/engineering_wave020/VICTORY_PRESENTATION_DIAGNOSTIC_RESULT.json; then
  echo "FAIL victory diagnostic (ok=false)"
  exit 1
fi
echo "PASS wave020-victory-diagnostic"
