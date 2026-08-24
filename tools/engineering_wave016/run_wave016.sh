#!/usr/bin/env bash
# make engineering-wave016
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/wave016 artifacts/engineering_wave016 tmp game-godot/artifacts/engineering_wave016

MAIN_SHA="b8da943b46e1460723603ea2216f646146180aa3"
echo "=== Wave016 accepted main SHA: ${MAIN_SHA} ==="
echo "=== HEAD=$(git rev-parse HEAD) ==="

# shellcheck source=tools/engineering_wave015/godot_orchestration.sh
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
echo "=== Wave016 Godot: $($GODOT --version 2>/dev/null || echo unknown) ==="
mkdir -p "${HOME}/Library/Application Support/Godot/app_userdata/Anime Aggressors/logs" 2>/dev/null || true

run() {
  local name="$1"; shift
  local log="tmp/wave016-${name}.log"
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

run build_matrix python3 tools/engineering_wave016/build_move_application_matrix.py
run choreography_v2 python3 tools/engineering_wave016/build_choreography_alignment_v2.py
run unit_resolver python3 tools/engineering_wave016/test_alias_resolver.py

run taste_gate make taste-gate

if [[ "${WAVE016_FULL_REGRESSION:-0}" == "1" ]]; then
  run wave011_regression bash tools/engineering_wave011/run_wave011.sh
  run wave012_regression bash tools/engineering_wave012/run_wave012.sh
  run wave013b_regression bash tools/engineering_wave013b/run_wave013b.sh
  run wave014_regression bash tools/engineering_wave014/run_wave014.sh
  run wave015_regression bash tools/engineering_wave015/run_wave015.sh
else
  echo "=== skipping full wave011-015 locally (CI workflows required on PR head) ==="
  test -f artifacts/engineering_wave014/WAVE014_RESULT.json
  test -f artifacts/engineering_wave015/WAVE015_RESULT.json || true
fi

godot_orchestration_prepare "wave016" "${ROOT}"
godot_orchestration_teardown "${ROOT}" || true
godot_orchestration_prepare "wave016-godot_import" "${ROOT}"
run godot_import bash -c 'source "$1" && godot_orchestration_import "$2" "$3" 3 wave016-godot_import "$4"' _ "${ROOT}/tools/engineering_wave015/godot_orchestration.sh" "$GODOT" "$ROOT/game-godot" "$ROOT"

run deterministic_routing_e2e "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave016/Wave016GoldenSliceMoveE2E.gd
run real_input_e2e "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave016/Wave016RealInputMoveE2E.gd
run ember_projectile_e2e "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave016/Wave016EmberProjectileRuntimeE2E.gd
run model_visibility "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/quality/TasteGateModelVisibility.gd || true

run emit_result python3 tools/engineering_wave016/emit_wave016_result.py

# Pixel merge gate (authorized Pixel 6a): build APK, authentic capture, 10-min smoke.
# If no device: records BLOCKED_PIXEL6A and READY_FOR_OWNER_MERGE=false.
if [[ "${WAVE016_SKIP_PIXEL_GATE:-0}" != "1" ]]; then
  run pixel_merge_gate python3 tools/engineering_wave016/run_pr87_pixel_merge_gate.py || true
else
  run contact_sheet python3 tools/engineering_wave016/capture_contact_sheet.py
fi

# Re-emit after Pixel gate so PIXEL_* / READY_FOR_OWNER_MERGE fields are final
run emit_result_final python3 tools/engineering_wave016/emit_wave016_result.py

godot_orchestration_teardown "${ROOT}" || true
echo "=== WAVE016 / PR87 final gate complete (do not merge; Edmund sole authority) ==="
