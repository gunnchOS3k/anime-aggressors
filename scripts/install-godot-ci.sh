#!/usr/bin/env bash
# Install Godot editor binary for CI (Linux x86_64).
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.3}"
INSTALL_DIR="${RUNNER_TOOL_CACHE:-/tmp}/godot"
GODOT_BIN="${INSTALL_DIR}/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
ZIP_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"

if [ -x "${GODOT_BIN}" ]; then
  echo "Godot already installed at ${GODOT_BIN}"
else
  mkdir -p "${INSTALL_DIR}"
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT
  echo "Downloading Godot ${GODOT_VERSION} for Linux..."
  curl -fsSL "${ZIP_URL}" -o "${TMP}/godot.zip"
  unzip -q "${TMP}/godot.zip" -d "${INSTALL_DIR}"
  chmod +x "${GODOT_BIN}"
fi

echo "GODOT_BIN=${GODOT_BIN}" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || export GODOT_BIN="${GODOT_BIN}"
echo "${GODOT_BIN}"
