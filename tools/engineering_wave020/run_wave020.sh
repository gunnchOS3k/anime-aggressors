#!/usr/bin/env bash
# make engineering-wave020
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/engineering_wave020 artifacts/wave020 tmp docs/engineering docs/quality

ACCEPTED_MAIN_SHA="c59211282b17630d4c1345650fe2f76c69e321ba"
echo "=== Wave020 accepted main SHA (PR90 merge): ${ACCEPTED_MAIN_SHA} ==="
echo "=== HEAD=$(git rev-parse HEAD) ==="

test -f docs/engineering/WAVE020_CONTRACT.md || { echo "FAIL: WAVE020_CONTRACT.md missing"; exit 1; }
test -f docs/quality/WAVE020_OWNER_REVIEW_PACKET.md || { echo "FAIL: owner review packet missing"; exit 1; }

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
echo "=== Wave020 Godot: $($GODOT --version 2>/dev/null || echo unknown) ==="

run() {
  local name="$1"; shift
  local log="tmp/wave020-${name}.log"
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
run audio_gen python3 tools/audio/generate_procedural_sfx.py

godot_orchestration_prepare "wave020" "${ROOT}" || true
run godot_import bash -c 'source "$1" && godot_orchestration_import "$2" "$3" 3 wave020-godot_import "$4"' _ "${ROOT}/tools/engineering_wave015/godot_orchestration.sh" "$GODOT" "$ROOT/game-godot" "$ROOT" || true

# Preserve wave016-019 regressions
run wave018_select "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave018/Wave018SelectPreviewStress.gd
run wave018_battle "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave018/Wave018BattleVisibilityInvariant.gd
run wave019_move_list "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave019/Wave019MoveListCatalogGate.gd

# Wave020 gates
run wave020_seven_browse "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020SevenBrowseVisibility.gd
run wave020_pause "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020PauseMoveList.gd
run wave020_audio "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave020/Wave020ElementalAudio.gd

if command -v adb >/dev/null 2>&1 && adb devices | rg -q "device$"; then
  # AA-only guards enforced in run_pixel_campaign.py (no monkey, no launcher taps)
  run pixel_campaign python3 tools/engineering_wave020/run_pixel_campaign.py || true
else
  echo "=== PIXEL6A unavailable — recording BLOCKED_PIXEL6A ==="
  python3 - <<'PY'
import json
from pathlib import Path
art = Path("artifacts/engineering_wave020")
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
  "PIXEL_AUDIO_SMOKE_FIGHTERS": 0,
  "PIXEL_AUDIO_RUNTIME_PASS": None,
  "reason": "No authorized Pixel 6a attached during Wave020 run",
}
(art / "PIXEL_CAMPAIGN.json").write_text(json.dumps(payload, indent=2) + "\n")
PY
fi

run emit python3 tools/engineering_wave020/emit_wave020.py

python3 - <<'PY'
import json
from pathlib import Path
r = json.loads(Path("artifacts/engineering_wave020/WAVE020_RESULT.json").read_text())
print("WAVE020=", r.get("WAVE020_CHARACTER_VISIBILITY_PAUSE_MOVELIST_ELEMENTAL_AUDIO"))
print("READY_FOR_OWNER_MERGE=", r.get("READY_FOR_OWNER_MERGE"))
assert r.get("FIGHTERS_WITH_DISTINCT_SILHOUETTES") == 7
assert r.get("NEW_S0") == 0
assert r.get("NEW_S1") == 0
print("desktop_gates=PASS")
PY

echo "=== Wave020 run complete ==="
