#!/usr/bin/env bash
# make engineering-wave021 — Wave021 full desktop campaign
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/engineering_wave021 artifacts/visual_qa/wave021 tmp docs/quality

PR95_MERGE_SHA="0d094349e2aa6a7bbb4e7cdec4694ab33e585593"
echo "=== Wave021 PR95 merge SHA: ${PR95_MERGE_SHA} ==="
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
echo "=== Wave021 Godot: $($GODOT --version 2>/dev/null || echo unknown) ==="

test -f docs/engineering/WAVE021_CONTRACT.md || { echo "FAIL: WAVE021_CONTRACT missing"; exit 1; }
test -f docs/art/CHARACTER_ART_DIRECTION_CONTRACT.md || { echo "FAIL: art contract missing"; exit 1; }

run() {
  local name="$1"; shift
  local log="tmp/wave021-${name}.log"
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

run art_direction python3 tools/engineering_wave021/check_art_direction.py
run form_arch bash tools/engineering_wave021/run_diagnostic.sh form-architecture
run aura_tiers bash tools/engineering_wave021/run_diagnostic.sh aura-tiers
run ember bash tools/engineering_wave021/run_diagnostic.sh ember-ascension
run battle_scale bash tools/engineering_wave021/run_diagnostic.sh battle-scale
run ui_feel bash tools/engineering_wave021/run_diagnostic.sh ui-feel
run visual_golden make visual-golden-qa

# Preserve Wave020 GoldenVisualQA v1 + presentation isolation regressions
run w020_transform "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020TransformIsolationDiagnostic.gd

run pixel python3 tools/engineering_wave021/run_pixel_wave021.py || true
run emit python3 tools/engineering_wave021/emit_wave021.py

python3 - <<'PY'
import json
from pathlib import Path
r = json.loads(Path("artifacts/engineering_wave021/WAVE021_RESULT.json").read_text())
print("WAVE021=", r.get("WAVE021_FACELESS_ASCENSION_UI_GOLDEN"))
print("TRANSFORM_ACTIVATIONS=", r.get("TRANSFORM_ACTIVATIONS"))
print("READY_FOR_OWNER_MERGE=", r.get("READY_FOR_OWNER_MERGE"))
assert int(r.get("TRANSFORM_ACTIVATIONS", 0)) >= 50, "transform activations below 50"
assert int(r.get("FAILURE_COUNTERS_SUM", 99)) == 0, "failure counters non-zero"
print("desktop_gates=PASS")
PY

echo "=== Wave021 run complete ==="
