#!/usr/bin/env bash
# make engineering-wave014
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/wave014 artifacts/engineering_wave014 tmp game-godot/artifacts/engineering_wave014

resolve_godot() {
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then echo "${GODOT_BIN}"; return; fi
  for c in /Applications/Godot.app/Contents/MacOS/Godot /Users/gunnchos/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot /opt/homebrew/bin/godot; do
    [[ -x "$c" ]] && { echo "$c"; return; }
  done
  command -v godot
}
GODOT="$(resolve_godot)"
export GODOT_BIN="$GODOT"
echo "=== Wave014 Godot: $($GODOT --version) ==="
echo "=== HEAD=$(git rev-parse HEAD) ==="
echo "=== WAVE013B_ACCEPTED_MAIN_SHA=2bebf3ce138aaaf6cc8d2b237a3d45aca3d11a80 ==="
echo "=== ANIME_WAVE014_START_SHA=2bebf3ce138aaaf6cc8d2b237a3d45aca3d11a80 ==="

run() {
  local name="$1"; shift
  local log="tmp/wave014-${name}.log"
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
echo "=== prerequisite wave013b ==="
run wave013b_regression bash tools/engineering_wave013b/run_wave013b.sh

run generate_characters python3 tools/art_pipeline/procedural_roster/generate_roster.py
run generate_animations python3 tools/animation_pipeline/procedural/generate_roster_animations.py
run silhouette_qa python3 tools/art_pipeline/procedural_roster/measure_silhouette_distinctness.py
run anim_distinctness python3 tools/animation_pipeline/qa/validate_runtime_animation_distinctness.py
run combat_alignment python3 tools/engineering_wave014/validate_combat_alignment.py
run synthetic_bvh python3 tools/engineering_wave014/run_synthetic_bvh_preview.py
run zero_cost python3 tools/art_pipeline/check_zero_cost_dependencies.py
cp artifacts/engineering_wave012/ZERO_COST_DEPENDENCY_CHECK.json artifacts/wave014/ZERO_COST_DEPENDENCY_CHECK.json 2>/dev/null || true
run quality_gates python3 tools/engineering_wave014/run_quality_gates.py
run renders python3 tools/engineering_wave014/generate_renders.py
run performance_smoke python3 tools/engineering_wave014/run_performance_smoke.py
run integrity bash tools/engineering_wave014/run_code_integrity.sh

for fighter in ember-vale rook-ironside juno-spark kaia-windrow nix-calder orion-vell vesper-nyx; do
  manifest="art_source/generated/procedural/${fighter}/character_manifest.json"
  if [[ -f "$manifest" ]]; then
    python3 - <<PY
import json
from pathlib import Path
m=json.loads(Path("${manifest}").read_text(encoding="utf-8"))
rig=m.get("rig", {})
Path("tmp/rig_${fighter}.json").write_text(json.dumps(rig, indent=2)+"\n", encoding="utf-8")
PY
    run "rig_${fighter}" python3 tools/art_pipeline/validate_character_rig.py "tmp/rig_${fighter}.json" --out "artifacts/engineering_wave014/rig_${fighter}.json"
  fi
done

run godot_import "$GODOT" --headless --path "$ROOT/game-godot" --import
run procedural_smoke "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave014/Wave014ProceduralSmoke.gd
run visible_skeletal "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave014/Wave014VisibleSkeletalRuntime.gd
run visible_game_juice "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave014/Wave014VisibleGameJuice.gd
run game_juice python3 tools/engineering_wave014/emit_game_juice_result.py
run runtime_renders "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave014/Wave014RuntimeRenders.gd
run battle_e2e "$GODOT" --headless --path "$ROOT/game-godot" --script res://tests/engineering_wave014/Wave014BattleSceneVisualE2E.gd
run sabotage python3 tools/engineering_wave014/run_sabotage_checks.py
python3 tools/engineering_wave014/emit_wave014_result.py

echo "=== Wave014 harness complete ==="
python3 - <<'PY'
import json
d=json.load(open("artifacts/engineering_wave014/WAVE014_RESULT.json"))
for k in ["ENGINEERING_WAVE_014","PROCEDURAL_CHARACTER_RUNTIME_PASS","PROCEDURAL_RUNTIME_ANIMATION_PASS","FINAL_CHARACTER_ART_PASS","HOST_PERFORMANCE_SMOKE_PASS","READY_FOR_OWNER_MERGE"]:
    print(f"{k}={d.get(k)}")
print("token=", d.get("token"))
PY
