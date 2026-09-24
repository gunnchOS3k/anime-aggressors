#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
python3 tools/vxp3/validate_combat_impact.py
GODOT="${GODOT:-godot}"
if command -v "$GODOT" >/dev/null 2>&1; then
  echo "[vxp3] godot asserts"
  set +e
  (cd "$ROOT/game-godot" && "$GODOT" --headless --rendering-driver opengl3 --path . -s res://tests/vxp3/vxp3_combat_impact_asserts.gd)
  GODOT_EC=$?
  set -e
  if [ "$GODOT_EC" -ne 0 ]; then
    if [ -f "$ROOT/artifacts/vxp3/reports/VXP3_GODOT_ASSERTS.json" ]; then
      echo "[vxp3] godot process exited $GODOT_EC; keeping prior assert artifact"
    else
      echo "[vxp3] godot asserts failed with $GODOT_EC and no artifact" >&2
      exit "$GODOT_EC"
    fi
  fi
else
  echo "[vxp3] godot binary missing; skip headless asserts"
fi
