#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/game-godot"
GODOT="${GODOT:-godot}"
GODOT_ARGS=(--headless --rendering-driver opengl3 --path .)
echo "[vxp2] import / editor sync"
"$GODOT" "${GODOT_ARGS[@]}" --import >/tmp/vxp2_import.log 2>&1 || true
echo "[vxp2] structural asserts"
"$GODOT" "${GODOT_ARGS[@]}" -s res://tests/vxp2/vxp2_structural_asserts.gd
