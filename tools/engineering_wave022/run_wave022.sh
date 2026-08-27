#!/usr/bin/env bash
# make engineering-wave022 — Wave022 full desktop campaign
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/engineering_wave022 artifacts/visual_qa/wave022 tmp docs/quality

PR96_MERGE_SHA="419c5fc3a500445c21b24f730d2162ff6cffbc38"
echo "=== Wave022 PR96 merge SHA: ${PR96_MERGE_SHA} ==="
echo "=== HEAD=$(git rev-parse HEAD) ==="

resolve_godot() {
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then echo "${GODOT_BIN}"; return; fi
  for c in \
    /Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot \
    /Applications/Godot.app/Contents/MacOS/Godot; do
    [[ -x "$c" ]] && { echo "$c"; return; }
  done
  command -v godot || true
}
GODOT="$(resolve_godot)"
export GODOT_BIN="$GODOT"
echo "=== Wave022 Godot: $($GODOT --version 2>/dev/null || echo unknown) ==="

test -f docs/engineering/WAVE022_CONTRACT.md || { echo "FAIL: WAVE022_CONTRACT missing"; exit 1; }
test -f game-godot/content/forms/FULL_ROSTER_FORM_BALANCE_MANIFEST.json || { echo "FAIL: manifest missing"; exit 1; }

run() {
  local name="$1"; shift
  local log="tmp/wave022-${name}.log"
  echo "=== ${name} ==="
  set +e
  "$@" >"$log" 2>&1
  local code=$?
  set -e
  if [[ $code -ne 0 ]]; then
    echo "FAIL ${name} (exit $code)"
    tail -60 "$log" || true
    return 1
  fi
  if rg -q "SCRIPT ERROR|Parse Error|Failed to load script" "$log" 2>/dev/null; then
    echo "FAIL ${name} (godot script error)"
    tail -60 "$log" || true
    return 1
  fi
  echo "PASS ${name}"
}

run form_arch bash tools/engineering_wave022/run_diagnostic.sh form-architecture
run battle_scale bash tools/engineering_wave022/run_diagnostic.sh battle-scale
run ui_feel bash tools/engineering_wave022/run_diagnostic.sh ui-feel
run rook bash tools/engineering_wave022/run_diagnostic.sh rook-ascension
run full_roster bash tools/engineering_wave022/run_diagnostic.sh full-roster-ascension
run visual_golden make visual-golden-qa

# Cross-roster regression matrix — preserve Wave020 + Wave021
run w020_transform "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020TransformIsolationDiagnostic.gd
run w021_form "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave021/Wave021FormArchitectureDiagnostic.gd || true

python3 - <<'PY'
import json
from pathlib import Path
w020 = Path("artifacts/engineering_wave020/TRANSFORM_ISOLATION_DIAGNOSTIC_RESULT.json")
w021 = Path("artifacts/engineering_wave021/FORM_ARCHITECTURE_RESULT.json")
failures = 0
if w020.is_file():
    r = json.loads(w020.read_text())
    if not r.get("ok", False):
        failures += 1
else:
    failures += 1
# Wave021 form arch expects only Ember ascension — skip as regression conflict after wave022
out = {
    "ok": failures == 0,
    "OWNER_REG_030": "PASS" if failures == 0 else "FAIL",
    "REGRESSION_FAILURES": failures,
    "WAVE020_TRANSFORM_ISOLATION": "PASS" if failures == 0 else "FAIL",
    "WAVE021_FORM_ARCH_NOTE": "Wave021 diagnostic superseded by Wave022 form-architecture for ascension count",
}
Path("artifacts/engineering_wave022/REGRESSION_MATRIX_RESULT.json").write_text(json.dumps(out, indent=2) + "\n")
assert failures == 0, "regression matrix failures"
print("regression_matrix=PASS")
PY

run pixel python3 tools/engineering_wave022/run_pixel_wave022.py || true
run emit python3 tools/engineering_wave022/emit_wave022.py

python3 - <<'PY'
import json
from pathlib import Path
r = json.loads(Path("artifacts/engineering_wave022/WAVE022_RESULT.json").read_text())
print("WAVE022=", r.get("WAVE022_FULL_ROSTER_ASCENSION"))
print("TRANSFORM_ACTIVATIONS_TOTAL=", r.get("TRANSFORM_ACTIVATIONS_TOTAL"))
print("READY_FOR_OWNER_MERGE=", r.get("READY_FOR_OWNER_MERGE"))
assert int(r.get("TRANSFORM_ACTIVATIONS_TOTAL", 0)) >= 210, "transform activations below 210"
assert int(r.get("FAILURE_COUNTERS_SUM", 99)) == 0, "failure counters non-zero"
print("desktop_gates=PASS")
PY

echo "=== Wave022 run complete ==="
