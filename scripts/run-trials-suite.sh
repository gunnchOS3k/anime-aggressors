#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT_BIN:-$(command -v godot || true)}"
if [[ -z "$GODOT" ]]; then echo "Godot CLI required"; exit 2; fi
OUT="$ROOT/artifacts/cursor_continuation/trials_of_convergence"
HOME_ISO="$OUT/home"
mkdir -p "$HOME_ISO/Library/Application Support/aa-native-cursor-trials/logs"
export HOME="$HOME_ISO"
SCRIPTS=(
  res://tests/integration/TrialsModeAuthority.gd
  res://tests/integration/ResonanceTrialDeterminism.gd
  res://tests/integration/FracturedAccordProgression.gd
  res://tests/integration/PrismWeaveDeterminism.gd
  res://tests/integration/RiftlineSeededWaves.gd
  res://tests/integration/EchoesGauntletLore.gd
  res://tests/integration/UnboundRulesetContract.gd
  res://tests/integration/TrialsRosamereEligibility.gd
  res://tests/integration/TrialsSharedCombatBridge.gd
  res://tests/integration/TrialsPartyLinkSeats.gd
  res://tests/integration/TrialsModePresentation.gd
  res://tests/integration/TrialsHitResolverDamageRatio.gd
  res://tests/integration/FlaglineFourBodyCombat.gd
  res://tests/integration/ColossusActorCollision.gd
  res://tests/integration/TrialsOrdinaryInputJourneys.gd
)
FAIL=0
cd "$ROOT/game-godot"
for s in "${SCRIPTS[@]}"; do
  name="$(basename "$s" .gd)"
  echo "==> $name"
  if "$GODOT" --headless --path . --rendering-driver opengl3 --script "$s" > "$OUT/${name}.log" 2>&1 \
    && grep -q " PASS " "$OUT/${name}.log" \
    && ! grep -qE "Compilation failed|Parse Error|Identifier \"BodyVariant\" not declared" "$OUT/${name}.log"; then
    tail -2 "$OUT/${name}.log" || true
  else
    echo "FAIL $name"
    tail -40 "$OUT/${name}.log" || true
    FAIL=1
  fi
done
python3 - <<PY
import json, time, pathlib
out = pathlib.Path("$OUT") / "TRIALS_SUITE_RESULT.json"
payload = {
  "suite": "trials_of_convergence",
  "unix": int(time.time()),
  "pass": $FAIL == 0,
  "scripts": 15,
  "HUMAN_ART_APPROVED": False,
  "RC2_READY": False,
  "V1_0_0_RELEASE_AUTHORIZED": False,
  "SHIPPING_ROLLBACK_ENABLED": False,
  "note": "Headless sim/journey smoke — not commercial V1 claim; Web CI ≠ native Trials",
}
out.write_text(json.dumps(payload, indent=2) + "\n")
print(out)
PY
exit "$FAIL"
