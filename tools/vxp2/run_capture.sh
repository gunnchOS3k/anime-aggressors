#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/game-godot"
GODOT="${GODOT:-godot}"
GODOT_ARGS=(--headless --rendering-driver opengl3 --path .)
mkdir -p "$ROOT/artifacts/vxp2/after" "$ROOT/artifacts/vxp2/manifests" "$ROOT/artifacts/vxp2/capture"
"$GODOT" "${GODOT_ARGS[@]}" --import >/tmp/vxp2_capture_import.log 2>&1 || true
set +e
"$GODOT" "${GODOT_ARGS[@]}" -s res://scripts/vxp2/vxp2_capture_harness.gd
CODE=$?
set -e
echo "[vxp2] capture exit=$CODE"
exit $CODE

# Fallback / primary fixture evidence when framebuffer readback is unavailable.
python3 "$ROOT/tools/vxp2/compose_fixture_evidence.py"
