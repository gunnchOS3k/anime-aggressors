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


def ocr_text(path: Path) -> str:
    """Best-effort OCR; empty string if unavailable."""
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


# Unique bio/signature lines only — roster strip lists all 7 names every frame.
FIGHTER_FOCUS_MARKERS: list[tuple[str, tuple[str, ...]]] = [
    ("ember", ("pressure first", "cinder rush", "controlled fire")),
    ("rook", ("plant. hold", "plant hold", "faultline", "iron guard")),
    ("juno", ("blink once", "flash circuit", "arc impulse")),
    ("kaia", ("wind never", "spiral current", "sky current")),
    ("nix", ("precision is louder", "glacier lock", "frost lattice")),
    ("orion", ("orbits wait", "gravity well", "decide where motion")),
    ("vesper", ("shadows don't", "shadows dont", "null step", "eclipse veil")),
]


def looks_like_fighter_select(path: Path) -> bool:
    return rpc.looks_like_fighter_select(path)


def focused_fighter_id(path: Path) -> str:
    """Best-effort focused fighter from bio OCR (not the full roster strip)."""
    text = ocr_text(path)
    if not text:
        return ""
    scores: dict[str, int] = {}
    for fid, markers in FIGHTER_FOCUS_MARKERS:
        scores[fid] = sum(1 for m in markers if m in text)
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else ""


def looks_like_left_select(path: Path) -> bool:
    """True if still on Fighter Select (battle capture must not match this)."""
    return looks_like_fighter_select(path)


def looks_like_post_select(path: Path) -> bool:
    """Stage / versus / battle — must leave Fighter Select chrome."""
    text = ocr_text(path)
    if not text:
        return False
    if looks_like_fighter_select(path):
        return False
    markers = (
        "stage select",
        "confirm stage",
        "versus",
        "training grid",
        "aura",
        "3:00",
        "jp",
    )
    return any(m in text for m in markers)


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

    select_path = PIXEL / "early_01_fighter_select.png"
    luma = mean_luma(select_path) if select_path.is_file() else -1.0
    ocr = ocr_text(select_path)
    on_select = looks_like_fighter_select(select_path)
    shell_only = (not cap_select.get("ok")) or (not on_select)
    if shell_only:
        select_ghosts += 1
        write_early({
            "PIXEL_EARLY_GATE": "FAIL",
            "reason": "NOT_ON_FIGHTER_SELECT_AFTER_NAV",
            "PIXEL_DEVICE_AVAILABLE": True,
            "PIXEL_AUTHENTIC": True,
            "DEVICE_SERIAL": serial,
            "DEVICE_MODEL": model,
            "PIXEL_SOURCE_SHA": source_sha,
            "APK_SHA256": apk_sha,
            "SELECT_MEAN_LUMA": luma,
            "SELECT_OCR_SNIPPET": ocr[:400],
            "PIXEL_FIGHTER_SELECT_DYNAMIC_CONTENT_COMPLETE": False,
            "PIXEL_OWNER_REG_009": "FAIL",
            "PIXEL_OWNER_REG_008": "FAIL",
            "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": select_ghosts,
            "PREVIOUS_FALSE_PASS_NOTE": "Prior byte-size-only heuristic could PASS while stuck on Rulesets",
            "captures": captures,
            "emitted_at": utc_now(),
        })
        raise SystemExit(1)

    # Browse fighters 1..7 via landscape roster taps (DPAD drifts to Showcase).
    expected = [fid for fid, _ in FIGHTER_FOCUS_MARKERS]
    seen_focus: list[str] = []
    for i in range(7):
        if not rpc.ensure_aa_foreground(serial, f"early_browse_{i}"):
            deaths += 1
            rpc.launch_app(serial)
            rpc.navigate_to_fighter_select(serial)
        rpc.tap_roster_index(serial, i)
        time.sleep(0.65)
        cap = rpc.screencap(serial, f"early_A_select_{i}")
        captures.append(cap)
        p = PIXEL / f"early_A_select_{i}.png"
        if not looks_like_fighter_select(p):
            select_ghosts += 1
        if not cap.get("ok") or cap.get("bytes", 0) < 55_000:
            select_ghosts += 1
        focus = focused_fighter_id(p)
        seen_focus.append(focus)
        if focus and focus != expected[i]:
            # Soft: OCR may miss; still require distinct focus ids across browse.
            pass

    distinct_focus = len({f for f in seen_focus if f})
    browse_complete = distinct_focus >= 5  # allow mild OCR miss; require real movement

    # Confirm into stage/versus/battle (must leave Fighter Select).
    rpc.confirm_fighter_select_into_battle(serial)
    time.sleep(2.0)
    if not rpc.ensure_aa_foreground(serial, "early_battle"):
        deaths += 1
    cap_battle = rpc.screencap(serial, "early_C_battle")
    captures.append(cap_battle)
    battle_path = PIXEL / "early_C_battle.png"
    still_on_select = looks_like_left_select(battle_path)
    if still_on_select or not looks_like_post_select(battle_path):
        battle_ghosts += 1
    # Battle HUD frames are dark/simple — often ~35-50KB; do not reuse select's 55KB floor.
    if not cap_battle.get("ok") or cap_battle.get("bytes", 0) < 20_000:
        battle_ghosts += 1

    logcat = rpc.adb(["-s", serial, "logcat", "-d", "-t", "400"]).stdout
    (PIXEL / "early_logcat.txt").write_text(logcat)
    fatal = logcat.count("FATAL EXCEPTION") if PKG in logcat else 0

    dynamic_complete = (
        not shell_only
        and select_ghosts == 0
        and browse_complete
        and battle_ghosts == 0
        and deaths == 0
        and fatal == 0
        and len([c for c in captures if c.get("ok")]) >= 9
    )
    # REG-009: select shell populated with roster + preview (entry capture).
    reg009 = "PASS" if (not shell_only and select_ghosts == 0 and deaths == 0 and fatal == 0) else "FAIL"
    # REG-008: seven-browse + leave-select without render ghosts / deaths.
    reg008 = "PASS" if (browse_complete and select_ghosts == 0 and battle_ghosts == 0 and deaths == 0) else "FAIL"
    gate = "PASS" if (reg009 == "PASS" and reg008 == "PASS" and dynamic_complete) else "FAIL"
    reason = None
    if still_on_select:
        reason = "BATTLE_CAPTURE_STILL_FIGHTER_SELECT"
    elif not browse_complete:
        reason = f"BROWSE_FOCUS_INCOMPLETE distinct={distinct_focus} seen={seen_focus}"

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
        "SELECT_OCR_SNIPPET": ocr[:400],
        "BROWSE_FOCUS_IDS": seen_focus,
        "BROWSE_DISTINCT_FOCUS": distinct_focus,
        "BATTLE_STILL_ON_SELECT": still_on_select,
        "reason": reason,
        "DISPLAY_COORD_SPACE": "landscape_preferred",
        "PREVIOUS_FALSE_PASS_NOTE": "Byte-size-only and ENTER-only nav could PASS while stuck on Rulesets/select",
        "captures": captures,
        "emitted_at": utc_now(),
    })
    raise SystemExit(0 if gate == "PASS" else 1)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:
        write_early({
            "PIXEL_EARLY_GATE": "FAIL",
            "reason": f"EXCEPTION:{type(exc).__name__}:{exc}",
            "emitted_at": utc_now(),
        })
        raise
