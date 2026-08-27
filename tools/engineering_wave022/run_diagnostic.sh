#!/usr/bin/env bash
# Individual Wave022 diagnostic targets
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
GODOT="${GODOT_BIN:-/Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot}"
mkdir -p artifacts/engineering_wave022 tmp

run_godot() {
  local name="$1" script="$2"
  local log="tmp/wave022-${name}.log"
  echo "=== ${name} ==="
  "$GODOT" --headless --path "$ROOT/game-godot" --script "$script" >"$log" 2>&1 || {
    tail -40 "$log"
    exit 1
  }
  if rg -q "SCRIPT ERROR|Parse Error" "$log" 2>/dev/null; then
    tail -40 "$log"
    exit 1
  fi
  echo "PASS ${name}"
}

case "${1:-all}" in
  form-architecture) run_godot form res://tests/engineering_wave022/Wave022FormArchitectureDiagnostic.gd ;;
  battle-scale) run_godot scale res://tests/engineering_wave022/Wave022BattleScaleDiagnostic.gd ;;
  ui-feel) run_godot ui res://tests/engineering_wave022/Wave022UIFeelDiagnostic.gd ;;
  full-roster-ascension) run_godot ascension res://tests/engineering_wave022/Wave022FullRosterAscensionDiagnostic.gd ;;
  rook-ascension) run_godot rook res://tests/engineering_wave022/Wave022RookAscensionDiagnostic.gd ;;
  *) echo "Usage: $0 {form-architecture|battle-scale|ui-feel|full-roster-ascension|rook-ascension}"; exit 1 ;;
esac
