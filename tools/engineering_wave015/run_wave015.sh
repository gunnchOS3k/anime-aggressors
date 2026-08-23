#!/usr/bin/env bash
# make engineering-wave015
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/engineering_wave015 artifacts/engineering_wave015/crash_census tmp

echo "=== Wave015 HEAD=$(git rev-parse HEAD) ==="
echo "=== ANIME_ACCEPTED_MAIN_SHA=706aba63274c9b563dfc34e76502d78a7cac19a9 ==="
echo "=== FIELD_KIT_ACCEPTED_MAIN_SHA=9e93e41a3b16b009c9cc5163b775360d4d2ef693 ==="

echo "=== prerequisite wave011 ==="
bash tools/engineering_wave011/run_wave011.sh >tmp/wave015-wave011.log 2>&1
echo "=== prerequisite wave012 ==="
bash tools/engineering_wave012/run_wave012.sh >tmp/wave015-wave012.log 2>&1
echo "=== prerequisite wave013b ==="
bash tools/engineering_wave013b/run_wave013b.sh >tmp/wave015-wave013b.log 2>&1
echo "=== prerequisite wave014 ==="
bash tools/engineering_wave014/run_wave014.sh >tmp/wave015-wave014.log 2>&1

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
