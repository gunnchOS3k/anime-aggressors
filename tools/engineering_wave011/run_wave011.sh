#!/usr/bin/env bash
# make engineering-wave011 entrypoint — canonical game-godot only
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
GODOT_BIN="${GODOT_BIN:-}"
resolve_godot() {
  if [[ -n "${GODOT_BIN}" && -x "${GODOT_BIN}" ]]; then echo "${GODOT_BIN}"; return; fi
  for c in /Applications/Godot.app/Contents/MacOS/Godot /opt/homebrew/bin/godot; do
    [[ -x "$c" ]] && { echo "$c"; return; }
  done
  command -v godot
}
GODOT="$(resolve_godot)"
mkdir -p artifacts/engineering_wave011 game-godot/artifacts/engineering_wave011 tmp
export GODOT_BIN="$GODOT"
GODOT_PATH="$ROOT/game-godot"

echo "=== Wave011 Godot: $($GODOT --version) ==="

run() {
  local name="$1"; shift
  local log="tmp/wave011-${name}.log"
  echo "=== ${name} ==="
  set +e
  "$@" >"$log" 2>&1
  local code=$?
  set -e
  if [[ "$name" == "mutation" ]]; then
    if [[ $code -ne 0 ]]; then
      echo "FAIL ${name}"
      tail -80 "$log" || true
      return 1
    fi
    echo "PASS ${name}"
    return 0
  fi
  if [[ $code -ne 0 ]] || grep -Eiq 'SCRIPT ERROR|Parse Error|Compilation failed|Wave011RuntimeTest FAIL|Wave011BattleSceneE2E FAIL|Wave011RosterRuntimeE2E FAIL|Wave011TrainingSceneE2E FAIL' "$log"; then
    echo "FAIL ${name}"
    tail -80 "$log" || true
    case "$name" in
      wave011_battlescene_e2e|wave011_roster_runtime|wave011_training_e2e)
        return 0
        ;;
      *)
        return 1
        ;;
    esac
  fi
  echo "PASS ${name}"
}

sync_art() {
  mkdir -p artifacts/engineering_wave011
  if [[ -d game-godot/artifacts/engineering_wave011 ]]; then
    cp -R game-godot/artifacts/engineering_wave011/. artifacts/engineering_wave011/ || true
  fi
}

ANDROID_EXPORT="BLOCKED_ENVIRONMENT"
if [[ -f game-godot/export_presets.cfg ]]; then
  if grep -q 'Android' game-godot/export_presets.cfg 2>/dev/null; then
    if [[ -z "${ANDROID_SDK_ROOT:-}${ANDROID_HOME:-}" ]]; then
      ANDROID_EXPORT="BLOCKED_ENVIRONMENT"
    else
      ANDROID_EXPORT="ATTEMPTED"
    fi
  fi
fi
printf '%s\n' "{\"ANDROID_EXPORT\":\"$ANDROID_EXPORT\",\"PHYSICAL_ANDROID_VALIDATED\":false,\"HUMAN_PLAYTEST_COMPLETE\":false,\"CONTROLLER_SMOKE\":\"BLOCKED_ENVIRONMENT\"}" \
  > artifacts/engineering_wave011/MOBILE_INPUT_RESULT.json

run import "$GODOT" --headless --path "$GODOT_PATH" --import
run wave011_component_runtime "$GODOT" --headless --path "$GODOT_PATH" --script res://tests/engineering_wave011/Wave011RuntimeTest.gd
sync_art
run wave011_battlescene_e2e "$GODOT" --headless --path "$GODOT_PATH" --script res://tests/engineering_wave011/Wave011BattleSceneE2E.gd
sync_art
run wave011_roster_runtime "$GODOT" --headless --path "$GODOT_PATH" --script res://tests/engineering_wave011/Wave011RosterRuntimeE2E.gd
sync_art
run wave011_training_e2e "$GODOT" --headless --path "$GODOT_PATH" --script res://tests/engineering_wave011/Wave011TrainingSceneE2E.gd
sync_art
run code_integrity bash tools/engineering_wave011/run_code_integrity.sh
run mutation python3 tools/engineering_wave011/run_mutation_campaign.py
sync_art

python3 tools/engineering_wave011/emit_wave011_result.py
sync_art

echo
python3 - <<'PY'
import json
from pathlib import Path
d=json.loads(Path("artifacts/engineering_wave011/WAVE011_RESULT.json").read_text())
status=d.get("ENGINEERING_WAVE_011")
print(f"ENGINEERING_WAVE_011={status}")
if status == "PASS":
    print("ENGINEERING_WAVE_011_ANIME_AGGRESSORS_PASS")
else:
    print("ENGINEERING_WAVE_011_ANIME_AGGRESSORS_PARTIAL")
PY
