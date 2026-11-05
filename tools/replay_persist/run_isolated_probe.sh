#!/bin/sh
# Headless private-match replay round-trip. Isolated project, no asset import.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
PROBE="$ROOT/tmp/replay_persist_probe"
USER_PARENT="$HOME/Library/Application Support/Godot/app_userdata"
PROBE_NAME="aa-replay-persist-probe"
PROBE_USER="$USER_PARENT/$PROBE_NAME"
OWNER_DIR="$USER_PARENT/Anime Aggressors"
OWNER_SAVE="$OWNER_DIR/aa_save.cfg"
OWNER_RULES="$OWNER_DIR/aa_rulesets.cfg"
OWNER_REPLAY="$OWNER_DIR/aa_private_match_replay.json"
OWNER_PASS="$OWNER_DIR/private_netplay_digital_pass.json"

if [ -e "$PROBE_USER" ]; then
  case "$PROBE_USER" in
    *"/Anime Aggressors"*) echo "refusing to remove owner user dir" >&2; exit 2 ;;
  esac
  rm -rf "$PROBE_USER"
fi
rm -rf "$PROBE"
mkdir -p "$PROBE/scripts/net" "$PROBE/tests"
cp "$ROOT"/game-godot/scripts/net/*.gd "$PROBE/scripts/net/"
cp "$ROOT/game-godot/tests/replay_persist_roundtrip.gd" "$PROBE/tests/replay_persist_roundtrip.gd"
cat > "$PROBE/project.godot" <<'EOF'
; Engine configuration file.
; Isolated replay-persist probe. No assets, no autoloads, no main scene.
config_version=5

[application]

config/name="aa-replay-persist-probe"
config/features=PackedStringArray("4.5")
EOF

stamp() {
  target=$1
  if [ -f "$target" ]; then
    stat -f '%m %z %N' "$target"
  else
    echo "ABSENT $target"
  fi
}

echo "OWNER_BEFORE_SAVE $(stamp "$OWNER_SAVE")"
echo "OWNER_BEFORE_RULES $(stamp "$OWNER_RULES")"
echo "OWNER_BEFORE_REPLAY $(stamp "$OWNER_REPLAY")"
echo "OWNER_BEFORE_PASS $(stamp "$OWNER_PASS")"
echo "DF_BEFORE"
df -h /

set +e
godot --headless --path "$PROBE" --audio-driver Dummy -s res://tests/replay_persist_roundtrip.gd > "$PROBE/probe.log" 2>&1
status=$?
set -e
cat "$PROBE/probe.log"
if grep -q "SCRIPT ERROR" "$PROBE/probe.log"; then
  echo "PROBE_PARSE_ERROR"
  status=1
fi

echo "OWNER_AFTER_SAVE $(stamp "$OWNER_SAVE")"
echo "OWNER_AFTER_RULES $(stamp "$OWNER_RULES")"
echo "OWNER_AFTER_REPLAY $(stamp "$OWNER_REPLAY")"
echo "OWNER_AFTER_PASS $(stamp "$OWNER_PASS")"
echo "DF_AFTER"
df -h /
echo "PROBE_BYTES"
du -sh "$PROBE" "$PROBE/.godot" 2>/dev/null || true
echo "PROBE_USER_BYTES"
du -sh "$PROBE_USER" 2>/dev/null || true
echo "PROBE_EXIT $status"
exit "$status"
