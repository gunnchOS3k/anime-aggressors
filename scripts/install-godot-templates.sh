#!/usr/bin/env bash
# Install Godot export templates for CI/local export.
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.3}"
TPZ_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"

if [[ "$(uname -s)" == "Darwin" ]]; then
  TEMPLATE_DIR="${HOME}/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.stable"
else
  TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
fi

if [ -d "${TEMPLATE_DIR}" ] && ls "${TEMPLATE_DIR}"/web_* 1>/dev/null 2>&1; then
  echo "Export templates already present at ${TEMPLATE_DIR}"
  exit 0
fi

mkdir -p "${TEMPLATE_DIR}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "Downloading Godot ${GODOT_VERSION} export templates..."
curl -fsSL "${TPZ_URL}" -o "${TMP}/templates.tpz"
unzip -q "${TMP}/templates.tpz" -d "${TMP}/extracted"
cp -R "${TMP}/extracted/templates/"* "${TEMPLATE_DIR}/"
echo "Installed export templates to ${TEMPLATE_DIR}"
