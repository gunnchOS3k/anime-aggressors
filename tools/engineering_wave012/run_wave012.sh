#!/usr/bin/env bash
# make engineering-wave012
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/wave012 artifacts/engineering_wave012 tmp game-godot/artifacts/engineering_wave012

resolve_godot() {
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then echo "${GODOT_BIN}"; return; fi
  for c in /Applications/Godot.app/Contents/MacOS/Godot /Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot /opt/homebrew/bin/godot; do
    [[ -x "$c" ]] && { echo "$c"; return; }
  done
  command -v godot
}
GODOT="$(resolve_godot)"
export GODOT_BIN="$GODOT"
echo "=== Wave012 Godot: $($GODOT --version) ==="
echo "=== HEAD=$(git rev-parse HEAD) ==="

run() {
  local name="$1"; shift
  local log="tmp/wave012-${name}.log"
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

run mocap_env python3 tools/art_pipeline/mocap/check_environment.py
run zero_cost python3 tools/art_pipeline/check_zero_cost_dependencies.py
run provenance python3 tools/art_pipeline/validate_toolchain_provenance.py

cat > artifacts/wave012/canonical_rig_fixture.json <<'EOF'
{
  "normalized": true,
  "bones": ["Root","Hips","Spine","Chest","Neck","Head","Shoulder_L","UpperArm_L","LowerArm_L","Hand_L","Shoulder_R","UpperArm_R","LowerArm_R","Hand_R","UpperLeg_L","LowerLeg_L","Foot_L","Toes_L","UpperLeg_R","LowerLeg_R","Foot_R","Toes_R"],
  "sockets": ["hand_l","hand_r","foot_l","foot_r","chest","head","back","projectile_origin","aura_root"]
}
EOF
run rig_validate python3 tools/art_pipeline/validate_character_rig.py artifacts/wave012/canonical_rig_fixture.json --out artifacts/wave012/RIG_VALIDATE.json

if [[ -x /Applications/Blender.app/Contents/MacOS/Blender ]]; then
  run blender_smoke python3 tools/art_pipeline/blender/run_blender_smoke.py || true
else
  echo "SKIP blender_smoke"
fi

set +e
python3 tools/art_pipeline/anycreature_adapter/run_calibration.py >tmp/wave012-anycreature.log 2>&1
echo "anycreature_adapter exit=$?"
tail -40 tmp/wave012-anycreature.log || true
set -e

run quality_gates python3 tools/art_pipeline/quality/run_quality_gates.py
run godot_import "$GODOT" --headless --path "$ROOT/game-godot" --import
run juice_smoke "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave012/Wave012JuiceSmoke.gd
run integrity bash tools/engineering_wave012/run_code_integrity.sh
python3 tools/engineering_wave012/emit_wave012_result.py

echo "=== Wave012 harness complete ==="
python3 - <<'PY'
import json
d=json.load(open("artifacts/engineering_wave012/WAVE012_RESULT.json"))
for k in ["ENGINEERING_WAVE_012","PIPELINE_IMPLEMENTATION_PASS","EMBER_DIGITAL_PREPARATION_PASS","EMBER_FINAL_ART_RUNTIME_PASS","SEVEN_FIGHTER_AUTHORING_PACKETS_PASS","MOCAP_GPU_EXECUTION","VROID_MODEL_CREATION","READY_FOR_OWNER_MERGE","CURSOR_MERGED_NOTHING"]:
    print(f"{k}={d.get(k)}")
print("blockers=", d.get("blockers"))
PY
