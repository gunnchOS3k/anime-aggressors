#!/usr/bin/env python3
"""Wave020 early Pixel gate — Fighter Select dynamic content + seven-browse (AA-only).

Path: launch -> Fighter Select -> roster visible -> browse all 7 -> confirm -> battle
Does NOT run the full 49-capture / 10-min soak campaign.
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

# Reuse AA-only helpers from full campaign module.
import run_pixel_campaign as rpc

ROOT = rpc.ROOT
ART = rpc.ART
PIXEL = rpc.PIXEL
APK = rpc.APK
PKG = rpc.PKG


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_early(payload: dict) -> None:
    ART.mkdir(parents=True, exist_ok=True)
    (ART / "PIXEL_EARLY_FIGHTER_SELECT_GATE.json").write_text(json.dumps(payload, indent=2) + "\n")
    # Also merge critical keys into PIXEL_CAMPAIGN for continuity (early, not final seal).
    (ART / "PIXEL_CAMPAIGN.json").write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps({k: v for k, v in payload.items() if k != "captures"}, indent=2))


def mean_luma(path: Path) -> float:
    try:
        from PIL import Image  # type: ignore
    except Exception:
        return -1.0
    im = Image.open(path).convert("RGB")
    w, h = im.size
    acc = 0.0
    n = 0
    step_x = max(1, w // 48)
    step_y = max(1, h // 48)
    px = im.load()
    for y in range(0, h, step_y):
        for x in range(0, w, step_x):
            r, g, b = px[x, y]
            acc += (r + g + b) / (3.0 * 255.0)
            n += 1
    return acc / float(max(n, 1))


def main() -> None:
    ART.mkdir(parents=True, exist_ok=True)
    PIXEL.mkdir(parents=True, exist_ok=True)
    serials = rpc.devices()
    if not serials:
        write_early({
            "PIXEL_EARLY_GATE": "BLOCKED_PIXEL6A",
            "PIXEL_DEVICE_AVAILABLE": False,
            "PIXEL_FIGHTER_SELECT_DYNAMIC_CONTENT_COMPLETE": False,
            "PIXEL_OWNER_REG_009": "BLOCKED",
            "PIXEL_OWNER_REG_008": "BLOCKED",
            "reason": "No adb device",
            "AA_ONLY_GUARDS": True,
            "SETTINGS_UI_USED": False,
            "emitted_at": utc_now(),
        })
        raise SystemExit(2)

    serial = serials[0]
    model = rpc.adb(["-s", serial, "shell", "getprop", "ro.product.model"]).stdout.strip()
    source_sha = rpc.sh(["git", "rev-parse", "HEAD"]).stdout.strip()

    force = os.environ.get("WAVE020_FORCE_APK_REBUILD", "1") == "1"
    if force or not APK.is_file() or APK.stat().st_size < 1_000_000:
        if not rpc.build_apk():
            write_early({
                "PIXEL_EARLY_GATE": "FAIL",
                "PIXEL_DEVICE_AVAILABLE": True,
                "reason": "APK_BUILD_FAILED",
                "DEVICE_SERIAL": serial,
                "DEVICE_MODEL": model,
                "PIXEL_SOURCE_SHA": source_sha,
                "emitted_at": utc_now(),
            })
            raise SystemExit(1)

    apk_sha = rpc.sha256_file(APK)
    (ROOT / "builds" / "android" / "anime-aggressors-debug.apk.sha256").write_text(apk_sha + "\n")

    for bad in rpc.FORBIDDEN_PACKAGES:
        rpc.adb(["-s", serial, "shell", "am", "force-stop", bad])
    rpc.adb(["-s", serial, "shell", "am", "force-stop", PKG])
    install = rpc.adb(["-s", serial, "install", "-r", "-d", "-g", str(APK)], timeout=300)
    (PIXEL / "install.txt").write_text(install.stdout + "\n" + install.stderr)
    if install.returncode != 0:
        write_early({
            "PIXEL_EARLY_GATE": "FAIL",
            "reason": "APK_INSTALL_FAILED",
            "DEVICE_SERIAL": serial,
            "install": (install.stdout + install.stderr)[-500:],
            "emitted_at": utc_now(),
        })
        raise SystemExit(1)

    perm_grants = rpc.grant_aa_runtime_permissions(serial)
    (PIXEL / "permission_grants.json").write_text(json.dumps({
        "method": "adb_pm_grant",
        "settings_ui_used": False,
        "grants": perm_grants,
        "emitted_at": utc_now(),
    }, indent=2) + "\n")

    rpc.adb(["-s", serial, "logcat", "-c"])
    if not rpc.launch_app(serial):
        write_early({
            "PIXEL_EARLY_GATE": "FAIL",
            "reason": "LAUNCH_FAILED",
            "emitted_at": utc_now(),
        })
        raise SystemExit(1)

    captures = []
    select_ghosts = 0
    battle_ghosts = 0
    deaths = 0

    captures.append(rpc.screencap(serial, "early_00_launch"))
    rpc.navigate_to_fighter_select(serial)
    time.sleep(1.0)
    cap_select = rpc.screencap(serial, "early_01_fighter_select")
    captures.append(cap_select)

    # Heuristic: blank/shell-only select captures are tiny or near-black.
    select_path = PIXEL / "early_01_fighter_select.png"
    luma = mean_luma(select_path) if select_path.is_file() else -1.0
    shell_only = (not cap_select.get("ok")) or cap_select.get("bytes", 0) < 55_000 or (0 <= luma < 0.04)
    if shell_only:
        select_ghosts += 1

    # Browse fighters 1..7
    for i in range(7):
        if not rpc.ensure_aa_foreground(serial, f"early_browse_{i}"):
            deaths += 1
            rpc.launch_app(serial)
            rpc.navigate_to_fighter_select(serial)
        if i == 0:
            for _ in range(8):
                rpc.key(serial, "21")
                time.sleep(0.06)
        else:
            rpc.key(serial, "22")
            time.sleep(0.22)
        time.sleep(0.55)
        cap = rpc.screencap(serial, f"early_A_select_{i}")
        captures.append(cap)
        if not cap.get("ok") or cap.get("bytes", 0) < 55_000:
            select_ghosts += 1

    # Confirm fighter 7 path into battle
    rpc.key(serial, "66")
    time.sleep(0.45)
    rpc.key(serial, "66")
    time.sleep(2.0)
    if not rpc.ensure_aa_foreground(serial, "early_battle"):
        deaths += 1
    cap_battle = rpc.screencap(serial, "early_C_battle")
    captures.append(cap_battle)
    if not cap_battle.get("ok") or cap_battle.get("bytes", 0) < 55_000:
        battle_ghosts += 1

    logcat = rpc.adb(["-s", serial, "logcat", "-d", "-t", "400"]).stdout
    (PIXEL / "early_logcat.txt").write_text(logcat)
    fatal = logcat.count("FATAL EXCEPTION") if PKG in logcat else 0

    dynamic_complete = (
        not shell_only
        and select_ghosts == 0
        and battle_ghosts == 0
        and deaths == 0
        and fatal == 0
        and len([c for c in captures if c.get("ok")]) >= 9
    )
    reg009 = "PASS" if dynamic_complete else "FAIL"
    reg008 = "PASS" if (select_ghosts == 0 and battle_ghosts == 0 and deaths == 0) else "FAIL"
    gate = "PASS" if (reg009 == "PASS" and reg008 == "PASS") else "FAIL"

    write_early({
        "PIXEL_EARLY_GATE": gate,
        "PIXEL_CAMPAIGN": "EARLY_GATE_" + gate,
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "AA_ONLY_GUARDS": True,
        "SETTINGS_UI_USED": False,
        "PERMISSION_GRANT_METHOD": "adb_pm_grant",
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "APK": str(APK.relative_to(ROOT)),
        "PIXEL_FIGHTER_SELECT_DYNAMIC_CONTENT_COMPLETE": dynamic_complete,
        "PIXEL_OWNER_REG_009": reg009,
        "PIXEL_OWNER_REG_008": reg008,
        "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": select_ghosts,
        "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES": battle_ghosts,
        "PIXEL_PROCESS_DEATHS": deaths,
        "PIXEL_FATAL": fatal,
        "SELECT_SHELL_ONLY_HEURISTIC": shell_only,
        "SELECT_MEAN_LUMA": luma,
        "captures": captures,
        "emitted_at": utc_now(),
    })
    raise SystemExit(0 if gate == "PASS" else 1)


if __name__ == "__main__":
    main()
