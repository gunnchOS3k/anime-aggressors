#!/usr/bin/env python3
"""Verify exact-head Android APK + emit ANDROID_BUILD_MANIFEST.json for CI upload."""
from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PACKAGE_ID = "com.gunnchos.animeaggressors"
APK_REL = Path("builds/android/anime-aggressors-debug.apk")
MIN_BYTES = 1_000_000  # debug APKs for this title are multi-MB; refuse empty stubs


def _run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT).strip()


def _which(name: str) -> str | None:
    from shutil import which

    return which(name)


def aapt_badging(apk: Path) -> dict[str, str]:
    aapt = _which("aapt") or _which("aapt2")
    out: dict[str, str] = {}
    if not aapt:
        return out
    try:
        text = _run([aapt, "dump", "badging", str(apk)])
    except Exception:
        # aapt2 uses different subcommand sometimes
        try:
            text = _run([aapt, "dump", "badging", str(apk)])
        except Exception as exc:
            out["aapt_error"] = str(exc)
            return out
    m = re.search(r"package: name='([^']+)'", text)
    if m:
        out["package"] = m.group(1)
    m = re.search(r"versionCode='([^']+)'", text)
    if m:
        out["versionCode"] = m.group(1)
    m = re.search(r"versionName='([^']+)'", text)
    if m:
        out["versionName"] = m.group(1)
    return out


def signer_digest(apk: Path) -> str:
    apksigner = _which("apksigner")
    if not apksigner:
        # try sdk build-tools
        sdk = os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME") or ""
        bt = Path(sdk) / "build-tools"
        if bt.is_dir():
            versions = sorted([p for p in bt.iterdir() if p.is_dir()], reverse=True)
            for v in versions:
                cand = v / "apksigner"
                if cand.is_file():
                    apksigner = str(cand)
                    break
    if not apksigner:
        return ""
    try:
        text = _run([apksigner, "verify", "--print-certs", str(apk)])
    except Exception:
        return ""
    m = re.search(r"SHA-256 digest:\s*([0-9a-fA-F:]+)", text)
    if not m:
        m = re.search(r"Signer #1 certificate SHA-256 digest:\s*([0-9a-fA-F]+)", text)
    return (m.group(1) if m else "").replace(":", "").lower()


def apk_embeds_sha(apk: Path, sha: str) -> bool:
    needle = sha.encode()
    with zipfile.ZipFile(apk) as zf:
        for name in zf.namelist():
            try:
                if needle in zf.read(name):
                    return True
            except Exception:
                continue
    return False


def main() -> int:
    apk = REPO / APK_REL
    expected_sha = (os.environ.get("GITHUB_SHA") or "").strip()
    if not expected_sha:
        expected_sha = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip()

    errors: list[str] = []
    if not apk.is_file():
        print(json.dumps({"ok": False, "error": f"missing {APK_REL}"}))
        return 1
    size = apk.stat().st_size
    if size < MIN_BYTES:
        errors.append(f"apk too small: {size} bytes")

    digest = hashlib.sha256(apk.read_bytes()).hexdigest()
    badging = aapt_badging(apk)
    if badging.get("package") and badging["package"] != PACKAGE_ID:
        errors.append(f"package_id={badging.get('package')}")
    embedded_ok = apk_embeds_sha(apk, expected_sha)
    if not embedded_ok:
        errors.append(f"embedded git_sha != {expected_sha}")

    identity_path = REPO / "game-godot/data/runtime/build_identity.json"
    identity = {}
    if identity_path.is_file():
        identity = json.loads(identity_path.read_text(encoding="utf-8"))
        if str(identity.get("git_sha", "")).lower() != expected_sha.lower():
            errors.append("stamped build_identity.json SHA mismatch")

    signer = signer_digest(apk)
    version_name = badging.get("versionName") or str(identity.get("version_name", ""))
    version_code = badging.get("versionCode") or str(identity.get("version_code", ""))

    manifest = {
        "schema": "anime_android_exact_head_manifest_v1",
        "git_sha": expected_sha,
        "git_short_sha": expected_sha[:12],
        "package_id": badging.get("package") or PACKAGE_ID,
        "version_name": version_name,
        "version_code": version_code,
        "artifact_file": APK_REL.name,
        "artifact_sha256": digest,
        "artifact_bytes": size,
        "godot_version": os.environ.get("GODOT_VERSION", "4.5"),
        "java_version": os.environ.get("JAVA_VERSION_LABEL", "17"),
        "android_sdk": os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME") or "",
        "build_type": "debug",
        "build_source": "github_actions" if os.environ.get("GITHUB_ACTIONS") == "true" else "local",
        "workflow_run_id": os.environ.get("GITHUB_RUN_ID", ""),
        "embedded_identity_verified": embedded_ok,
        "signer_cert_sha256": signer,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "errors": errors,
    }

    out_dir = REPO / "builds/android"
    out_dir.mkdir(parents=True, exist_ok=True)
    man_path = out_dir / "ANDROID_BUILD_MANIFEST.json"
    man_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))

    if errors or not embedded_ok:
        return 1
    if str(manifest["package_id"]) != PACKAGE_ID:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
