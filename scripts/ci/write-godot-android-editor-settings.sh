#!/usr/bin/env bash
# Write Godot 4.5 editor settings for headless Android export on CI.
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.5}"
ANDROID_SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
JAVA_HOME_PATH="${JAVA_HOME:-}"

if [[ -z "${ANDROID_SDK}" || ! -d "${ANDROID_SDK}" ]]; then
  echo "ANDROID_SDK_ROOT/ANDROID_HOME required" >&2
  exit 1
fi
if [[ -z "${JAVA_HOME_PATH}" || ! -x "${JAVA_HOME_PATH}/bin/java" ]]; then
  echo "JAVA_HOME (JDK 17) required" >&2
  exit 1
fi

CONFIG_DIR="${HOME}/.config/godot"
mkdir -p "${CONFIG_DIR}"
SETTINGS="${CONFIG_DIR}/editor_settings-${GODOT_VERSION}.tres"

cat > "${SETTINGS}" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "${ANDROID_SDK}"
export/android/java_sdk_path = "${JAVA_HOME_PATH}"
EOF

echo "Wrote ${SETTINGS}"
echo "android_sdk=${ANDROID_SDK}"
echo "java_sdk=${JAVA_HOME_PATH}"
