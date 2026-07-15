#!/usr/bin/env bash
# Signed Anime Aggressors release APK export with Godot .import resource workaround.
# Requires: GODOT_BIN, JAVA_HOME (JDK 17), ANDROID_SDK_ROOT, sourced passwords.env
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT_DIR="$ROOT/game-godot"
OUT="${1:-$ROOT/build/android/anime-aggressors-release.apk}"
PREPARE="$ROOT/scripts/android/prepare-release-signing.mjs"

fail() { echo "[export-release-apk] $*" >&2; exit 1; }

[[ -n "${GODOT_BIN:-}" ]] || fail "GODOT_BIN unset"
[[ -x "$GODOT_BIN" ]] || fail "GODOT_BIN not executable: $GODOT_BIN"
[[ -n "${JAVA_HOME:-}" ]] || fail "JAVA_HOME unset (need JDK 17)"
[[ -n "${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}" ]] || fail "ANDROID_SDK_ROOT / ANDROID_HOME unset"
[[ -n "${GUNNCHOS_KEYSTORE_DIR:-}" ]] || fail "GUNNCHOS_KEYSTORE_DIR unset — source passwords.env"
[[ -n "${ANIME_STORE_PASSWORD:-${ANIME_KEYSTORE_PASS:-}}" ]] || fail "ANIME_STORE_PASSWORD unset — source passwords.env"

export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"

cleanup_imports() {
  find "$GODOT_DIR/android/build/res" -name '*.import' -delete 2>/dev/null || true
}

restore() {
  node "$PREPARE" --app anime --restore >/dev/null 2>&1 || true
  kill "${WATCH_PID:-}" 2>/dev/null || true
}
trap restore EXIT

node "$PREPARE" --app anime --apply

# Godot may rewrite *.import beside launcher PNGs during Gradle resource merge.
(
  for _ in $(seq 1 240); do
    cleanup_imports
    sleep 0.5
  done
) &
WATCH_PID=$!

set +e
"$GODOT_BIN" --headless --path "$GODOT_DIR" --export-release Android "$OUT"
GODOT_RC=$?
set -e

kill "$WATCH_PID" 2>/dev/null || true
WATCH_PID=""
cleanup_imports

if [[ ! -f "$OUT" ]]; then
  echo "[export-release-apk] Godot exit=$GODOT_RC — trying gradle assembleStandardRelease after import cleanup"
  (
    cd "$GODOT_DIR/android/build"
    cleanup_imports
    ./gradlew assembleStandardRelease --no-daemon
  )
  APK_CAND="$(find "$GODOT_DIR/android/build" -path '*/apk/*/release/*.apk' | head -1 || true)"
  [[ -n "$APK_CAND" ]] || fail "APK not produced (Godot rc=$GODOT_RC)"
  cp -f "$APK_CAND" "$OUT"
fi

node "$PREPARE" --app anime --restore
trap - EXIT

SHA="$(shasum -a 256 "$OUT" | awk '{print $1}')"
echo "$SHA  $(basename "$OUT")" > "${OUT}.sha256"
echo "[export-release-apk] OK: $OUT"
echo "[export-release-apk] SHA-256: $SHA"
