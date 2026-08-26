#!/usr/bin/env bash
# make wave020-fighter-select-diagnostic — fail-fast OWNER-REG-009
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
source "${ROOT}/tools/engineering_wave015/godot_orchestration.sh"
export GODOT_ORCH_ROOT="${ROOT}"
godot_orchestration_prepare "wave020-reg009" "${ROOT}"
GODOT="${GODOT_BIN:-$(command -v godot || echo /Applications/Godot.app/Contents/MacOS/Godot)}"
echo "=== Wave020 Fighter Select diagnostic (OWNER-REG-009) ==="
LOG="tmp/wave020-fighter-select-diagnostic.log"
mkdir -p tmp artifacts/engineering_wave020
set +e
"$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020OwnerReg009Diagnostic.gd 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
set -e
if rg -q "SCRIPT ERROR|Parse Error|Failed to load script" "$LOG" 2>/dev/null; then
  # Diagnostic itself must load; select-script parse errors should be caught as FAIL payload.
  if rg -q "Wave020OwnerReg009Diagnostic" "$LOG" && rg -q "Parse Error" "$LOG"; then
    if ! rg -q "OWNER-REG-009 DIAGNOSTIC" "$LOG"; then
      echo "FAIL: Godot script error before diagnostic completed"
      tail -40 "$LOG" || true
      exit 1
    fi
  fi
fi
if [[ $code -ne 0 ]]; then
  echo "FAIL: OWNER-REG-009 diagnostic — stopping campaign (exit $code)"
  tail -40 "$LOG" || true
  exit "$code"
fi
echo "PASS wave020-fighter-select-diagnostic"
