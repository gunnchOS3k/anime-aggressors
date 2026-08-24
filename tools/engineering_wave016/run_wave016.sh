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
  # Prefer 4.5 for Wave016 headless stability on macOS (4.7 logger crash observed).
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
  echo "PASS ${name}"
}

run build_matrix python3 tools/engineering_wave016/build_move_application_matrix.py
run unit_resolver python3 tools/engineering_wave016/test_alias_resolver.py

# Taste gate (Golden Slice scoped)
run taste_gate make taste-gate

# Optional heavy regressions when WAVE016_FULL_REGRESSION=1
if [[ "${WAVE016_FULL_REGRESSION:-0}" == "1" ]]; then
  run wave011_regression bash tools/engineering_wave011/run_wave011.sh
  run wave012_regression bash tools/engineering_wave012/run_wave012.sh
  run wave013b_regression bash tools/engineering_wave013b/run_wave013b.sh
  run wave014_regression bash tools/engineering_wave014/run_wave014.sh
  run wave015_regression bash tools/engineering_wave015/run_wave015.sh
else
  echo "=== skipping full wave011-015 (set WAVE016_FULL_REGRESSION=1) ==="
  # Lightweight integrity: alias map + prior result tokens present
  test -f artifacts/engineering_wave014/WAVE014_RESULT.json
  test -f artifacts/engineering_wave015/WAVE015_RESULT.json || true
fi

godot_orchestration_prepare "wave016" "${ROOT}"
godot_orchestration_teardown "${ROOT}" || true
godot_orchestration_prepare "wave016-godot_import" "${ROOT}"
run godot_import bash -c 'source "$1" && godot_orchestration_import "$2" "$3" 3 wave016-godot_import "$4"' _ "${ROOT}/tools/engineering_wave015/godot_orchestration.sh" "$GODOT" "$ROOT/game-godot" "$ROOT"
run golden_slice_e2e "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave016/Wave016GoldenSliceMoveE2E.gd
run model_visibility "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/quality/TasteGateModelVisibility.gd || true

run emit_result python3 tools/engineering_wave016/emit_wave016_result.py
run contact_sheet python3 tools/engineering_wave016/capture_contact_sheet.py

godot_orchestration_teardown "${ROOT}" || true
echo "=== WAVE016 complete (draft PR; do not merge) ==="
