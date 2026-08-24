#!/usr/bin/env bash
# make engineering-wave017
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/wave017 artifacts/engineering_wave017 tmp game-godot/artifacts/engineering_wave017 docs/engineering_wave017

ACCEPTED_MAIN_SHA="aef8ce845bf01f51703d2dbd584932198a36881c"
echo "=== Wave017 accepted main SHA (PR87 merge): ${ACCEPTED_MAIN_SHA} ==="
echo "=== HEAD=$(git rev-parse HEAD) ==="

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
echo "=== Wave017 Godot: $($GODOT --version 2>/dev/null || echo unknown) ==="

run() {
  local name="$1"; shift
  local log="tmp/wave017-${name}.log"
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

run taste_gate make taste-gate
run emit_owner_baseline python3 tools/engineering_wave017/emit_wave017_packet.py
run placeholder_scan python3 tools/quality/check_placeholder_visuals.py

godot_orchestration_prepare "wave017" "${ROOT}"
godot_orchestration_teardown "${ROOT}" || true
godot_orchestration_prepare "wave017-godot_import" "${ROOT}"
run godot_import bash -c 'source "$1" && godot_orchestration_import "$2" "$3" 3 wave017-godot_import "$4"' _ "${ROOT}/tools/engineering_wave015/godot_orchestration.sh" "$GODOT" "$ROOT/game-godot" "$ROOT"

run model_visibility "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/quality/TasteGateModelVisibility.gd || true
run ghost_lifecycle "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave017/Wave017GhostLifecycle.gd
run debug_label_scan "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave017/Wave017PlayerBuildDebugLabels.gd
run golden_slice_visual "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave017/Wave017GoldenSliceVisual.gd

# Preserve Wave016 move application foundation
run wave016_routing_regression "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave016/Wave016GoldenSliceMoveE2E.gd
run wave016_projectile_regression "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave016/Wave016EmberProjectileRuntimeE2E.gd

# Pixel campaign (honest if device missing)
if command -v adb >/dev/null 2>&1 && adb devices | rg -q "device$"; then
  run pixel_campaign python3 tools/engineering_wave017/run_pixel_campaign.py || true
else
  echo "=== PIXEL6A unavailable — recording BLOCKED_PIXEL6A ==="
  python3 - <<'PY'
import json, pathlib
p = pathlib.Path("artifacts/wave017/PIXEL_CAMPAIGN.json")
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps({
  "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
  "NORMAL_PLAY_GHOST_FIGHTER_OCCURRENCES": None,
  "PIXEL_AUTHENTIC": False,
}, indent=2) + "\n")
PY
fi

python3 tools/engineering_wave017/emit_wave017_result.py
echo "=== Wave017 local harness complete ==="
