#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
GODOT="${GODOT_BIN:-$(command -v godot || echo /Applications/Godot.app/Contents/MacOS/Godot)}"
echo "=== Wave020 pause diagnostic ==="
LOG="tmp/wave020-pause-diagnostic.log"
mkdir -p tmp artifacts/engineering_wave020
set +e
"$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020PauseMoveList.gd 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
set -e
if [[ $code -ne 0 ]]; then
  echo "FAIL pause diagnostic (exit $code)"
  tail -40 "$LOG" || true
  exit "$code"
fi
echo "PASS wave020-pause-diagnostic"
