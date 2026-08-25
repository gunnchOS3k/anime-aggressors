#!/usr/bin/env python3
"""Wave018 Pixel 6a campaign — renderability telemetry (not process-death ghosts)."""
from __future__ import annotations

import hashlib
import json
import os
import random
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "engineering_wave018"
PIXEL = ART / "pixel"
PKG = os.environ.get("AA_ANDROID_PKG", "com.gunnchos.animeaggressors")
ACTIVITY = "com.godot.game.GodotApp"
COMPONENT = f"{PKG}/{ACTIVITY}"
APK = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"
TRACE_REMOTE = "files/wave018_visibility_trace.jsonl"
COUNTERS_REMOTE = "files/wave018_visibility_counters.json"
FORBIDDEN_PACKAGES = (
    "com.gunnchos.pedestrianpursuit",
    "com.gunnchos.beatlink",
    "com.gunnchos.archive",
)
FIGHTERS = [
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_file(path: Path) -> str:
    if not path.is_file():
        return ""
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def git_sha() -> str:
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()


def adb(*args: str, timeout: int = 180) -> subprocess.CompletedProcess:
    return subprocess.run(["adb", *args], cwd=ROOT, capture_output=True, text=True, timeout=timeout)


def adb_authorized() -> bool:
    raw = adb("devices").stdout
    for ln in raw.splitlines()[1:]:
        parts = ln.split()
        if len(parts) >= 2 and parts[1] == "device":
            return True
    return False


def discover_pixel6a() -> dict:
    subprocess.run(["adb", "start-server"], capture_output=True, text=True)
    raw = adb("devices", "-l").stdout
    lines = [ln for ln in raw.splitlines()[1:] if ln.strip()]
    auth = [ln for ln in lines if len(ln.split()) >= 2 and ln.split()[1] == "device"]
    unauth = [ln for ln in lines if "unauthorized" in ln]
    if not auth:
        return {
            "ok": False,
            "reason": "BLOCKED_PIXEL6A",
            "detail": "unauthorized" if unauth else "no adb device",
            "raw": raw,
        }
    serial = auth[0].split()[0]
    model = adb("shell", "getprop", "ro.product.model").stdout.strip()
    if "Pixel 6a" not in model and "Pixel_6a" not in raw:
        if "bluejay" not in raw and "Pixel 6a" not in model:
            return {"ok": False, "reason": "BLOCKED_WRONG_DEVICE", "model": model, "serial": serial}
    return {"ok": True, "serial": serial, "model": model or "Pixel 6a", "raw": raw}


def write_blocked(reason: str, extra: dict | None = None) -> int:
    payload = {
        "PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A",
        "PIXEL_DEVICE_AVAILABLE": False,
        "PIXEL_AUTHENTIC": False,
        "reason": reason,
        "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": None,
        "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES": None,
        "PIXEL_PROCESS_DEATHS": None,
        "emitted_at": utc_now(),
    }
    if extra:
        payload.update(extra)
    ART.mkdir(parents=True, exist_ok=True)
    for name in [
        "WAVE018_PIXEL_SELECT_STRESS_RESULT.json",
        "WAVE018_PIXEL_VISIBILITY_RESULT.json",
        "WAVE018_PIXEL_SMOKE_RESULT.json",
    ]:
        (ART / name).write_text(json.dumps({**payload, "artifact": name}, indent=2) + "\n")
    print(json.dumps(payload, indent=2))
    return 2


def run_as_cat(rel: str) -> str:
    r = subprocess.run(
        ["adb", "exec-out", "run-as", PKG, "cat", rel],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=60,
    )
    if r.returncode != 0:
        return ""
    return r.stdout


def clear_telemetry() -> None:
    adb("shell", f"run-as {PKG} rm -f {TRACE_REMOTE} {COUNTERS_REMOTE}")


def pull_trace_rows() -> list[dict]:
    raw = run_as_cat(TRACE_REMOTE)
    rows: list[dict] = []
    for ln in raw.splitlines():
        ln = ln.strip()
        if not ln:
            continue
        try:
            rows.append(json.loads(ln))
        except json.JSONDecodeError:
            continue
    return rows


def pull_counters() -> dict:
    raw = run_as_cat(COUNTERS_REMOTE)
    if not raw.strip():
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def analyze_trace(rows: list[dict]) -> dict:
    select_rows = [r for r in rows if r.get("scene") == "fighter_select"]
    battle_rows = [r for r in rows if r.get("scene") == "battle"]
    heal_rows = [r for r in rows if r.get("scene") == "heal_recovery" or r.get("fallback_recovery")]
    select_ghosts = sum(1 for r in select_rows if r.get("render_ghost") or (
        bool(r.get("preview_expected_visible")) and int(r.get("visible_renderable_mesh_count", 0)) == 0
    ))
    battle_ghosts = sum(1 for r in battle_rows if r.get("render_ghost") or (
        bool(r.get("expected_visible"))
        and bool(r.get("logic_active"))
        and int(r.get("visible_renderable_mesh_count", 0)) == 0
    ))
    select_viol = sum(1 for r in select_rows if not bool(r.get("visibility_invariant_pass", True)))
    battle_viol = sum(1 for r in battle_rows if not bool(r.get("visibility_invariant_pass", True)))
    # Prefer on-device counters when present (includes heal recoveries).
    counters = pull_counters()
    return {
        "select_rows": len(select_rows),
        "battle_rows": len(battle_rows),
        "heal_rows": len(heal_rows),
        "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": int(
            counters.get("PIXEL_SELECT_RENDER_GHOST_OCCURRENCES", select_ghosts)
        ),
        "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES": int(
            counters.get("PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES", battle_ghosts)
        ),
        "PIXEL_SELECT_VISIBILITY_INVARIANT_VIOLATIONS": int(
            counters.get("PIXEL_SELECT_VISIBILITY_INVARIANT_VIOLATIONS", select_viol)
        ),
        "PIXEL_BATTLE_VISIBILITY_INVARIANT_VIOLATIONS": int(
            counters.get("PIXEL_BATTLE_VISIBILITY_INVARIANT_VIOLATIONS", battle_viol)
        ),
        "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS": int(
            counters.get(
                "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS",
                select_viol + battle_viol + len(heal_rows),
            )
        ),
        "PIXEL_FALLBACK_RECOVERIES": int(
            counters.get("PIXEL_FALLBACK_RECOVERIES", len(heal_rows))
        ),
        "latest_select": select_rows[-1] if select_rows else {},
        "latest_battle": battle_rows[-2:] if len(battle_rows) >= 2 else battle_rows,
        "counters": counters,
    }


def screencap(name: str, *, telemetry_meta: dict | None = None) -> dict:
    PIXEL.mkdir(parents=True, exist_ok=True)
    remote = f"/sdcard/wave018_{name}.png"
    local = PIXEL / f"{name}.png"
    adb("shell", "screencap", "-p", remote)
    r = adb("pull", remote, str(local))
    ok = r.returncode == 0 and local.is_file() and local.stat().st_size > 1000
    entry = {
        "capture": name,
        "name": name,
        "path": str(local.relative_to(ROOT)) if ok else None,
        "bytes": local.stat().st_size if ok else 0,
        "ok": ok,
        "timestamp": utc_now(),
    }
    if telemetry_meta:
        entry.update(telemetry_meta)
    return entry


def foreground_package() -> str:
    """Prefer window focus — dumpsys activity topResumed can lag behind Godot."""
    win = adb("shell", "dumpsys", "window").stdout
    for line in win.splitlines():
        if "mCurrentFocus=" not in line and "mFocusedApp=" not in line:
            continue
        # e.g. mCurrentFocus=Window{abc u0 com.gunnchos.animeaggressors/com.godot.game.GodotApp}
        if PKG in line:
            return PKG
        for bad in FORBIDDEN_PACKAGES:
            if bad in line:
                return bad
        if "nexuslauncher" in line.lower() or "launcher" in line.lower():
            return "com.google.android.apps.nexuslauncher"
    out = adb("shell", "dumpsys", "activity", "activities").stdout
    for marker in ("topResumedActivity=", "mResumedActivity=", "mFocusedApp="):
        for line in out.splitlines():
            if marker not in line:
                continue
            if PKG in line:
                return PKG
            if " " not in line:
                continue
            try:
                part = line.split(" u0 ", 1)[1]
                pkg = part.split("/", 1)[0].strip()
                if pkg and not pkg.startswith("ActivityRecord"):
                    return pkg
            except IndexError:
                continue
    return ""


def pidof() -> str:
    return adb("shell", "pidof", PKG).stdout.strip()


def launch_app(*, reset_telemetry: bool = False) -> bool:
    for bad in FORBIDDEN_PACKAGES:
        adb("shell", "am", "force-stop", bad)
    adb("shell", "am", "force-stop", PKG)
    time.sleep(0.5)
    if reset_telemetry:
        clear_telemetry()
    # monkey launcher start reliably brings AA to window focus on Pixel 6a.
    r = adb(
        "shell",
        "monkey",
        "-p",
        PKG,
        "-c",
        "android.intent.category.LAUNCHER",
        "1",
    )
    time.sleep(5.0)
    fg = foreground_package()
    if PKG in fg:
        return True
    # Fallback: explicit component start (no --activity-brought-to-front; that can bounce to launcher).
    adb(
        "shell",
        "am",
        "start",
        "-W",
        "-n",
        COMPONENT,
        "-a",
        "android.intent.action.MAIN",
        "-c",
        "android.intent.category.LAUNCHER",
    )
    time.sleep(3.0)
    fg = foreground_package()
    if PKG not in fg and not pidof():
        print(f"LAUNCH FAIL: expected {PKG}, foreground={fg!r}, monkey={r.stdout}{r.stderr}")
        return False
    if PKG not in fg:
        print(f"LAUNCH WARN: foreground={fg!r} after starting {COMPONENT}")
        return False
    return True


def ensure_aa_foreground(context: str) -> bool:
    if not pidof():
        return launch_app()
    fg = foreground_package()
    if fg in FORBIDDEN_PACKAGES:
        print(f"force-stopping forbidden package during {context}: {fg}")
        adb("shell", "am", "force-stop", fg)
        return launch_app()
    if PKG in fg:
        return True
    # Soft recover: monkey bring-to-front without force-stop (preserve telemetry).
    print(f"re-focusing AA ({context}); was foreground={fg!r}")
    adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(2.0)
    if PKG in foreground_package():
        return True
    return launch_app()


def soft_back_in_aa(actions: list | None = None) -> None:
    """Issue BACK only while AA focused; never drive launcher afterward."""
    if PKG not in foreground_package():
        ensure_aa_foreground("soft_back_pre")
        return
    adb("shell", "input", "keyevent", "4")
    time.sleep(0.25)
    if actions is not None:
        actions.append("BACK")
    if PKG not in foreground_package():
        # Bounce home is common on Android; refocus AA without touching other apps.
        adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
        time.sleep(1.2)
    ensure_aa_foreground("soft_back_post")


def tap(x: int, y: int) -> None:
    if not ensure_aa_foreground(f"tap {x},{y}"):
        return
    adb("shell", "input", "tap", str(x), str(y))


def key(code: str) -> None:
    if not ensure_aa_foreground(f"key {code}"):
        return
    # Never send BACK through generic key() — use soft_back_in_aa.
    if str(code) in ("4", "KEYCODE_BACK"):
        soft_back_in_aa()
        return
    adb("shell", "input", "keyevent", code)


def navigate_to_fighter_select(actions: list) -> int:
    """Menu path into fighter select.

    Rulesets focuses the first Button (Stocks -); bare ENTER never reaches Confirm.
    Drive focus down to Confirm, confirm, then proceed into fighter select.
    """
    n = 0
    # Leave splash / main / mode menus
    for _ in range(8):
        key("66")
        time.sleep(0.35)
        n += 1
        actions.append("ENTER")
    # Rulesets: move focus to Confirm (many buttons above it)
    for _ in range(16):
        key("20")  # DPAD_DOWN
        time.sleep(0.08)
        n += 1
        actions.append("DPAD_DOWN")
    key("66")
    time.sleep(0.45)
    n += 1
    actions.append("ENTER_CONFIRM")
    # Tap Confirm region as belt-and-suspenders (Pixel 6a portrait)
    tap(540, 2050)
    time.sleep(0.4)
    n += 1
    actions.append("TAP_CONFIRM")
    # Extra confirms for stage/select entry if already past rulesets
    for _ in range(4):
        key("66")
        time.sleep(0.35)
        n += 1
        actions.append("ENTER")
    return n


def select_stress(actions: list) -> dict:
    """>=120 nav actions, >=20 roster sweeps, forward/reverse/rapid/random/confirm-back."""
    stats = {
        "nav_actions": 0,
        "roster_sweeps": 0,
        "confirm_back": 0,
        "random_reselections": 0,
        "process_deaths": 0,
    }
    # Forward sweeps (7 fighters each)
    for _ in range(12):
        for _i in range(7):
            if not ensure_aa_foreground("select_forward"):
                stats["process_deaths"] += 1
                if not launch_app(reset_telemetry=True):
                    return stats
                navigate_to_fighter_select(actions)
            key("22")  # RIGHT
            time.sleep(0.11)
            stats["nav_actions"] += 1
            actions.append("DPAD_RIGHT")
        stats["roster_sweeps"] += 1
        time.sleep(0.15)
        # Sample telemetry after each sweep
        _ = pull_trace_rows()

    # Reverse sweeps
    for _ in range(8):
        for _i in range(7):
            if not ensure_aa_foreground("select_reverse"):
                stats["process_deaths"] += 1
                if not launch_app():
                    return stats
                navigate_to_fighter_select(actions)
            key("21")  # LEFT
            time.sleep(0.11)
            stats["nav_actions"] += 1
            actions.append("DPAD_LEFT")
        stats["roster_sweeps"] += 1

    # Rapid cycling
    for i in range(40):
        if not ensure_aa_foreground("select_rapid"):
            stats["process_deaths"] += 1
            break
        key("22" if i % 2 == 0 else "21")
        time.sleep(0.06)
        stats["nav_actions"] += 1
        actions.append("RAPID")

    # Random reselections
    for _ in range(24):
        if not ensure_aa_foreground("select_random"):
            stats["process_deaths"] += 1
            break
        steps = random.randint(1, 6)
        direction = "22" if random.random() < 0.5 else "21"
        for _s in range(steps):
            key(direction)
            time.sleep(0.08)
            stats["nav_actions"] += 1
            actions.append("RANDOM")
        stats["random_reselections"] += 1

    # Confirm / soft-back loops (stay in AA)
    for _ in range(20):
        if not ensure_aa_foreground("select_confirm_back"):
            stats["process_deaths"] += 1
            break
        key("66")
        time.sleep(0.22)
        stats["nav_actions"] += 1
        actions.append("CONFIRM")
        if PKG in foreground_package():
            soft_back_in_aa(actions)
            stats["nav_actions"] += 1
        stats["confirm_back"] += 1

    return stats


def select_to_battle(launches: int = 14) -> dict:
    stats = {
        "launches": 0,
        "process_deaths": 0,
        "paths": [],
    }
    for bout in range(launches):
        if not ensure_aa_foreground(f"battle_bout_{bout}"):
            stats["process_deaths"] += 1
            if not launch_app():
                break
            navigate_to_fighter_select([])
        # Cycle fighters before each launch
        for _ in range(7 + (bout % 7)):
            key("22")
            time.sleep(0.1)
        # Confirm through select/stage into battle
        for _ in range(12):
            key("66")
            time.sleep(0.38)
        time.sleep(2.2)
        stats["launches"] += 1
        path = "normal"
        if bout % 5 == 1:
            path = "back_reenter"
        elif bout % 5 == 2:
            path = "arcade_next"
        elif bout % 5 == 3:
            path = "ko_respawn_attempt"
        elif bout % 5 == 4:
            path = "rematch_attempt"
        stats["paths"].append(path)
        # Light combat / KO attempt
        for _ in range(8):
            tap(900, 1900)
            time.sleep(0.35)
            tap(750, 1750)
            time.sleep(0.35)
            key("22")
            time.sleep(0.15)
        if not pidof():
            stats["process_deaths"] += 1
            if not launch_app():
                break
            continue
        # Back toward select for next bout
        for _ in range(5):
            if PKG in foreground_package():
                key("4")
                time.sleep(0.35)
            ensure_aa_foreground("battle_bout_back")
        # Re-nav into select if needed
        for _ in range(4):
            key("66")
            time.sleep(0.3)
    return stats


def main() -> int:
    ART.mkdir(parents=True, exist_ok=True)
    PIXEL.mkdir(parents=True, exist_ok=True)
    disc = discover_pixel6a()
    if not disc.get("ok"):
        return write_blocked(str(disc.get("detail") or disc.get("reason")), {"discover": disc})

    serial = disc["serial"]
    model = disc["model"]
    source_sha = git_sha()

    force_rebuild = os.environ.get("WAVE018_FORCE_APK_REBUILD", "1") == "1"
    if force_rebuild or not APK.is_file() or APK.stat().st_size < 1_000_000:
        print("Rebuilding APK…")
        env = os.environ.copy()
        godot = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
        if godot.is_file():
            env["GODOT_BIN"] = str(godot)
        build = subprocess.run(
            ["node", "scripts/export-godot-android.mjs"],
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
            timeout=900,
        )
        (PIXEL / "apk_build_log.txt").write_text(build.stdout + "\n" + build.stderr)
        if build.returncode != 0 or not APK.is_file():
            return write_blocked("APK_BUILD_FAILED", {"build_exit": build.returncode})

    apk_sha = sha256_file(APK)
    (PIXEL / "PIXEL_BUILD_PROVENANCE.json").write_text(
        json.dumps(
            {
                "PIXEL_SOURCE_SHA": source_sha,
                "APK_SHA256": apk_sha,
                "APK_PATH": str(APK.relative_to(ROOT)),
                "PACKAGE": PKG,
                "DEVICE_SERIAL": serial,
                "DEVICE_MODEL": model,
                "emitted_at": utc_now(),
            },
            indent=2,
        )
        + "\n"
    )

    print("Installing", APK)
    inst = adb("install", "-r", str(APK), timeout=300)
    (PIXEL / "install.txt").write_text(inst.stdout + "\n" + inst.stderr)
    install_ok = inst.returncode == 0
    if not install_ok:
        return write_blocked("APK_INSTALL_FAILED", {"install": inst.stdout[-500:] + inst.stderr[-500:]})

    capture_manifest: list[dict] = []
    actions: list[str] = []

    # ---- Select preview stress ----
    if not launch_app():
        return write_blocked("LAUNCH_FAILED_WRONG_OR_MISSING_PACKAGE")
    capture_manifest.append(screencap("00_launch"))
    navigate_to_fighter_select(actions)
    time.sleep(1.0)
    # Initial select telemetry sample
    time.sleep(0.8)
    select_trace0 = analyze_trace(pull_trace_rows())
    sel0 = select_trace0.get("latest_select") or {}
    capture_manifest.append(
        screencap(
            "01_after_menu_nav",
            telemetry_meta={
                "scene": "fighter_select",
                "fighter_id": sel0.get("selected_fighter_id"),
                "telemetry_record_id": sel0.get("telemetry_record_id"),
                "visible_renderable_mesh_count": sel0.get("visible_renderable_mesh_count"),
                "visibility_invariant_pass": sel0.get("visibility_invariant_pass"),
            },
        )
    )

    stress = select_stress(actions)
    time.sleep(0.8)
    select_analysis = analyze_trace(pull_trace_rows())
    sel_end = select_analysis.get("latest_select") or {}
    capture_manifest.append(
        screencap(
            "02_select_stress_end",
            telemetry_meta={
                "scene": "fighter_select",
                "fighter_id": sel_end.get("selected_fighter_id"),
                "telemetry_record_id": sel_end.get("telemetry_record_id"),
                "visible_renderable_mesh_count": sel_end.get("visible_renderable_mesh_count"),
                "visibility_invariant_pass": sel_end.get("visibility_invariant_pass"),
            },
        )
    )

    select_ghosts = int(select_analysis["PIXEL_SELECT_RENDER_GHOST_OCCURRENCES"])
    select_viol = int(select_analysis["PIXEL_SELECT_VISIBILITY_INVARIANT_VIOLATIONS"])
    select_pass = (
        select_ghosts == 0
        and select_viol == 0
        and stress["nav_actions"] >= 120
        and stress["roster_sweeps"] >= 20
        and select_analysis["select_rows"] > 0
    )
    select_payload = {
        "PIXEL_CAMPAIGN": "PASS" if select_pass else "FAIL",
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "INSTALL_OK": install_ok,
        "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": select_ghosts,
        "PIXEL_SELECT_VISIBILITY_INVARIANT_VIOLATIONS": select_viol,
        "PIXEL_FALLBACK_RECOVERIES": int(select_analysis["PIXEL_FALLBACK_RECOVERIES"]),
        "PIXEL_PROCESS_DEATHS": int(stress["process_deaths"]),
        "SELECT_NAV_ACTIONS": int(stress["nav_actions"]),
        "PIXEL_FULL_ROSTER_SWEEPS": int(stress["roster_sweeps"]),
        "CONFIRM_BACK_CYCLES": int(stress["confirm_back"]),
        "RANDOM_RESELECTIONS": int(stress["random_reselections"]),
        "TELEMETRY_SELECT_ROWS": int(select_analysis["select_rows"]),
        "NOTE": (
            "Render ghost = expected_visible AND visible_renderable_mesh_count==0. "
            "Process death tracked separately as PIXEL_PROCESS_DEATHS."
        ),
        "captures": [c for c in capture_manifest if str(c.get("name", "")).startswith(("00_", "01_", "02_"))],
        "emitted_at": utc_now(),
    }
    (ART / "WAVE018_PIXEL_SELECT_STRESS_RESULT.json").write_text(json.dumps(select_payload, indent=2) + "\n")
    (PIXEL / "wave018_visibility_trace_select.jsonl").write_text(
        "\n".join(json.dumps(r) for r in pull_trace_rows() if r.get("scene") == "fighter_select") + "\n"
    )

    # ---- Select-to-battle ----
    # Fresh launch so battle telemetry is clean enough; keep cumulative counters via file append.
    if not ensure_aa_foreground("pre_battle"):
        return write_blocked("LAUNCH_FAILED_BEFORE_BATTLE")
    navigate_to_fighter_select([])
    battle_stats = select_to_battle(14)
    time.sleep(0.8)
    battle_analysis = analyze_trace(pull_trace_rows())
    for i, brow in enumerate(battle_analysis.get("latest_battle") or []):
        capture_manifest.append(
            screencap(
                f"03_battle_attempt_{i}",
                telemetry_meta={
                    "scene": "battle",
                    "fighter_id": brow.get("fighter_id"),
                    "telemetry_record_id": brow.get("telemetry_record_id"),
                    "visible_renderable_mesh_count": brow.get("visible_renderable_mesh_count"),
                    "visibility_invariant_pass": brow.get("visibility_invariant_pass"),
                },
            )
        )
    # Extra battle captures for remaining bout indices (screenshot + latest telemetry id)
    latest_ids = [
        r.get("telemetry_record_id")
        for r in pull_trace_rows()
        if r.get("scene") == "battle"
    ]
    for bout in range(2, min(6, battle_stats["launches"])):
        meta = {
            "scene": "battle",
            "fighter_id": None,
            "telemetry_record_id": latest_ids[-1] if latest_ids else None,
            "visible_renderable_mesh_count": None,
            "visibility_invariant_pass": None,
        }
        if latest_ids:
            # bind to most recent battle row
            for r in reversed(pull_trace_rows()):
                if r.get("scene") == "battle":
                    meta = {
                        "scene": "battle",
                        "fighter_id": r.get("fighter_id"),
                        "telemetry_record_id": r.get("telemetry_record_id"),
                        "visible_renderable_mesh_count": r.get("visible_renderable_mesh_count"),
                        "visibility_invariant_pass": r.get("visibility_invariant_pass"),
                    }
                    break
        capture_manifest.append(screencap(f"03_battle_attempt_{bout}", telemetry_meta=meta))

    capture_manifest.append(screencap("04_visibility_end"))
    battle_ghosts = int(battle_analysis["PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES"])
    battle_viol = int(battle_analysis["PIXEL_BATTLE_VISIBILITY_INVARIANT_VIOLATIONS"])
    battle_pass = (
        battle_ghosts == 0
        and battle_viol == 0
        and battle_stats["launches"] >= 14
        and battle_analysis["battle_rows"] > 0
    )
    vis_payload = {
        "PIXEL_CAMPAIGN": "PASS" if battle_pass else "FAIL",
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES": battle_ghosts,
        "PIXEL_BATTLE_VISIBILITY_INVARIANT_VIOLATIONS": battle_viol,
        "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS": int(battle_analysis["PIXEL_VISIBILITY_INVARIANT_VIOLATIONS"]),
        "PIXEL_FALLBACK_RECOVERIES": int(battle_analysis["PIXEL_FALLBACK_RECOVERIES"]),
        "PIXEL_PROCESS_DEATHS": int(battle_stats["process_deaths"]),
        "SELECT_TO_BATTLE_ATTEMPTS": int(battle_stats["launches"]),
        "PIXEL_SELECT_TO_BATTLE_LAUNCHES": int(battle_stats["launches"]),
        "BATTLE_PATHS": battle_stats["paths"],
        "TELEMETRY_BATTLE_ROWS": int(battle_analysis["battle_rows"]),
        "DISAPPEARING_BODY_REPRO_ATTEMPTED": True,
        "NOTE": (
            "Render ghost = expected_visible AND logic_active AND visible_renderable_mesh_count==0. "
            "Process death is NOT counted as a battle render ghost."
        ),
        "captures": [
            c
            for c in capture_manifest
            if str(c.get("name", "")).startswith("03_") or c.get("name") == "04_visibility_end"
        ],
        "emitted_at": utc_now(),
    }
    (ART / "WAVE018_PIXEL_VISIBILITY_RESULT.json").write_text(json.dumps(vis_payload, indent=2) + "\n")
    (PIXEL / "wave018_visibility_trace_full.jsonl").write_text(
        "\n".join(json.dumps(r) for r in pull_trace_rows()) + "\n"
    )

    # ---- 10-minute smoke ----
    if not launch_app():
        return write_blocked("LAUNCH_FAILED_BEFORE_SMOKE")
    navigate_to_fighter_select([])
    for _ in range(12):
        key("66")
        time.sleep(0.4)
    time.sleep(2.0)
    adb("logcat", "-c")
    smoke_sec = int(os.environ.get("WAVE018_PIXEL_SMOKE_SEC", "600"))
    start = time.time()
    deaths = 0
    unauthorized_interrupt = False
    while time.time() - start < smoke_sec:
        if not adb_authorized():
            print("SMOKE INTERRUPTED: adb unauthorized mid-campaign")
            unauthorized_interrupt = True
            break
        if not ensure_aa_foreground("smoke"):
            deaths += 1
            if not launch_app():
                time.sleep(3.0)
                if not launch_app():
                    time.sleep(2.0)
                    continue
            time.sleep(2.0)
            continue
        key("22")
        time.sleep(0.2)
        key("21")
        time.sleep(0.2)
        tap(900, 1900)
        time.sleep(0.8)
        tap(750, 1750)
        time.sleep(1.5)
        if not pidof():
            deaths += 1
            if not launch_app():
                time.sleep(3.0)
                launch_app()
            time.sleep(2.0)
        elapsed = time.time() - start
        if int(elapsed) % 120 < 3:
            smoke_analysis = analyze_trace(pull_trace_rows())
            brow = (smoke_analysis.get("latest_battle") or [{}])[-1]
            capture_manifest.append(
                screencap(
                    f"05_smoke_{int(elapsed)}s",
                    telemetry_meta={
                        "scene": brow.get("scene", "battle"),
                        "fighter_id": brow.get("fighter_id"),
                        "telemetry_record_id": brow.get("telemetry_record_id"),
                        "visible_renderable_mesh_count": brow.get("visible_renderable_mesh_count"),
                        "visibility_invariant_pass": brow.get("visibility_invariant_pass"),
                    },
                )
            )

    log = adb("logcat", "-d", "-t", "4000")
    (PIXEL / "pixel_logcat_smoke.txt").write_text(log.stdout)
    fatals = log.stdout.lower().count("fatal exception")
    anrs = log.stdout.lower().count("anr in")
    ooms = log.stdout.lower().count("out of memory") + log.stdout.lower().count("outofmemory")
    elapsed = time.time() - start
    final_analysis = analyze_trace(pull_trace_rows())
    capture_manifest.append(
        screencap(
            "06_smoke_end",
            telemetry_meta={
                "scene": "battle",
                "fighter_id": None,
                "telemetry_record_id": (final_analysis.get("latest_battle") or [{}])[-1].get(
                    "telemetry_record_id"
                )
                if final_analysis.get("latest_battle")
                else None,
                "visible_renderable_mesh_count": None,
                "visibility_invariant_pass": None,
            },
        )
    )

    smoke_select_ghosts = int(final_analysis["PIXEL_SELECT_RENDER_GHOST_OCCURRENCES"])
    smoke_battle_ghosts = int(final_analysis["PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES"])
    smoke_viol = int(final_analysis["PIXEL_VISIBILITY_INVARIANT_VIOLATIONS"])
    smoke_ok = (
        not unauthorized_interrupt
        and deaths == 0
        and fatals == 0
        and anrs == 0
        and ooms == 0
        and elapsed >= smoke_sec * 0.95
        and smoke_select_ghosts == 0
        and smoke_battle_ghosts == 0
        and smoke_viol == 0
    )
    smoke_payload = {
        "PIXEL_CAMPAIGN": (
            "BLOCKED_PIXEL6A" if unauthorized_interrupt else ("PASS" if smoke_ok else "FAIL")
        ),
        "PIXEL_DEVICE_AVAILABLE": True,
        "PIXEL_AUTHENTIC": True,
        "DEVICE_SERIAL": serial,
        "DEVICE_MODEL": model,
        "PIXEL_SOURCE_SHA": source_sha,
        "APK_SHA256": apk_sha,
        "PIXEL_SMOKE_MIN": round(elapsed / 60.0, 3),
        "PIXEL_FATAL_EXCEPTIONS": fatals,
        "PIXEL_ANR": anrs,
        "PIXEL_OOM": ooms,
        "PIXEL_PROCESS_DEATHS": deaths,
        "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": smoke_select_ghosts,
        "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES": smoke_battle_ghosts,
        "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS": smoke_viol,
        "PIXEL_FALLBACK_RECOVERIES": int(final_analysis["PIXEL_FALLBACK_RECOVERIES"]),
        "UNAUTHORIZED_INTERRUPT": unauthorized_interrupt,
        "PIXEL_SMOKE_TARGET_SEC": smoke_sec,
        "NOTE": "Smoke pass requires zero process deaths AND zero render ghosts/invariant violations.",
        "captures": [
            c
            for c in capture_manifest
            if str(c.get("name", "")).startswith("05_") or c.get("name") == "06_smoke_end"
        ],
        "emitted_at": utc_now(),
    }
    (ART / "WAVE018_PIXEL_SMOKE_RESULT.json").write_text(json.dumps(smoke_payload, indent=2) + "\n")

    (PIXEL / "CAPTURE_MANIFEST.json").write_text(
        json.dumps(
            {
                "PIXEL_AUTHENTIC": True,
                "DEVICE_MODEL": model,
                "DEVICE_SERIAL": serial,
                "PIXEL_SOURCE_SHA": source_sha,
                "APK_SHA256": apk_sha,
                "GHOST_SEMANTICS": "render_ghost != process_death",
                "captures": [c for c in capture_manifest if c.get("ok")],
                "emitted_at": utc_now(),
            },
            indent=2,
        )
        + "\n"
    )
    (PIXEL / "wave018_visibility_counters.json").write_text(
        json.dumps(final_analysis.get("counters") or {}, indent=2) + "\n"
    )

    summary = {
        "select": select_payload,
        "visibility": vis_payload,
        "smoke": smoke_payload,
        "PIXEL_CAMPAIGN": (
            "PASS"
            if select_payload["PIXEL_CAMPAIGN"] == "PASS"
            and vis_payload["PIXEL_CAMPAIGN"] == "PASS"
            and smoke_payload["PIXEL_CAMPAIGN"] == "PASS"
            else "FAIL"
        ),
        "PIXEL_SELECT_RENDER_GHOST_OCCURRENCES": select_ghosts,
        "PIXEL_BATTLE_RENDER_GHOST_OCCURRENCES": battle_ghosts,
        "PIXEL_PROCESS_DEATHS": int(stress["process_deaths"])
        + int(battle_stats["process_deaths"])
        + deaths,
        "PIXEL_FALLBACK_RECOVERIES": int(final_analysis["PIXEL_FALLBACK_RECOVERIES"]),
        "PIXEL_VISIBILITY_INVARIANT_VIOLATIONS": int(
            final_analysis["PIXEL_VISIBILITY_INVARIANT_VIOLATIONS"]
        ),
    }
    (ART / "PIXEL_CAMPAIGN.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))
    return 0 if summary["PIXEL_CAMPAIGN"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
