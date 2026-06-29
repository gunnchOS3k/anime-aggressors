#!/usr/bin/env bash
# Install Godot editor binary for CI (Linux x86_64).
# Contract: print ONLY the final Godot binary path to stdout.
# All logs go to stderr so callers can safely capture stdout and write GODOT_BIN to $GITHUB_ENV.
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.3}"
INSTALL_DIR="${RUNNER_TOOL_CACHE:-/tmp}/godot"
GODOT_BIN="${INSTALL_DIR}/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
ZIP_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"

if [ -x "${GODOT_BIN}" ]; then
  echo "Godot already installed at ${GODOT_BIN}" >&2
else
  mkdir -p "${INSTALL_DIR}"
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT
  echo "Downloading Godot ${GODOT_VERSION} for Linux..." >&2
  curl -fsSL "${ZIP_URL}" -o "${TMP}/godot.zip"
  unzip -q "${TMP}/godot.zip" -d "${INSTALL_DIR}"
  chmod +x "${GODOT_BIN}"
fi

# Do not write to GITHUB_ENV here. The workflow is responsible for that.
printf '%s\n' "${GODOT_BIN}"
