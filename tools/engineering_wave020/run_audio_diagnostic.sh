#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
GODOT="${GODOT_BIN:-$(command -v godot || echo /Applications/Godot.app/Contents/MacOS/Godot)}"
echo "=== Wave020 audio diagnostic ==="
LOG="tmp/wave020-audio-diagnostic.log"
mkdir -p tmp artifacts/engineering_wave020
python3 tools/audio/generate_procedural_sfx.py
set +e
"$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020ElementalAudio.gd 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
set -e
if [[ $code -ne 0 ]]; then
  echo "FAIL audio diagnostic (exit $code)"
  tail -40 "$LOG" || true
  exit "$code"
fi
echo "PASS wave020-audio-diagnostic"
