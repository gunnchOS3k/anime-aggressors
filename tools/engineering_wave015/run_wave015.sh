#!/usr/bin/env bash
# make engineering-wave015
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/engineering_wave015 artifacts/engineering_wave015/crash_census tmp

# shellcheck source=tools/engineering_wave015/godot_orchestration.sh
source "${ROOT}/tools/engineering_wave015/godot_orchestration.sh"
export GODOT_ORCH_ROOT="${ROOT}"

MANUAL_RESCUE_STEPS_REQUIRED=false
MAKE_ENGINEERING_WAVE015_MONOLITHIC_PASS=false

echo "=== Wave015 HEAD=$(git rev-parse HEAD) ==="
echo "=== ANIME_ACCEPTED_MAIN_SHA=706aba63274c9b563dfc34e76502d78a7cac19a9 ==="
echo "=== FIELD_KIT_ACCEPTED_MAIN_SHA=9e93e41a3b16b009c9cc5163b775360d4d2ef693 ==="

run_prereq_wave() {
  local wave="$1"
  local script="$2"
  godot_orchestration_teardown "${ROOT}"
  godot_orchestration_prepare "wave015-${wave}" "${ROOT}"
  echo "=== prerequisite ${wave} ==="
  bash "${script}" >"tmp/wave015-${wave}.log" 2>&1
  echo "PASS prerequisite ${wave}"
}

run_prereq_wave wave011 tools/engineering_wave011/run_wave011.sh
run_prereq_wave wave012 tools/engineering_wave012/run_wave012.sh
run_prereq_wave wave013b tools/engineering_wave013b/run_wave013b.sh
run_prereq_wave wave014 tools/engineering_wave014/run_wave014.sh

MAKE_ENGINEERING_WAVE015_MONOLITHIC_PASS=true
python3 - <<'PY'
import json
from datetime import datetime, timezone
from pathlib import Path
root = Path(".")
payload = {
    "schema": "engineering_wave015.monolithic_pass.v1",
    "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "MAKE_ENGINEERING_WAVE015_MONOLITHIC_PASS": True,
    "MANUAL_RESCUE_STEPS_REQUIRED": False,
    "waves": {
        "WAVE011": "PASS",
        "WAVE012": "PASS",
        "WAVE013B": "PASS",
        "WAVE014": "PASS",
    },
}
dest = root / "artifacts/engineering_wave015/MONOLITHIC_PASS.json"
dest.parent.mkdir(parents=True, exist_ok=True)
dest.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(json.dumps(payload, indent=2))
PY

# Non-physical / local gate path: cluster existing census logs if present; do not claim phone attached.
python3 tools/engineering_wave015/cluster_crashes.py || true
python3 tools/engineering_wave015/emit_wave015_result.py

# Physical crash census is opt-in (real Pixel 6a via ADB). CI must not pretend a phone was attached.
if [[ "${WAVE015_RUN_PHYSICAL_CENSUS:-0}" == "1" ]]; then
  python3 tools/engineering_wave015/run_crash_census.py --stages "${WAVE015_CENSUS_STAGES:-ABCD}" --phase "${WAVE015_CENSUS_PHASE:-baseline}"
  python3 tools/engineering_wave015/emit_wave015_result.py
elif [[ "${WAVE015_RUN_PHYSICAL:-0}" == "1" ]]; then
  python3 tools/engineering_wave015/run_physical_pixel6a.py
  python3 tools/engineering_wave015/emit_wave015_result.py
fi

echo "MAKE_ENGINEERING_WAVE015_MONOLITHIC_PASS=${MAKE_ENGINEERING_WAVE015_MONOLITHIC_PASS}"
echo "MANUAL_RESCUE_STEPS_REQUIRED=${MANUAL_RESCUE_STEPS_REQUIRED}"
