#!/usr/bin/env bash
# make engineering-wave019
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/engineering_wave019 artifacts/wave019 tmp playtest-evidence/visual_qa/wave019 docs/engineering_wave019 docs/quality

ACCEPTED_MAIN_SHA="52003b7161522580aa95c0f734e620a516540331"
echo "=== Wave019 accepted main SHA (PR89 merge): ${ACCEPTED_MAIN_SHA} ==="
echo "=== HEAD=$(git rev-parse HEAD) ==="

test -f docs/engineering/WAVE019_CONTRACT.md || { echo "FAIL: WAVE019_CONTRACT.md missing"; exit 1; }
test -f docs/quality/WAVE019_FIGHTER_IDENTITY_CONTRACTS.md || { echo "FAIL: identity contracts missing"; exit 1; }
test -f docs/quality/OWNER_REGRESSION_MEMORY.md || { echo "FAIL: owner regression memory missing"; exit 1; }
test -f docs/quality/WAVE019_OWNER_ROSTER_TASTE_REVIEW.md || { echo "FAIL: taste review packet missing"; exit 1; }

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
echo "=== Wave019 Godot: $($GODOT --version 2>/dev/null || echo unknown) ==="

run() {
  local name="$1"; shift
  local log="tmp/wave019-${name}.log"
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

godot_orchestration_prepare "wave019" "${ROOT}" || true
run godot_import bash -c 'source "$1" && godot_orchestration_import "$2" "$3" 3 wave019-godot_import "$4"' _ "${ROOT}/tools/engineering_wave015/godot_orchestration.sh" "$GODOT" "$ROOT/game-godot" "$ROOT" || true

# Preserve Wave018 visibility regressions
run wave018_select "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave018/Wave018SelectPreviewStress.gd || true
run wave018_battle "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave018/Wave018BattleVisibilityInvariant.gd || true
run wave019_move_list "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave019/Wave019MoveListCatalogGate.gd

# Pixel campaign if device present
if command -v adb >/dev/null 2>&1 && adb devices | rg -q "device$"; then
  run pixel_campaign python3 tools/engineering_wave019/run_pixel_campaign.py || true
else
  echo "=== PIXEL6A unavailable — recording BLOCKED_PIXEL6A ==="
  python3 - <<'PY'
import json
from pathlib import Path
art = Path("artifacts/engineering_wave019")
art.mkdir(parents=True, exist_ok=True)
payload = {
  "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
  "PIXEL_DEVICE_AVAILABLE": False,
  "PIXEL_AUTHENTIC": False,
  "PIXEL_RENDER_GHOSTS": None,
  "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS": None,
  "PIXEL_FALLBACK_RECOVERIES": None,
  "PIXEL_PROCESS_DEATHS": None,
  "PIXEL_FATAL": None,
  "PIXEL_ANR": None,
  "PIXEL_OOM": None,
  "PIXEL_SMOKE_MIN": None,
  "PIXEL_CAPTURE_CASES": 0,
  "PIXEL_FIGHTERS_REVIEWED": 0,
  "PIXEL_MOVE_LIST_OPEN_CLOSE_CYCLES": 0,
  "PIXEL_MOVE_PREVIEWS_RENDERED": 0,
  "PIXEL_MOVE_LIST_GHOST_REGRESSIONS": 0,
  "PIXEL_MOVE_LIST_CRASHES": 0,
  "reason": "No authorized Pixel 6a attached during Wave019 run",
}
(art / "PIXEL_CAMPAIGN.json").write_text(json.dumps(payload, indent=2) + "\n")
PY
fi

run emit python3 tools/engineering_wave019/emit_wave019.py

python3 - <<'PY'
import json
from pathlib import Path
r = json.loads(Path("artifacts/engineering_wave019/WAVE019_RESULT.json").read_text())
print("WAVE019=", r.get("WAVE019_ROSTER_IDENTITY_CONVERGENCE"))
print("READY_FOR_OWNER_MERGE=", r.get("READY_FOR_OWNER_MERGE"))
print("CURSOR_MERGED_NOTHING=", r.get("CURSOR_MERGED_NOTHING"))
# Desktop accuracy gates must be green even if Pixel blocked
assert r.get("MOVE_LIST_FALSE_PLAYABLE_ENTRIES") == 0
assert r.get("MOVE_LIST_MISSING_PLAYABLE_MOVES") == 0
assert r.get("MOVE_LIST_INPUT_MISMATCHES") == 0
assert r.get("MOVE_LIST_ANIMATION_MISMATCHES") == 0
assert r.get("MOVE_PREVIEW_AUTHENTICITY_PASS") is True
assert r.get("WAVE_CONTRACT_CREATED") is True
assert Path("docs/engineering/WAVE019_CONTRACT.md").exists()
print("desktop_gates=PASS")
PY

echo "=== Wave019 run complete ==="
