#!/usr/bin/env bash
# make engineering-wave018
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/engineering_wave018 artifacts/wave018 tmp game-godot/artifacts/engineering_wave018 docs/engineering_wave018 docs/quality

ACCEPTED_MAIN_SHA="2d2dafd16905009441e012ba2abbd2fd586a6621"
echo "=== Wave018 accepted main SHA (PR88 merge): ${ACCEPTED_MAIN_SHA} ==="
echo "=== HEAD=$(git rev-parse HEAD) ==="
echo "=== TREE=$(git rev-parse HEAD^{tree}) ==="

source "${ROOT}/tools/engineering_wave015/godot_orchestration.sh"
export GODOT_ORCH_ROOT="${ROOT}"

resolve_godot() {
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then echo "${GODOT_BIN}"; return; fi
  for c in \
    /Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot \
    /Applications/Godot.app/Contents/MacOS/Godot \
    /opt/homebrew/bin/Godot \
    /opt/homebrew/bin/godot; do
    [[ -x "$c" ]] && { echo "$c"; return; }
  done
  command -v godot
}
GODOT="$(resolve_godot)"
export GODOT_BIN="$GODOT"
echo "=== Wave018 Godot: $($GODOT --version 2>/dev/null || echo unknown) ==="

run() {
  local name="$1"; shift
  local log="tmp/wave018-${name}.log"
  echo "=== ${name} ==="
  set +e
  "$@" >"$log" 2>&1
  local code=$?
  set -e
  if [[ $code -ne 0 ]]; then
    echo "FAIL ${name} (exit $code)"
    tail -80 "$log" || true
    return 1
  fi
  if rg -q "SCRIPT ERROR|Parse Error|Failed to load script" "$log" 2>/dev/null; then
    echo "FAIL ${name} (godot script error in log)"
    tail -80 "$log" || true
    return 1
  fi
  echo "PASS ${name}"
}

run taste_gate make taste-gate || true
run placeholder_scan python3 tools/quality/check_placeholder_visuals.py || true

godot_orchestration_prepare "wave018" "${ROOT}"
godot_orchestration_teardown "${ROOT}" || true
godot_orchestration_prepare "wave018-godot_import" "${ROOT}"
run godot_import bash -c 'source "$1" && godot_orchestration_import "$2" "$3" 3 wave018-godot_import "$4"' _ "${ROOT}/tools/engineering_wave015/godot_orchestration.sh" "$GODOT" "$ROOT/game-godot" "$ROOT"

run select_preview_stress "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave018/Wave018SelectPreviewStress.gd
run select_to_battle "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave018/Wave018SelectToBattleVisibility.gd
run battle_visibility "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave018/Wave018BattleVisibilityInvariant.gd
run model_visibility "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/quality/TasteGateModelVisibility.gd || true
run ghost_lifecycle "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave017/Wave017GhostLifecycle.gd || true
run wave017_golden "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave017/Wave017GoldenSliceVisual.gd || true
run wave016_routing "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave016/Wave016GoldenSliceMoveE2E.gd || true

run emit_baseline python3 tools/engineering_wave018/emit_roster_baseline.py
run emit_projectile python3 tools/engineering_wave018/emit_projectile_presentation.py
run emit_presentation python3 tools/engineering_wave018/emit_presentation_systems.py
run emit_integrity python3 tools/engineering_wave018/emit_code_integrity.py
run emit_truth python3 tools/engineering_wave018/emit_truth_boundaries.py
run emit_docs python3 tools/engineering_wave018/emit_docs.py
run emit_result python3 tools/engineering_wave018/emit_wave018_result.py

# Pixel campaign (honest if device missing)
if command -v adb >/dev/null 2>&1 && adb devices | rg -q "device$"; then
  run pixel_campaign python3 tools/engineering_wave018/run_pixel_campaign.py || true
else
  echo "=== PIXEL6A unavailable — recording BLOCKED_PIXEL6A ==="
  python3 - <<'PY'
import json, pathlib
from datetime import datetime, timezone
art = pathlib.Path("artifacts/engineering_wave018")
art.mkdir(parents=True, exist_ok=True)
payload = {
  "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
  "PIXEL_DEVICE_AVAILABLE": False,
  "PIXEL_AUTHENTIC": False,
  "reason": "no adb device",
  "emitted_at": datetime.now(timezone.utc).isoformat(),
}
for name in [
  "WAVE018_PIXEL_SELECT_STRESS_RESULT.json",
  "WAVE018_PIXEL_VISIBILITY_RESULT.json",
  "WAVE018_PIXEL_SMOKE_RESULT.json",
]:
  (art / name).write_text(json.dumps({**payload, "artifact": name}, indent=2) + "\n")
print(json.dumps(payload, indent=2))
PY
fi

echo "=== Wave018 orchestration complete ==="
