#!/usr/bin/env python3
"""WAVE020 CP2 reopen — Vesper vs Kaia first failure Pixel screen-witness.

Normal player route: Select → Confirm → Versus → Battle → countdown → timer.
STOP on first body-absent failure. AA-only guards.
"""
from __future__ import annotations

import json
import os
import struct
import subprocess
import sys
import time
import zlib
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_pixel_campaign as rpc

ROOT = rpc.ROOT
ART = rpc.ART
PIXEL = ART / "pixel" / "screen_witness"
PKG = rpc.PKG
APK = rpc.APK

# Roster index: ember0 rook1 juno2 kaia3 nix4 orion5 vesper6
VESPER_IDX = 6
KAIA_IDX = 3


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def git_sha() -> str:
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()


def analyze_stage_colorful(path: Path) -> dict:
    """Count non-navy/non-green/non-white pixels in stage band (fighter body proxy)."""
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    i = 8
    w = h = ctype = None
    idat = b""
    while i < len(data):
        ln = int.from_bytes(data[i : i + 4], "big")
        i += 4
        typ = data[i : i + 4]
        i += 4
        chunk = data[i : i + ln]
        i += ln + 4
        if typ == b"IHDR":
            w, h, _bit, ctype = struct.unpack(">IIBB", chunk[:10])
        elif typ == b"IDAT":
            idat += chunk
        elif typ == b"IEND":
            break
    raw = zlib.decompress(idat)
    bpp = {2: 3, 6: 4, 0: 1, 4: 2, 3: 1}.get(ctype, 4)
    stride = w * bpp
    rows = []
    p = 0
    prev = bytearray(stride)
    for _y in range(h):
        ft = raw[p]
        p += 1
        row = bytearray(raw[p : p + stride])
        p += stride
        if ft == 1:
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                row[x] = (row[x] + left) & 255
        elif ft == 2:
            for x in range(stride):
                row[x] = (row[x] + prev[x]) & 255
        elif ft == 3:
            for x in range(stride):
                left = row[x - bpp] if x >= bpp else 0
                row[x] = (row[x] + ((left + prev[x]) // 2)) & 255
        elif ft == 4:
            for x in range(stride):
                a = row[x - bpp] if x >= bpp else 0
                b = prev[x]
                c = prev[x - bpp] if x >= bpp else 0
                p0 = a + b - c
                pa, pb, pc = abs(p0 - a), abs(p0 - b), abs(p0 - c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                row[x] = (row[x] + pr) & 255
        rows.append(row)
        prev = row
    x0, x1 = int(w * 0.22), int(w * 0.78)
    y0, y1 = int(h * 0.28), int(h * 0.62)
    colorful = 0
    total = 0
    for y in range(y0, y1):
        row = rows[y]
        for x in range(x0, x1):
            o = x * bpp
            if bpp >= 3:
                r, g, b = row[o], row[o + 1], row[o + 2]
            else:
                r = g = b = row[o]
            total += 1
            if g > 130 and r < 110 and b < 110:
                continue
            if r < 55 and g < 65 and b < 110:
                continue
            if r > 200 and g > 200 and b > 200:
                continue
            if max(r, g, b) - min(r, g, b) > 35 and max(r, g, b) > 70:
                colorful += 1
    pct = 100.0 * colorful / max(total, 1)
    # Labels alone ≈ <3%; visible geometric bodies typically >> 4%
    return {
        "path": str(path.relative_to(ROOT)),
        "w": w,
        "h": h,
        "stage_colorful": colorful,
        "stage_total": total,
        "stage_colorful_pct": round(pct, 3),
        "bodies_likely_absent": pct < 3.5,
    }


def install_apk(serial: str) -> dict:
    if not APK.is_file():
        return {"ok": False, "reason": "APK_MISSING"}
    rpc.adb(["-s", serial, "install", "-r", str(APK)], timeout=300)
    grants = rpc.grant_aa_runtime_permissions(serial)
    return {
        "ok": True,
        "apk": str(APK),
        "sha256": rpc.sha256_file(APK),
        "git_sha": git_sha(),
        "grants": grants,
    }


def main() -> int:
    PIXEL.mkdir(parents=True, exist_ok=True)
    serials = rpc.devices()
    if not serials:
        payload = {
            "ok": False,
            "status": "BLOCKED_PIXEL6A",
            "CP2_SEALED": False,
            "reason": "no device",
            "emitted_at": utc_now(),
        }
        (ART / "CP2_VESPER_KAIA_FIRST_FAILURE.json").write_text(json.dumps(payload, indent=2) + "\n")
        print(json.dumps(payload, indent=2))
        return 2
    serial = serials[0]
    install = install_apk(serial)
    if not install.get("ok"):
        payload = {"ok": False, "status": "BLOCKED_PIXEL6A", "install": install, "CP2_SEALED": False}
        (ART / "CP2_VESPER_KAIA_FIRST_FAILURE.json").write_text(json.dumps(payload, indent=2) + "\n")
        return 2

    rpc.adb(["-s", serial, "shell", "am", "force-stop", PKG])
    time.sleep(0.5)
    if not rpc.launch_app(serial):
        payload = {"ok": False, "status": "BLOCKED_PIXEL6A", "reason": "launch_failed", "CP2_SEALED": False}
        (ART / "CP2_VESPER_KAIA_FIRST_FAILURE.json").write_text(json.dumps(payload, indent=2) + "\n")
        return 2
    time.sleep(2.5)
    if not rpc.ensure_aa_foreground(serial, "boot"):
        payload = {"ok": False, "status": "BLOCKED_PIXEL6A", "reason": "not_foreground", "CP2_SEALED": False}
        (ART / "CP2_VESPER_KAIA_FIRST_FAILURE.json").write_text(json.dumps(payload, indent=2) + "\n")
        return 2

    # Navigate to Fighter Select (same early-gate pattern).
    rpc.navigate_to_fighter_select(serial)
    time.sleep(1.0)
    rpc.screencap(serial, "sw_00_select")
    # Move capture into screen_witness folder
    src = rpc.PIXEL / "sw_00_select.png"
    if src.is_file():
        (PIXEL / "sw_00_select.png").write_bytes(src.read_bytes())

    # P1 = Vesper (index 6)
    rpc.tap_roster_index(serial, VESPER_IDX)
    time.sleep(0.6)
    rpc.screencap(serial, "sw_01_p1_vesper")
    src = rpc.PIXEL / "sw_01_p1_vesper.png"
    if src.is_file():
        (PIXEL / "sw_01_p1_vesper.png").write_bytes(src.read_bytes())

    # Confirm P1 then select P2 Kaia
    if not rpc.confirm_fighter_select_into_battle.__doc__:
        pass
    # Manual: tap Next for P1, then Kaia for P2, then Next, then stage confirm.
    # Reuse campaign confirm but first set P2.
    # After P1 lock via first Next, tap Kaia, then continue confirm helpers.
    w, h = rpc.display_wh(serial)
    # First Next (P1)
    rpc.tap(serial, 360, 941)
    time.sleep(0.8)
    rpc.tap_roster_index(serial, KAIA_IDX)
    time.sleep(0.6)
    rpc.screencap(serial, "sw_02_p2_kaia")
    src = rpc.PIXEL / "sw_02_p2_kaia.png"
    if src.is_file():
        (PIXEL / "sw_02_p2_kaia.png").write_bytes(src.read_bytes())
    # P2 Next
    rpc.tap(serial, 360, 941)
    time.sleep(0.8)
    # Stage Confirm
    rpc.tap(serial, 1200, 980)
    time.sleep(1.2)
    if not rpc.ensure_aa_foreground(serial, "post_confirm"):
        payload = {"ok": False, "status": "BLOCKED_PIXEL6A", "reason": "lost_fg_post_confirm", "CP2_SEALED": False}
        (ART / "CP2_VESPER_KAIA_FIRST_FAILURE.json").write_text(json.dumps(payload, indent=2) + "\n")
        return 2

    captures = []
    first_failure = None
    # Versus may flash; then battle countdown 3/2/1 + active offsets.
    timeline = [
        ("versus_or_countdown", 0.8),
        ("countdown_3", 0.0),
        ("countdown_2", 1.0),
        ("countdown_1", 1.0),
        ("fight_active_0", 0.7),
        ("fight_plus_250ms", 0.25),
        ("fight_plus_500ms", 0.25),
        ("fight_plus_1000ms", 0.5),
        ("fight_plus_3000ms", 2.0),
    ]
    for name, wait_s in timeline:
        if wait_s > 0:
            time.sleep(wait_s)
        if not rpc.ensure_aa_foreground(serial, name):
            first_failure = {"state": name, "reason": "LOST_FOREGROUND"}
            break
        cap_name = f"sw_{name}"
        rpc.screencap(serial, cap_name)
        src = rpc.PIXEL / f"{cap_name}.png"
        dst = PIXEL / f"{cap_name}.png"
        if src.is_file():
            dst.write_bytes(src.read_bytes())
            analysis = analyze_stage_colorful(dst)
            analysis["state"] = name
            captures.append(analysis)
            # Detect HUD-present / bodies-absent: OCR optional; colorful threshold primary.
            if analysis["bodies_likely_absent"] and name.startswith(("countdown", "fight")):
                first_failure = {
                    "state": name,
                    "reason": "FINAL_SCREEN_BODIES_ABSENT",
                    "OWNER_REG_014": "FAIL",
                    "analysis": analysis,
                    "note": "STOP on first failure — HUD/stage may still be visible",
                }
                break

    sealed = first_failure is None and all(not c.get("bodies_likely_absent", True) for c in captures if str(c.get("state", "")).startswith(("countdown", "fight")))
    payload = {
        "ok": sealed,
        "status": "PASS" if sealed else ("FAIL" if first_failure else "PARTIAL"),
        "CP2_SEALED": False,
        "SAFE_TO_START_CP3_FLOURISH": False,
        "SAFE_TO_START_CP5_ELEMENTAL_AUDIO": False,
        "pair": "vesper-nyx_vs_kaia-windrow",
        "route": "Select→Confirm→Versus→Battle→countdown→timer",
        "PHYSICALLY_TESTED_RUNTIME_SHA": install.get("git_sha"),
        "APK_SHA256": install.get("sha256"),
        "PACKAGE": PKG,
        "DEVICE_SERIAL": serial,
        "SETTINGS_UI_USED": False,
        "PERMISSION_GRANT_METHOD": "adb_pm_grant",
        "AA_ONLY_GUARDS": True,
        "install": install,
        "captures": captures,
        "first_failure": first_failure,
        "emitted_at": utc_now(),
    }
    out = ART / "CP2_VESPER_KAIA_FIRST_FAILURE.json"
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps({k: v for k, v in payload.items() if k != "captures"}, indent=2))
    print(f"captures={len(captures)} first_failure={first_failure is not None} wrote={out}")
    return 0 if sealed else 1


if __name__ == "__main__":
    raise SystemExit(main())
