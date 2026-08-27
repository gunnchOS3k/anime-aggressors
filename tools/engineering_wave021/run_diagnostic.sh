#!/usr/bin/env bash
# Individual Wave021 diagnostic targets
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
GODOT="${GODOT_BIN:-/Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot}"
mkdir -p artifacts/engineering_wave021 tmp

run_godot() {
  local name="$1" script="$2"
  local log="tmp/wave021-${name}.log"
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
  form-architecture) run_godot form res://tests/engineering_wave021/Wave021FormArchitectureDiagnostic.gd ;;
  aura-tiers) run_godot aura res://tests/engineering_wave021/Wave021AuraTierDiagnostic.gd ;;
  ember-ascension) run_godot ember res://tests/engineering_wave021/Wave021EmberAscensionDiagnostic.gd ;;
  battle-scale) run_godot scale res://tests/engineering_wave021/Wave021BattleScaleDiagnostic.gd ;;
  ui-feel) run_godot ui res://tests/engineering_wave021/Wave021UIFeelDiagnostic.gd ;;
  *) echo "Usage: $0 {form-architecture|aura-tiers|ember-ascension|battle-scale|ui-feel}"; exit 1 ;;
esac
