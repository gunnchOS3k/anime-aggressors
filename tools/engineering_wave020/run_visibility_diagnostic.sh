#!/usr/bin/env bash
# make wave020-visibility-diagnostic — fail-fast OWNER-REG-008
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
source "${ROOT}/tools/engineering_wave015/godot_orchestration.sh"
export GODOT_ORCH_ROOT="${ROOT}"
GODOT="${GODOT_BIN:-$(command -v godot || echo /Applications/Godot.app/Contents/MacOS/Godot)}"
echo "=== Wave020 visibility diagnostic (OWNER-REG-008) ==="
LOG="tmp/wave020-visibility-diagnostic.log"
mkdir -p tmp artifacts/engineering_wave020
set +e
"$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020OwnerReg008Diagnostic.gd 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
set -e
  if rg -q "SCRIPT ERROR|Parse Error|Failed to load script" "$LOG" 2>/dev/null; then
    echo "FAIL: Godot script error in diagnostic log"
    tail -40 "$LOG" || true
    exit 1
  fi
  if [[ $code -ne 0 ]]; then
  echo "FAIL: OWNER-REG-008 diagnostic — stopping campaign (exit $code)"
  tail -40 "$LOG" || true
  exit "$code"
fi
echo "PASS wave020-visibility-diagnostic"
