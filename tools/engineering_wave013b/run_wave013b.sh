#!/usr/bin/env bash
# make engineering-wave013b
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/wave013b artifacts/engineering_wave013b tmp game-godot/artifacts/engineering_wave013b

resolve_godot() {
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then echo "${GODOT_BIN}"; return; fi
  for c in /Applications/Godot.app/Contents/MacOS/Godot /Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot /opt/homebrew/bin/godot; do
    [[ -x "$c" ]] && { echo "$c"; return; }
  done
  command -v godot
}
GODOT="$(resolve_godot)"
export GODOT_BIN="$GODOT"
echo "=== Wave013B Godot: $($GODOT --version) ==="
echo "=== HEAD=$(git rev-parse HEAD) ==="

run() {
  local name="$1"; shift
  local log="tmp/wave013b-${name}.log"
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

echo "=== prerequisite wave011 ==="
run wave011_regression bash tools/engineering_wave011/run_wave011.sh

echo "=== prerequisite wave012 ==="
run wave012_regression bash tools/engineering_wave012/run_wave012.sh

run generate_content python3 tools/engineering_wave013b/generate_wave013b_content.py
run zero_cost python3 tools/art_pipeline/check_zero_cost_dependencies.py
cp artifacts/engineering_wave012/ZERO_COST_DEPENDENCY_CHECK.json artifacts/wave013b/ZERO_COST_DEPENDENCY_CHECK.json 2>/dev/null || true
run quality_gates python3 tools/engineering_wave013b/run_quality_gates.py
run motion_qa python3 tools/motion_pipeline/qa/run_motion_qa.py
run upload_ready python3 tools/motion_pipeline/user_upload/validate_upload.py
run normalize_ready python3 tools/motion_pipeline/user_upload/normalize_motion.py
run retarget_ready python3 tools/motion_pipeline/user_upload/retarget/retarget_to_canonical.py
run sabotage python3 tools/engineering_wave013b/run_sabotage_checks.py
run integrity bash tools/engineering_wave013b/run_code_integrity.sh
run godot_import "$GODOT" --headless --path "$ROOT/game-godot" --import
run motion_smoke "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave013b/Wave013bMotionSmoke.gd
python3 tools/engineering_wave013b/emit_wave013b_result.py

echo "=== Wave013B harness complete ==="
python3 - <<'PY'
import json
d=json.load(open("artifacts/engineering_wave013b/WAVE013B_RESULT.json"))
for k in ["ENGINEERING_WAVE_013B","NOTES_DRIVEN_CHOREOGRAPHY_ACTIVE","USER_MOTION_UPLOAD_PIPELINE_READY","REAL_USER_MOTION_LIBRARY_PRESENT","EDMUND_PERSONAL_MOTION_REQUIRED","ACTION_SPECS_TOTAL","PROTOTYPE_ANIMATICS_COUNT","READY_FOR_OWNER_MERGE","CURSOR_MERGED_NOTHING"]:
    print(f"{k}={d.get(k)}")
print("token=", d.get("token"))
PY
