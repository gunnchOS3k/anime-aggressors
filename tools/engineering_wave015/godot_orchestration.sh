#!/usr/bin/env bash
# Shared Godot orchestration for long Wave015 monolithic chains.
# Isolates editor user data, ensures ADB is reachable, tears down stale processes.
set -euo pipefail

godot_orchestration_root() {
  if [[ -n "${GODOT_ORCH_ROOT:-}" ]]; then
    echo "${GODOT_ORCH_ROOT}"
    return 0
  fi
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  echo "${here}"
}

godot_orchestration_prepare() {
  local session="${1:-default}"
  local root="${2:-$(godot_orchestration_root)}"
  export GODOT_ORCH_ROOT="${root}"
  export WAVE015_GODOT_SESSION="${session}"
  export XDG_DATA_HOME="${root}/tmp/godot-xdg/${session}"
  export XDG_CACHE_HOME="${root}/tmp/godot-cache/${session}"
  export XDG_CONFIG_HOME="${root}/tmp/godot-config/${session}"
  mkdir -p "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}" "${XDG_CONFIG_HOME}"
  # Godot Android editor hooks probe adb; start server to avoid Abort trap on refused 5037.
  adb start-server >/dev/null 2>&1 || true
}

godot_orchestration_teardown() {
  local root="${1:-$(godot_orchestration_root)}"
  pkill -f "Godot.*${root}/game-godot" 2>/dev/null || true
  pkill -f "Godot.*--path.*game-godot" 2>/dev/null || true
  sleep 1
  rm -f "${root}/game-godot/.godot/editor/project_metadata.cfg.lock" 2>/dev/null || true
  rm -f "${root}/game-godot/.godot/editor/filesystem_cache10" 2>/dev/null || true
}

godot_orchestration_import() {
  local godot_bin="$1"
  local project_path="$2"
  local max_retries="${3:-3}"
  local log_name="${4:-godot_import}"
  local root="${5:-$(godot_orchestration_root)}"
  local log="${root}/tmp/${log_name}.log"
  local attempt=1
  local code=0

  mkdir -p "${root}/tmp"
  while (( attempt <= max_retries )); do
    godot_orchestration_prepare "${log_name}-try${attempt}" "${root}"
    adb start-server >/dev/null 2>&1 || true
    set +e
    "${godot_bin}" --headless --path "${project_path}" --import >"${log}" 2>&1
    code=$?
    set -e
    if [[ ${code} -eq 0 ]]; then
      echo "PASS ${log_name} (attempt ${attempt})"
      return 0
    fi
    if [[ ${code} -eq 134 || ${code} -eq 132 ]]; then
      echo "WARN ${log_name} transient abort (exit ${code}) attempt ${attempt}/${max_retries}" >&2
      godot_orchestration_teardown "${root}"
      sleep 2
      attempt=$((attempt + 1))
      continue
    fi
    echo "FAIL ${log_name} (exit ${code})" >&2
    tail -40 "${log}" >&2 || true
    return "${code}"
  done
  echo "FAIL ${log_name} after ${max_retries} transient retries" >&2
  tail -40 "${log}" >&2 || true
  return "${code}"
}
