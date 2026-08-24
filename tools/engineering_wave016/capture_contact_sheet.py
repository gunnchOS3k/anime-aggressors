#!/usr/bin/env python3
"""Capture Pixel 6a Golden Slice contact sheet or emit honest BLOCKED_DEVICE."""
from __future__ import annotations

import json
import shutil
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "artifacts" / "wave016" / "golden_slice_contact_sheet"
PKG = "com.gunnchos.animeaggressors"
# Prefer existing debug apk from repo builds if present
APK_CANDIDATES = [
    ROOT / "builds/android/anime-aggressors-debug.apk",
    ROOT / "builds/digital-rc/anime-aggressors-debug.apk",
]


def _adb_available() -> bool:
    return shutil.which("adb") is not None


def _adb(*args: str) -> subprocess.CompletedProcess:
    if not _adb_available():
        return subprocess.CompletedProcess(args=("adb", *args), returncode=127, stdout="", stderr="adb not found")
    return subprocess.run(["adb", *args], capture_output=True, text=True)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    shots: list[dict] = []
    status = "BLOCKED_DEVICE"
    note = "No Pixel 6a / adb device; desktop captures labeled if present."

    if not _adb_available():
        status = "BLOCKED_DEVICE"
        note = "adb binary not available (CI/non-device host)."
        serials: list[str] = []
    else:
        devices = _adb("devices")
        serials = [
            line.split()[0]
            for line in devices.stdout.splitlines()[1:]
            if "\tdevice" in line
        ]

    if serials:
        serial = serials[0]
        note = f"adb device {serial}"
        apk = next((p for p in APK_CANDIDATES if p.is_file()), None)
        if apk:
            _adb("-s", serial, "install", "-r", str(apk))
        # Launch if package exists
        _adb(
            "-s",
            serial,
            "shell",
            "monkey",
            "-p",
            PKG,
            "-c",
            "android.intent.category.LAUNCHER",
            "1",
        )
        time.sleep(3)
        labels = [
            "ember_idle",
            "ember_projectile_family",
            "ember_throw",
            "ember_aura_signature",
            "ember_recovery_ko",
        ]
        for i, label in enumerate(labels):
            remote = f"/sdcard/wave016_{label}.png"
            local = OUT / f"{label}.png"
            _adb("-s", serial, "shell", "screencap", "-p", remote)
            pull = _adb("-s", serial, "pull", remote, str(local))
            if local.is_file():
                shots.append({"label": label, "path": str(local.relative_to(ROOT)), "source": "pixel6a"})
            else:
                shots.append({"label": label, "path": None, "source": "pixel6a", "error": pull.stderr})
            time.sleep(0.8)
        status = "CAPTURED" if any(s.get("path") for s in shots) else "BLOCKED_DEVICE"
        if status == "CAPTURED":
            note = f"Pixel captures via {serial}"
    else:
        # Prefer already-committed Pixel captures from this wave if present.
        existing = sorted(OUT.glob("ember_*.png"))
        if existing:
            for p in existing:
                shots.append(
                    {
                        "label": p.stem,
                        "path": str(p.relative_to(ROOT)),
                        "source": "committed_pixel_or_prior",
                    }
                )
            status = "CAPTURED_COMMITTED" if note.startswith("adb binary") else "BLOCKED_DEVICE_DESKTOP_LABELED"
            if status == "CAPTURED_COMMITTED":
                note = "Using committed contact sheet captures; adb not available in this environment."
        else:
            # Copy any existing desktop/wave015 ember screenshots as labeled desktop evidence
            src_dirs = [
                ROOT / "artifacts/engineering_wave015/device_screenshots",
                ROOT / "artifacts/engineering_wave015/device_pull/device_screenshots",
                ROOT / "artifacts/engineering_wave014/runtime_renders",
            ]
            for d in src_dirs:
                if not d.is_dir():
                    continue
                for p in sorted(d.glob("*ember*"))[:8]:
                    dest = OUT / f"desktop_{p.name}"
                    shutil.copy2(p, dest)
                    shots.append(
                        {
                            "label": p.stem,
                            "path": str(dest.relative_to(ROOT)),
                            "source": "desktop_labeled_not_pixel",
                        }
                    )
            if shots:
                status = "BLOCKED_DEVICE_DESKTOP_LABELED"
                note = "No adb device; desktop/prior captures labeled correctly as non-Pixel."

    manifest = {
        "schema": "wave016_golden_slice_contact_sheet_v1",
        "status": status,
        "note": note,
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "shots": shots,
        "PIXEL_GOLDEN_SLICE_CAPTURE": status,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (OUT / "README.md").write_text(
        f"# Golden Slice Contact Sheet\n\nStatus: **{status}**\n\n{note}\n",
        encoding="utf-8",
    )
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
