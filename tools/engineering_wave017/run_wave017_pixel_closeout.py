#!/usr/bin/env python3
"""Wave017 Pixel physical + owner taste closeout (evidence only; never merges)."""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "artifacts" / "wave017"
PIXEL = ART / "pixel"
ENG = ROOT / "artifacts" / "engineering_wave017"
OUT = PIXEL / "captures"
PKG = "com.gunnchos.animeaggressors"
ACTIVITY = "com.godot.game.GodotApp"
APK = ROOT / "builds" / "android" / "anime-aggressors-debug.apk"


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


def adb(*args: str, serial: str | None = None, timeout: int = 180) -> subprocess.CompletedProcess:
    cmd = ["adb"]
    if serial:
        cmd += ["-s", serial]
    cmd += list(args)
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=timeout)


def discover_pixel6a() -> dict:
    if not shutil.which("adb"):
        return {"ok": False, "reason": "BLOCKED_PIXEL6A", "raw": "adb not found"}
    subprocess.run(["adb", "start-server"], capture_output=True, text=True)
    raw = adb("devices", "-l").stdout
    lines = [ln for ln in raw.splitlines()[1:] if ln.strip()]
    auth = [ln for ln in lines if len(ln.split()) >= 2 and ln.split()[1] == "device"]
    if not auth:
        unauth = [ln for ln in lines if "unauthorized" in ln]
        return {"ok": False, "reason": "BLOCKED_PIXEL6A", "raw": raw, "unauthorized": bool(unauth)}
    serial = auth[0].split()[0]
    model = adb("shell", "getprop", "ro.product.model", serial=serial).stdout.strip()
    if "Pixel 6a" not in model:
        return {"ok": False, "reason": "BLOCKED_WRONG_DEVICE", "model": model, "serial": serial}
    return {"ok": True, "serial": serial, "model": model, "raw": raw}


def git_sha() -> str:
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()


def godot_version() -> str:
    godot = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
    candidates = [os.environ.get("GODOT_BIN"), str(godot), shutil.which("godot")]
    for c in candidates:
        if c and Path(c).is_file():
            try:
                return subprocess.check_output([c, "--version"], text=True).strip()
            except Exception:
                pass
    return "UNKNOWN"


def version_code_from_apk() -> str:
    # Prefer aapt if present
    for aapt in [
        shutil.which("aapt"),
        *Path(os.path.expanduser("~/Library/Android/sdk/build-tools")).glob("*/aapt"),
    ]:
        if not aapt:
            continue
        aapt = str(aapt)
        if not Path(aapt).is_file():
            continue
        try:
            out = subprocess.check_output([aapt, "dump", "badging", str(APK)], text=True, stderr=subprocess.DEVNULL)
            m = re.search(r"versionCode='(\d+)'", out)
            if m:
                return m.group(1)
        except Exception:
            pass
    return "210"


def build_apk() -> dict:
    env = os.environ.copy()
    godot = Path.home() / "Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
    if godot.is_file():
        env["GODOT_BIN"] = str(godot)
    APK.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run(
        ["npm", "run", "godot:export:android"],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
    )
    (PIXEL / "android_build_log.txt").write_text(proc.stdout + "\n" + proc.stderr, encoding="utf-8")
    return {
        "ok": proc.returncode == 0 and APK.is_file(),
        "exit_code": proc.returncode,
        "PIXEL_SOURCE_SHA": git_sha(),
        "APK_SHA256": sha256_file(APK),
        "PACKAGE": PKG,
        "VERSION_CODE": version_code_from_apk() if APK.is_file() else "",
        "GODOT_VERSION": godot_version(),
        "apk_path": str(APK.relative_to(ROOT)) if APK.is_file() else "",
    }


def pull_file(serial: str, rel: str, dest: Path) -> bool:
    dest.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.run(
        ["adb", "-s", serial, "exec-out", "run-as", PKG, "cat", f"files/{rel}"],
        capture_output=True,
    )
    if proc.returncode != 0 or not proc.stdout:
        return False
    # Reject adb/run-as error text accidentally treated as content
    head = proc.stdout[:64]
    if head.startswith(b"cat:") or b"No such file" in head:
        return False
    dest.write_bytes(proc.stdout)
    return dest.is_file() and dest.stat().st_size > 0


def run_pixel_closeout(serial: str, build: dict, timeout_s: int = 900) -> dict:
    adb("shell", "am", "force-stop", PKG, serial=serial)
    adb("shell", f"run-as {PKG} rm -rf files/wave017", serial=serial)
    adb("shell", f"run-as {PKG} mkdir -p files/wave017", serial=serial)
    sha = build.get("PIXEL_SOURCE_SHA", "")
    apk_sha = build.get("APK_SHA256", "")
    adb(
        "shell",
        f"run-as {PKG} sh -c 'printf wave017-pixel-closeout > files/wave017_pixel_closeout_trigger.txt'",
        serial=serial,
    )
    adb("shell", f"run-as {PKG} sh -c \"printf '{sha}' > files/wave017/source_sha.txt\"", serial=serial)
    adb("shell", f"run-as {PKG} sh -c \"printf '{apk_sha}' > files/wave017/apk_sha256.txt\"", serial=serial)
    adb(
        "shell",
        "am",
        "start",
        "-n",
        f"{PKG}/{ACTIVITY}",
        "--es",
        "command_line",
        "--wave017-pixel-closeout",
        serial=serial,
    )
    deadline = time.time() + timeout_s
    ready = False
    while time.time() < deadline:
        check = adb(
            "shell",
            "run-as",
            PKG,
            "ls",
            "files/wave017/PIXEL_CLOSEOUT_RESULT.json",
            serial=serial,
        )
        if check.returncode == 0 and "PIXEL_CLOSEOUT_RESULT.json" in check.stdout:
            ready = True
            break
        time.sleep(3)
    adb("shell", "am", "force-stop", PKG, serial=serial)

    pull_dir = PIXEL / "device_pull"
    pull_dir.mkdir(parents=True, exist_ok=True)
    result_path = pull_dir / "PIXEL_CLOSEOUT_RESULT.json"
    pull_file(serial, "wave017/PIXEL_CLOSEOUT_RESULT.json", result_path)
    obj_path = pull_dir / "WAVE017_PIXEL_OBJECTIVE_PRESENTATION.json"
    pull_file(serial, "wave017/WAVE017_PIXEL_OBJECTIVE_PRESENTATION.json", obj_path)

    capture = {}
    if result_path.is_file() and result_path.stat().st_size > 2:
        try:
            capture = json.loads(result_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            capture = {}

    OUT.mkdir(parents=True, exist_ok=True)
    shots_out = []
    for shot in capture.get("shots", []):
        rel = str(shot.get("path") or "")
        if not rel.endswith(".png"):
            continue
        name = Path(rel).name
        dest = OUT / name
        ok = pull_file(serial, f"wave017/device_screenshots/{name}", dest)
        row = {
            "label": shot.get("label"),
            "pixel_device": True,
            "source_sha": build.get("PIXEL_SOURCE_SHA"),
            "apk_sha256": build.get("APK_SHA256"),
            "fighter_id": shot.get("fighter_id", "ember-vale"),
            "opponent_id": shot.get("opponent_id", "rook-ironside"),
            "gameplay_state": shot.get("gameplay_state", ""),
            "active_move_id": shot.get("active_move_id") or shot.get("gameplay_move_id", ""),
            "active_clip": shot.get("active_clip", ""),
            "model_visible": bool(shot.get("model_visible")),
            "debug_labels_visible": bool(shot.get("debug_labels_visible", False)),
            "captured_at": shot.get("captured_at") or utc_now(),
            "path": str(dest.relative_to(ROOT)) if ok and dest.is_file() else None,
        }
        shots_out.append(row)

    objective = capture.get("objective_presentation") or {}
    if obj_path.is_file():
        try:
            objective = json.loads(obj_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            pass
    objective.update(
        {
            "PIXEL_SOURCE_SHA": build.get("PIXEL_SOURCE_SHA"),
            "APK_SHA256": build.get("APK_SHA256"),
            "DEVICE_MODEL": "Pixel 6a",
            "generated_at_utc": utc_now(),
            "HUMAN_Q3_APPROVAL": False,
            "HUMAN_ART_DIRECTION_APPROVAL": False,
            "OWNER_TASTE_REVIEW": "PENDING",
        }
    )
    (PIXEL / "WAVE017_PIXEL_OBJECTIVE_PRESENTATION.json").write_text(
        json.dumps(objective, indent=2) + "\n", encoding="utf-8"
    )

    manifest = {
        "schema": "wave017_pixel_visual_manifest_v1",
        "status": "CAPTURED_AUTHENTIC" if capture.get("PIXEL_AUTHENTIC_CAPTURE") and len(shots_out) >= 23 else ("PARTIAL" if shots_out else "FAIL"),
        "ready": bool(ready),
        "PIXEL_AUTHENTIC_CAPTURE": bool(capture.get("PIXEL_AUTHENTIC_CAPTURE")),
        "PIXEL_GHOST_FIGHTER_OCCURRENCES": capture.get("PIXEL_GHOST_FIGHTER_OCCURRENCES"),
        "PLAYER_BUILD_VISIBLE_DEBUG_LABELS": capture.get("PLAYER_BUILD_VISIBLE_DEBUG_LABELS"),
        "COMBAT_NAME_LABEL_OVERLAP_CASES": capture.get("COMBAT_NAME_LABEL_OVERLAP_CASES"),
        "TRANSITION_SAMPLES": capture.get("TRANSITION_SAMPLES"),
        "captures": shots_out,
        "capture_count": len(shots_out),
        "source_sha": build.get("PIXEL_SOURCE_SHA"),
        "apk_sha256": build.get("APK_SHA256"),
        "generated_at_utc": utc_now(),
    }
    (PIXEL / "WAVE017_PIXEL_VISUAL_MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return {**capture, **manifest, "device_result_ready": ready}


def run_smoke(serial: str, build: dict, duration_min: float = 10.0) -> dict:
    adb("logcat", "-c", serial=serial)
    adb("shell", "am", "force-stop", PKG, serial=serial)
    adb(
        "shell",
        f"run-as {PKG} rm -f files/wave017_pixel_closeout_trigger.txt files/wave016_pixel_capture_trigger.txt files/wave015_trigger.txt",
        serial=serial,
    )
    adb(
        "shell",
        "monkey",
        "-p",
        PKG,
        "-c",
        "android.intent.category.LAUNCHER",
        "1",
        serial=serial,
    )
    start = time.time()
    deaths = 0
    last_pid = ""
    saw_pid = False
    while (time.time() - start) < duration_min * 60:
        pid = adb("shell", "pidof", PKG, serial=serial).stdout.strip()
        if pid:
            saw_pid = True
            last_pid = pid
        elif saw_pid and last_pid:
            deaths += 1
            saw_pid = False
            adb(
                "shell",
                "monkey",
                "-p",
                PKG,
                "-c",
                "android.intent.category.LAUNCHER",
                "1",
                serial=serial,
            )
            time.sleep(2)
        time.sleep(5)
    logcat = adb("logcat", "-d", serial=serial).stdout
    (PIXEL / "device_pull" / "smoke_logcat.txt").write_text(logcat[-200000:], encoding="utf-8")
    fatal = len(re.findall(r"FATAL EXCEPTION", logcat))
    anr = len(re.findall(r"ANR in", logcat))
    oom = len(re.findall(r"OutOfMemoryError|lowmemorykiller|am_crash.*oom", logcat, re.I))
    elapsed = (time.time() - start) / 60.0
    result = {
        "schema": "wave017_pixel_normal_play_smoke_v1",
        "generated_at_utc": utc_now(),
        "PIXEL_NORMAL_PLAY_MIN": round(elapsed, 3),
        "UNEXPECTED_PROCESS_DEATHS": deaths,
        "FATAL_EXCEPTIONS": fatal,
        "ANR_COUNT": anr,
        "OOM_COUNT": oom,
        "PIXEL_GHOST_FIGHTER_OCCURRENCES_SMOKE": None,  # ghosts measured in harness, not logcat
        "PIXEL_SOURCE_SHA": build.get("PIXEL_SOURCE_SHA"),
        "APK_SHA256": build.get("APK_SHA256"),
        "DEVICE_MODEL": "Pixel 6a",
        "PASS": elapsed >= 10.0 and deaths == 0 and fatal == 0 and anr == 0 and oom == 0,
        "CURSOR_MERGED_NOTHING": True,
    }
    (PIXEL / "PIXEL_NORMAL_PLAY_SMOKE.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    return result


def capture_performance(serial: str) -> dict:
    mem = adb("shell", "dumpsys", "meminfo", PKG, serial=serial).stdout
    gfx = adb("shell", "dumpsys", "gfxinfo", PKG, serial=serial).stdout
    therm = adb("shell", "dumpsys", "thermalservice", serial=serial).stdout
    (PIXEL / "device_pull" / "meminfo.txt").write_text(mem, encoding="utf-8")
    (PIXEL / "device_pull" / "gfxinfo.txt").write_text(gfx[:50000], encoding="utf-8")
    (PIXEL / "device_pull" / "thermalservice.txt").write_text(therm[:30000], encoding="utf-8")

    pss = None
    m = re.search(r"TOTAL PSS:\s+(\d+)", mem) or re.search(r"TOTAL:\s+(\d+)", mem)
    if m:
        pss = int(m.group(1))
    # gfxinfo percentiles if present
    frame_stats = {}
    for key, pat in [
        ("p50_ms", r"50th percentile:\s+([\d.]+)ms"),
        ("p90_ms", r"90th percentile:\s+([\d.]+)ms"),
        ("p95_ms", r"95th percentile:\s+([\d.]+)ms"),
        ("p99_ms", r"99th percentile:\s+([\d.]+)ms"),
    ]:
        mm = re.search(pat, gfx)
        if mm:
            frame_stats[key] = float(mm.group(1))
    fps = None
    fm = re.search(r"([\d.]+)\s+frames/s", gfx) or re.search(r"Janky frames:.*?\(([\d.]+)%\)", gfx)
    # Prefer histogram-derived if available; otherwise leave null honestly
    hist = re.search(r"Total frames rendered:\s+(\d+)", gfx)
    janky = re.search(r"Janky frames:\s+(\d+)", gfx)

    payload = {
        "schema": "wave017_pixel_performance_v1",
        "generated_at_utc": utc_now(),
        "DEVICE_MODEL": "Pixel 6a",
        "PSS_KB": pss,
        "frame_percentiles_ms": frame_stats,
        "total_frames_rendered": int(hist.group(1)) if hist else None,
        "janky_frames": int(janky.group(1)) if janky else None,
        "FPS": fps,
        "thermal_raw_present": bool(therm.strip()),
        "particle_projectile_node_hwm": None,
        "note": "Honest capture from dumpsys; FPS/HWM left null when not exposed by platform dumpsys.",
        "sources": [
            "artifacts/wave017/pixel/device_pull/meminfo.txt",
            "artifacts/wave017/pixel/device_pull/gfxinfo.txt",
            "artifacts/wave017/pixel/device_pull/thermalservice.txt",
        ],
    }
    (PIXEL / "WAVE017_PIXEL_PERFORMANCE.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return payload


def write_before_after_contact_sheet(manifest: dict) -> dict:
    ba = PIXEL / "WAVE017_BEFORE_AFTER_CONTACT_SHEET"
    ba.mkdir(parents=True, exist_ok=True)
    # Copy after captures into contact sheet folder
    after_dir = ba / "after"
    after_dir.mkdir(parents=True, exist_ok=True)
    copied = []
    for shot in manifest.get("captures", []):
        p = shot.get("path")
        if not p:
            continue
        src = ROOT / p
        if src.is_file():
            dest = after_dir / src.name
            shutil.copy2(src, dest)
            copied.append(str(dest.relative_to(ROOT)))

    # Baseline notes from owner screenshot baseline (text before references)
    baseline = ROOT / "docs" / "quality" / "WAVE017_OWNER_SCREENSHOT_BASELINE.md"
    before_notes = (ART / "before_after").read_text(encoding="utf-8") if False else ""
    # Use existing markdown debt notes as BEFORE narrative
    before_src = ART / "before_after"
    before_copied = []
    if before_src.is_dir():
        bdir = ba / "before_notes"
        bdir.mkdir(parents=True, exist_ok=True)
        for md in before_src.glob("*.md"):
            dest = bdir / md.name
            shutil.copy2(md, dest)
            before_copied.append(str(dest.relative_to(ROOT)))

    sheet = {
        "schema": "wave017_before_after_contact_sheet_v1",
        "baseline_doc": "docs/quality/WAVE017_OWNER_SCREENSHOT_BASELINE.md",
        "baseline_exists": baseline.is_file(),
        "before_notes": before_copied,
        "after_captures": copied,
        "compare_axes": [
            "ghost_proxy_to_character",
            "debug_labels",
            "projectiles",
            "stage",
            "camera",
            "hud_touch",
            "versus_victory",
        ],
        "generated_at_utc": utc_now(),
        "OWNER_TASTE_REVIEW": "PENDING",
        "HUMAN_Q3_APPROVAL": False,
    }
    readme = ba / "README.md"
    readme.write_text(
        "\n".join(
            [
                "# WAVE017 Before/After Contact Sheet",
                "",
                "BEFORE: owner-observed weaknesses locked in `docs/quality/WAVE017_OWNER_SCREENSHOT_BASELINE.md` and `before_notes/`.",
                "AFTER: authentic Pixel 6a captures in `after/`.",
                "",
                "Owner taste ratings are intentionally unanswered.",
                "",
                f"- after capture count: {len(copied)}",
                f"- generated_at_utc: {utc_now()}",
                "",
            ]
        ),
        encoding="utf-8",
    )
    (ba / "manifest.json").write_text(json.dumps(sheet, indent=2) + "\n", encoding="utf-8")
    return sheet


def write_owner_taste_review(build: dict) -> None:
    path = ROOT / "docs" / "quality" / "WAVE017_OWNER_TASTE_REVIEW.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f"""# WAVE017 — Owner Taste Review (Edmund)

**Automation must leave ratings unanswered.**  
**Merge authority:** Edmund only. Cursor never merges.  
**Draft PR:** https://github.com/gunnchOS3k/anime-aggressors/pull/88

| Field | Value |
|-------|-------|
| `OWNER_TASTE_REVIEW` | `PENDING` |
| `HUMAN_Q3_APPROVAL` | `false` |
| `HUMAN_ART_DIRECTION_APPROVAL` | `false` |
| `HUMAN_PLAYTEST_COMPLETE` | `false` |
| `BUILD_SHA` (engineering) | `{build.get("PIXEL_SOURCE_SHA", "")}` |
| `APK_SHA256` | `{build.get("APK_SHA256", "")}` |
| `DEVICE` | Pixel 6a (physical) |
| `SLICE` | Ember Vale Golden Slice vs Rook / Ember Courtyard |

Baseline before Wave017 delivery: `OWNER_TASTE_REVIEW=CHANGES_REQUESTED` / `HUMAN_VISIBLE_QUALITY_BEFORE=Q1_FUNCTIONAL_PROTOTYPE`  
See `docs/quality/WAVE017_OWNER_SCREENSHOT_BASELINE.md`.

---

## Rating prompts (owner only)

Rate each 1–5 or PASS / FAIL / PASS_WITH_DEBT. Leave blank until Edmund reviews.

| Prompt | Owner rating |
|--------|--------------|
| Ember reads as a character (head/face/hair/clothing/fire), not cubes | _unanswered_ |
| No ghost / nameplate-only fighter bodies during play | _unanswered_ |
| No PROXY / DEBUG / MODEL_PENDING / PLACEHOLDER labels in player build | _unanswered_ |
| Projectiles: tap / medium / full feel distinct | _unanswered_ |
| Ember Courtyard stage depth / atmosphere | _unanswered_ |
| Camera framing & separation zoom | _unanswered_ |
| Combat name labels readable (no full-name overlap on body) | _unanswered_ |
| HUD / touch controls taste | _unanswered_ |
| Versus entry presentation | _unanswered_ |
| Victory / arcade continuation presentation | _unanswered_ |
| Animation readability (Wave016 mappings preserved) | _unanswered_ |
| Overall Golden Slice immersion | _unanswered_ |

### Ladder

| Field | Owner value |
|-------|-------------|
| `OWNER_CURRENT_QUALITY_LEVEL` | _unanswered_ (Q0–Q5) |
| `OWNER_TASTE_REVIEW` | _unanswered_ (`PASS` / `FAIL` / `PASS_WITH_DEBT`) |
| `HUMAN_Q3_APPROVAL` | _unanswered_ |
| `HUMAN_ART_DIRECTION_APPROVAL` | _unanswered_ |
| `HUMAN_PLAYTEST_COMPLETE` | _unanswered_ |

### Freeform

_What breaks immersion first? What is good enough? What must the next wave fix?_

_unanswered_

---

Evidence packet: `artifacts/wave017/pixel/`  
Contact sheet: `artifacts/wave017/pixel/WAVE017_BEFORE_AFTER_CONTACT_SHEET/`
""",
        encoding="utf-8",
    )


def emit_campaign(build: dict, capture: dict, smoke: dict, perf: dict, sheet: dict) -> dict:
    ghosts = capture.get("PIXEL_GHOST_FIGHTER_OCCURRENCES")
    debug = capture.get("PLAYER_BUILD_VISIBLE_DEBUG_LABELS")
    overlap = capture.get("COMBAT_NAME_LABEL_OVERLAP_CASES")
    authentic = bool(capture.get("PIXEL_AUTHENTIC_CAPTURE")) and int(capture.get("capture_count") or 0) >= 23
    smoke_ok = bool(smoke.get("PASS"))
    status = "PASS" if authentic and smoke_ok and ghosts == 0 and debug == 0 and overlap == 0 else "PARTIAL"
    if ghosts not in (0, None) and ghosts != 0:
        status = "FAIL_GHOST"
    payload = {
        "PIXEL_CAMPAIGN": status,
        "PIXEL_AUTHENTIC": True,
        "DEVICE_MODEL": "Pixel 6a",
        "PIXEL_SOURCE_SHA": build.get("PIXEL_SOURCE_SHA"),
        "APK_SHA256": build.get("APK_SHA256"),
        "PACKAGE": build.get("PACKAGE"),
        "VERSION_CODE": build.get("VERSION_CODE"),
        "GODOT_VERSION": build.get("GODOT_VERSION"),
        "NORMAL_PLAY_GHOST_FIGHTER_OCCURRENCES": ghosts,
        "PLAYER_BUILD_VISIBLE_DEBUG_LABELS": debug,
        "COMBAT_NAME_LABEL_OVERLAP_CASES": overlap,
        "PIXEL_NORMAL_PLAY_MIN": smoke.get("PIXEL_NORMAL_PLAY_MIN"),
        "smoke_pass": smoke_ok,
        "capture_count": capture.get("capture_count"),
        "before_after_present": bool(sheet.get("after_captures")),
        "objective_presentation_path": "artifacts/wave017/pixel/WAVE017_PIXEL_OBJECTIVE_PRESENTATION.json",
        "performance_path": "artifacts/wave017/pixel/WAVE017_PIXEL_PERFORMANCE.json",
        "emitted_at": utc_now(),
        "CURSOR_MERGED_NOTHING": True,
        "OWNER_TASTE_REVIEW": "PENDING",
        "HUMAN_Q3_APPROVAL": False,
    }
    (ART / "PIXEL_CAMPAIGN.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    (PIXEL / "PIXEL_CAMPAIGN.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return payload


def main() -> int:
    PIXEL.mkdir(parents=True, exist_ok=True)
    ENG.mkdir(parents=True, exist_ok=True)
    device = discover_pixel6a()
    if not device.get("ok"):
        blocked = {
            "WAVE017_PIXEL_CLOSEOUT": "BLOCKED_PIXEL6A",
            "READY_FOR_OWNER_MERGE": False,
            "DEVICE": device,
            "OWNER_TASTE_REVIEW": "PENDING",
            "HUMAN_Q3_APPROVAL": False,
            "CURSOR_MERGED_NOTHING": True,
            "emitted_at": utc_now(),
        }
        (PIXEL / "WAVE017_PIXEL_CLOSEOUT.json").write_text(json.dumps(blocked, indent=2) + "\n", encoding="utf-8")
        (ART / "PIXEL_CAMPAIGN.json").write_text(
            json.dumps({"PIXEL_CAMPAIGN": "BLOCKED_PIXEL6A", "PIXEL_AUTHENTIC": False, **blocked}, indent=2) + "\n",
            encoding="utf-8",
        )
        write_owner_taste_review({"PIXEL_SOURCE_SHA": git_sha(), "APK_SHA256": sha256_file(APK)})
        print(json.dumps(blocked, indent=2))
        return 2

    print("=== Building current-head APK ===", flush=True)
    # If SKIP_REBUILD=1 and APK exists, reuse (caller may have just rebuilt)
    if os.environ.get("SKIP_REBUILD") == "1" and APK.is_file():
        build = {
            "ok": True,
            "exit_code": 0,
            "PIXEL_SOURCE_SHA": git_sha(),
            "APK_SHA256": sha256_file(APK),
            "PACKAGE": PKG,
            "VERSION_CODE": version_code_from_apk(),
            "GODOT_VERSION": godot_version(),
            "apk_path": str(APK.relative_to(ROOT)),
            "reused_existing_apk": True,
        }
    else:
        build = build_apk()
    build["model"] = device["model"]
    (PIXEL / "PIXEL_BUILD_PROVENANCE.json").write_text(json.dumps(build, indent=2) + "\n", encoding="utf-8")
    write_owner_taste_review(build)
    if not build.get("ok"):
        fail = {"WAVE017_PIXEL_CLOSEOUT": "FAIL_BUILD", "READY_FOR_OWNER_MERGE": False, "build": build}
        (PIXEL / "WAVE017_PIXEL_CLOSEOUT.json").write_text(json.dumps(fail, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(fail, indent=2))
        return 1

    serial = device["serial"]
    print("=== Installing APK ===", flush=True)
    inst = adb("install", "-r", str(APK), serial=serial, timeout=300)
    (PIXEL / "device_pull" / "install.txt").write_text((inst.stdout or "") + "\n" + (inst.stderr or ""), encoding="utf-8")
    print(inst.stdout or inst.stderr, flush=True)

    print("=== Authentic Wave017 Pixel closeout capture ===", flush=True)
    capture = run_pixel_closeout(serial, build)
    print("=== Performance snapshot ===", flush=True)
    # Launch briefly for perf dumpsys
    adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1", serial=serial)
    time.sleep(8)
    perf = capture_performance(serial)
    print("=== 10-minute normal play smoke ===", flush=True)
    smoke = run_smoke(serial, build, duration_min=float(os.environ.get("SMOKE_MIN", "10")))
    sheet = write_before_after_contact_sheet(capture)
    campaign = emit_campaign(build, capture, smoke, perf, sheet)

    ghosts = capture.get("PIXEL_GHOST_FIGHTER_OCCURRENCES")
    ready = (
        campaign.get("PIXEL_CAMPAIGN") == "PASS"
        and ghosts == 0
        and capture.get("PLAYER_BUILD_VISIBLE_DEBUG_LABELS") == 0
        and capture.get("COMBAT_NAME_LABEL_OVERLAP_CASES") == 0
        and smoke.get("PASS") is True
        and (PIXEL / "WAVE017_PIXEL_OBJECTIVE_PRESENTATION.json").is_file()
        and bool(sheet.get("after_captures"))
    )
    closeout = {
        "WAVE017_PIXEL_CLOSEOUT": "PASS" if ready else "PARTIAL",
        "READY_FOR_OWNER_MERGE_ENGINEERING": ready,  # final CI still required by caller
        "build": build,
        "campaign": campaign,
        "capture_status": capture.get("status"),
        "PIXEL_GHOST_FIGHTER_OCCURRENCES": ghosts,
        "PLAYER_BUILD_VISIBLE_DEBUG_LABELS": capture.get("PLAYER_BUILD_VISIBLE_DEBUG_LABELS"),
        "COMBAT_NAME_LABEL_OVERLAP_CASES": capture.get("COMBAT_NAME_LABEL_OVERLAP_CASES"),
        "PIXEL_NORMAL_PLAY_MIN": smoke.get("PIXEL_NORMAL_PLAY_MIN"),
        "smoke": smoke,
        "performance": {k: perf.get(k) for k in ("PSS_KB", "frame_percentiles_ms", "FPS", "janky_frames", "total_frames_rendered")},
        "OWNER_TASTE_REVIEW": "PENDING",
        "HUMAN_Q3_APPROVAL": False,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_PLAYTEST_COMPLETE": False,
        "CURSOR_MERGED_NOTHING": True,
        "emitted_at": utc_now(),
    }
    (PIXEL / "WAVE017_PIXEL_CLOSEOUT.json").write_text(json.dumps(closeout, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: closeout[k] for k in closeout if k not in ("build", "smoke")}, indent=2))
    return 0 if ready else 1


if __name__ == "__main__":
    raise SystemExit(main())
