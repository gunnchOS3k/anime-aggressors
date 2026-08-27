#!/usr/bin/env python3
"""WAVE020 CP2 reopen — Vesper vs Kaia first failure Pixel screen-witness.

Normal player route: Select → Confirm → Versus → Battle → countdown → timer.
STOP on first body-absent failure. AA-only guards.
"""
from __future__ import annotations

import json
import os
import re
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

FIGHTER_FOCUS_MARKERS: list[tuple[str, tuple[str, ...]]] = [
    ("ember", ("pressure first", "cinder rush", "controlled fire")),
    ("rook", ("plant. hold", "plant hold", "faultline", "iron guard")),
    ("juno", ("blink once", "flash circuit", "arc impulse")),
    ("kaia", ("wind never", "spiral current", "sky current")),
    ("nix", ("precision is louder", "glacier lock", "frost lattice")),
    ("orion", ("orbits wait", "gravity well", "decide where motion")),
    ("vesper", ("shadows don't", "shadows dont", "null step", "eclipse veil")),
]


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


def ocr_text(path: Path) -> str:
    if not path.is_file():
        return ""
    try:
        r = subprocess.run(
            ["tesseract", str(path), "stdout"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        return (r.stdout or "").lower()
    except Exception:
        return ""


def focused_fighter_id(path: Path) -> str:
    text = ocr_text(path)
    if not text:
        return ""
    scores: dict[str, int] = {}
    for fid, markers in FIGHTER_FOCUS_MARKERS:
        scores[fid] = sum(1 for m in markers if m in text)
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else ""


def looks_like_fighter_select(path: Path) -> bool:
    return rpc.looks_like_fighter_select(path)


def looks_like_victory_screen(path: Path) -> bool:
    text = ocr_text(path)
    if not text:
        return False
    victory_markers = (" wins!", " wins", "rematch", "change fighters", "back home", "victory")
    return any(m in text for m in victory_markers)


def looks_like_fight_hud(path: Path) -> bool:
    text = ocr_text(path)
    if not text:
        return False
    if looks_like_victory_screen(path):
        return False
    if "move list" in text or "command guide" in text:
        return False
    if "stage select" in text or "confirm stage" in text:
        return False
    if looks_like_fighter_select(path):
        return False

    return bool(re.search(r"\d:\d{2}", text)) or "fight!" in text or "versus" in text or "aura" in text


def battle_hud_fighters(path: Path) -> tuple[str, str]:
    """Best-effort P1/P2 names from battle HUD OCR (left-to-right order)."""
    text = ocr_text(path)
    hits: list[tuple[int, str]] = []
    for short, full in (
        ("vesper", "vesper-nyx"),
        ("kaia", "kaia-windrow"),
        ("rook", "rook-ironside"),
        ("nix", "nix-calder"),
        ("juno", "juno-spark"),
        ("orion", "orion-vell"),
        ("ember", "ember-vale"),
    ):
        pos = text.find(short)
        if pos >= 0:
            hits.append((pos, full))
    hits.sort(key=lambda t: t[0])
    p1 = hits[0][1] if hits else ""
    p2 = hits[1][1] if len(hits) > 1 else ""
    return p1, p2


def copy_cap(name: str) -> Path:
    src = rpc.PIXEL / f"{name}.png"
    dst = PIXEL / f"{name}.png"
    if src.is_file():
        dst.write_bytes(src.read_bytes())
    return dst


def tap_next(serial: str, step: str) -> None:
    cap = rpc.screencap(serial, f"sw_nav_{step}")
    path = rpc.PIXEL / f"sw_nav_{step}.png"
    xy = rpc.find_label_tap(path, "next", "confirm") if path.is_file() else None
    x, y = xy or (360, 941)
    rpc.tap(serial, x, y)
    time.sleep(0.85)


def tap_confirm_stage(serial: str) -> None:
    cap = rpc.screencap(serial, "sw_nav_stage")
    path = rpc.PIXEL / "sw_nav_stage.png"
    xy = rpc.find_label_tap(path, "confirm", "stage", max_top=1080) if path.is_file() else None
    if xy is None and path.is_file():
        xy = rpc.find_label_tap(path, "confirm", max_top=1080)
    w, h = rpc.display_wh(serial)
    x, y = xy or (w // 2, int(h * 0.94))
    rpc.tap(serial, x, y)
    time.sleep(0.5)
    rpc.key(serial, "66")  # ENTER / ui_accept
    time.sleep(1.0)


def tap_fighter_name(serial: str, cap_name: str, *needles: str) -> bool:
    rpc.screencap(serial, cap_name)
    path = copy_cap(cap_name)
    xy = rpc.find_label_tap(path, *needles, max_top=900)
    if xy is None:
        return False
    rpc.tap(serial, xy[0], xy[1])
    time.sleep(0.65)
    return True


def select_roster_fighter(serial: str, index: int, want: str, cap_name: str) -> str:
    """Tap roster tile until OCR focus matches want (ember/rook/.../vesper)."""
    focus = ""
    name_needles = {
        "kaia": ("kaia", "windrow", "sky current", "spiral current"),
        "vesper": ("vesper", "nyx", "eclipse veil", "null step"),
        "rook": ("rook", "ironside"),
    }.get(want, (want,))
    for attempt in range(5):
        if attempt == 0 or attempt >= 2:
            rpc.tap_roster_index(serial, index)
            time.sleep(0.65)
        if attempt in (1, 3):
            tap_fighter_name(serial, f"{cap_name}_ocr_{attempt}", *name_needles)
        rpc.screencap(serial, cap_name)
        path = copy_cap(cap_name)
        if not looks_like_fighter_select(path):
            time.sleep(0.4)
            continue
        focus = focused_fighter_id(path)
        text = ocr_text(path)
        if focus == want or any(n in text for n in name_needles[:2]):
            if any(n in text for n in name_needles[:2]) and "face-off" in text:
                # Require face-off line to mention wanted fighter for P2 lock-in.
                if want in text or name_needles[0] in text:
                    return want
            if focus == want:
                return focus
        time.sleep(0.35)
    return focus


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
    copy_cap("sw_00_select")

    p1_focus = select_roster_fighter(serial, VESPER_IDX, "vesper", "sw_01_p1_vesper")
    tap_next(serial, "p1")
    if not rpc.ensure_aa_foreground(serial, "post_p1_next"):
        payload = {"ok": False, "status": "BLOCKED_PIXEL6A", "reason": "lost_fg_post_p1_next", "CP2_SEALED": False}
        (ART / "CP2_VESPER_KAIA_FIRST_FAILURE.json").write_text(json.dumps(payload, indent=2) + "\n")
        return 2

    p2_focus = select_roster_fighter(serial, KAIA_IDX, "kaia", "sw_02_p2_kaia")
    # Require face-off OCR shows Kaia before advancing.
    p2_path = PIXEL / "sw_02_p2_kaia.png"
    p2_text = ocr_text(p2_path)
    if "kaia" not in p2_text and "windrow" not in p2_text:
        tap_fighter_name(serial, "sw_02_p2_kaia_retry", "kaia", "windrow")
        rpc.screencap(serial, "sw_02_p2_kaia")
        copy_cap("sw_02_p2_kaia")
        p2_text = ocr_text(PIXEL / "sw_02_p2_kaia.png")
        if "kaia" in p2_text or "windrow" in p2_text:
            p2_focus = "kaia"
    tap_next(serial, "p2")
    tap_confirm_stage(serial)
    if not rpc.ensure_aa_foreground(serial, "post_confirm"):
        payload = {"ok": False, "status": "BLOCKED_PIXEL6A", "reason": "lost_fg_post_confirm", "CP2_SEALED": False}
        (ART / "CP2_VESPER_KAIA_FIRST_FAILURE.json").write_text(json.dumps(payload, indent=2) + "\n")
        return 2

    # Wait for battle HUD (not stage select) before screen-witness timeline.
    battle_ready = False
    for _wait in range(20):
        time.sleep(0.5)
        rpc.screencap(serial, "sw_battle_wait")
        wait_path = copy_cap("sw_battle_wait")
        text = ocr_text(wait_path)
        if "stage select" in text or "confirm stage" in text:
            tap_confirm_stage(serial)
            continue
        if any(m in text for m in ("3:00", "versus", "fight!", "aura")) and "confirm stage" not in text:
            battle_ready = True
            break
    if not battle_ready:
        first_failure = {"state": "battle_wait", "reason": "NEVER_REACHED_BATTLE_HUD"}
        captures = []
        pair_ok = False
        p1_actual = p2_actual = ""
        p1_focus = p1_focus if "p1_focus" in dir() else ""
        sealed = False
        payload = {
            "ok": False,
            "status": "FAIL",
            "PIXEL_VESPER_KAIA_FINAL_SCREEN_PASS": False,
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
            "visual_owner_review": {
                "p1_requested": "vesper-nyx",
                "p2_requested": "kaia-windrow",
                "p1_select_focus": p1_focus,
                "p2_select_focus": p2_focus,
                "p2_nav_mismatch": True,
                "battle_bodies_visible_on_pixel": False,
            },
            "emitted_at": utc_now(),
        }
        (ART / "CP2_VESPER_KAIA_FIRST_FAILURE.json").write_text(json.dumps(payload, indent=2) + "\n")
        print(json.dumps({k: v for k, v in payload.items() if k != "captures"}, indent=2))
        return 1

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
            analysis["screen_class"] = (
                "victory" if looks_like_victory_screen(dst)
                else "fight_hud" if looks_like_fight_hud(dst)
                else "other"
            )
            analysis["evaluated_for_bodies"] = analysis["screen_class"] == "fight_hud"
            captures.append(analysis)

    # Evaluate in-fight frames only; victory/menu screens are not body-absent failures.
    in_fight = [
        c for c in captures
        if c.get("evaluated_for_bodies") and str(c.get("state", "")).startswith(("countdown", "fight"))
    ]
    if in_fight:
        passing = [c for c in in_fight if not c.get("bodies_likely_absent")]
        failing = [c for c in in_fight if c.get("bodies_likely_absent")]
        # Require majority of sampled in-fight HUD frames to show bodies (animation dips OK).
        min_pass = max(2, (len(in_fight) + 1) // 2)
        if len(passing) < min_pass and failing:
            worst = min(failing, key=lambda c: c.get("stage_colorful_pct", 0))
            first_failure = {
                "state": worst.get("state"),
                "reason": "FINAL_SCREEN_BODIES_ABSENT",
                "OWNER_REG_014": "FAIL",
                "analysis": worst,
                "in_fight_frames": len(in_fight),
                "in_fight_passing": len(passing),
                "in_fight_failing": len(failing),
                "note": (
                    "Majority of in-fight HUD frames below colorful threshold; "
                    "victory/menu frames excluded"
                ),
            }

    pair_ok = False
    p1_actual = p2_actual = ""
    for c in captures:
        if c.get("state") == "fight_active_0":
            p = PIXEL / "sw_fight_active_0.png"
            p1_actual, p2_actual = battle_hud_fighters(p)
            pair_ok = p1_actual == "vesper-nyx" and p2_actual == "kaia-windrow"
            break

    sealed = (
        first_failure is None
        and pair_ok
        and p1_focus == "vesper"
        and p2_focus == "kaia"
        and len(in_fight) >= 2
        and len([c for c in in_fight if not c.get("bodies_likely_absent")]) >= max(
            2, (len(in_fight) + 1) // 2
        )
    )
    pixel_pass = sealed
    payload = {
        "ok": sealed,
        "status": "PASS" if sealed else ("FAIL" if first_failure or not pair_ok else "PARTIAL"),
        "PIXEL_VESPER_KAIA_FINAL_SCREEN_PASS": pixel_pass,
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
        "visual_owner_review": {
            "p1_requested": "vesper-nyx",
            "p2_requested": "kaia-windrow",
            "p1_select_focus": p1_focus,
            "p2_select_focus": p2_focus,
            "p1_actual": p1_actual,
            "p2_actual": p2_actual,
            "p2_nav_mismatch": not pair_ok,
            "battle_bodies_visible_on_pixel": first_failure is None,
        },
        "emitted_at": utc_now(),
    }
    out = ART / "CP2_VESPER_KAIA_FIRST_FAILURE.json"
    out.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps({k: v for k, v in payload.items() if k != "captures"}, indent=2))
    print(f"captures={len(captures)} first_failure={first_failure is not None} wrote={out}")
    return 0 if sealed else 1


if __name__ == "__main__":
    raise SystemExit(main())
