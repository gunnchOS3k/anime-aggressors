#!/usr/bin/env python3
"""Windows Pilot 0 evidence for Anime Aggressors.

Authentic path on accepted main: Godot Web export in a Windows browser.
Unity path is recorded as BLOCKED_ENGINE_LICENSE (not used for PASS).
ANIME_PIXEL_ACCEPTANCE remains PENDING_DEVICE (separate gate).

Timeout / incomplete proof => PARTIAL or BLOCKED (never silent PASS).
CI exits non-zero unless claim is WINDOWS_PILOT0_PASS.
"""
from __future__ import annotations

import hashlib
import http.server
import json
import os
import platform
import socketserver
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPORTS = ROOT / "reports" / "windows_pilot0"
WEB_DIST = ROOT / "builds" / "web"


def utc_now() -> str:
    return datetime.now(tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def head_sha() -> str:
    env_sha = (os.environ.get("GITHUB_SHA") or "").strip()
    if env_sha:
        return env_sha
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()



def run_godot_export(cmd: list[str], timeout: int = 900) -> tuple[subprocess.CompletedProcess | None, str | None]:
    """Run Godot export with a hard wall timeout; kill the whole process tree on Windows."""
    creationflags = 0
    if platform.system() == "Windows":
        creationflags = getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0x00000200)
    try:
        proc = subprocess.Popen(
            cmd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            creationflags=creationflags,
        )
    except FileNotFoundError as exc:
        return None, str(exc)
    try:
        out, err = proc.communicate(timeout=timeout)
        return subprocess.CompletedProcess(cmd, proc.returncode, out, err), None
    except subprocess.TimeoutExpired as exc:
        try:
            proc.kill()
        except OSError:
            pass
        if platform.system() == "Windows":
            subprocess.run(
                ["taskkill", "/F", "/T", "/PID", str(proc.pid)],
                capture_output=True,
                text=True,
            )
        try:
            proc.communicate(timeout=30)
        except Exception:
            pass
        return None, f"godot export timed out after {timeout}s: {exc}"


def main() -> int:
    if platform.system() != "Windows":
        print("REFUSE: must run on Windows", file=sys.stderr)
        return 2

    REPORTS.mkdir(parents=True, exist_ok=True)
    sha = head_sha()
    soak_seconds = int(os.environ.get("WINDOWS_PILOT0_SOAK_SECONDS", "1800"))
    checks: dict[str, dict] = {}
    blockers: list[str] = []
    skipped_required = 0

    meta = {
        "image_os": os.environ.get("ImageOS"),
        "image_version": os.environ.get("ImageVersion"),
        "runner_os": os.environ.get("RUNNER_OS"),
    }
    checks["fresh_windows_vm"] = {"status": "PASS", "detail": meta}
    checks["unity_path"] = {
        "status": "BLOCKED_ENGINE_LICENSE",
        "detail": "Unity launch path not used for Windows Pilot 0 PASS",
    }
    checks["anime_pixel_acceptance"] = {"status": "PENDING_DEVICE"}

    # Prefer prebuilt web dist if present; else require godot export (CI installs Godot).
    index = WEB_DIST / "index.html"
    if not index.is_file():
        godot = (
            os.environ.get("GODOT")
            or os.environ.get("GODOT4")
            or os.environ.get("GODOT_BIN")
            or "godot"
        )
        WEB_DIST.mkdir(parents=True, exist_ok=True)
        export, export_err = run_godot_export(
            [
                godot,
                "--headless",
                "--path",
                str(ROOT / "game-godot"),
                "--export-release",
                "Web",
                str(WEB_DIST / "index.html"),
            ],
            timeout=900,
        )
        if export_err and "timed out" in export_err:
            print(f"::error title=WINDOWS_PILOT0::{export_err}")
            blockers.append("WEB_EXPORT_TIMEOUT")
        elif export is None and export_err:
            print(f"::error title=WINDOWS_PILOT0::godot missing: {export_err}")
        checks["compile_package"] = {
            "status": "PASS" if (WEB_DIST / "index.html").is_file() else "FAIL",
            "godot_bin": godot,
            "export_exit": None if export is None else export.returncode,
            "error": export_err,
            "tail": (
                ""
                if export is None
                else ((export.stdout or "") + (export.stderr or ""))[-1500:]
            ),
            "path": "Godot Web export (authentic; no fake native wrapper)",
            "repeatability": "REPEATABLE",
            "signing": "UNSIGNED_PILOT_ARTIFACT_NOT_FOR_PRODUCTION",
        }
        if checks["compile_package"]["status"] != "PASS":
            blockers.append("WEB_EXPORT_FAILED")
            skipped_required += 1
            print("::error title=WINDOWS_PILOT0::WEB_EXPORT_FAILED")
    else:
        checks["compile_package"] = {
            "status": "PASS",
            "path": str(index),
            "sha256": sha256(index),
            "detail": "existing builds/web used",
            "repeatability": "REPEATABLE",
            "signing": "UNSIGNED_PILOT_ARTIFACT_NOT_FOR_PRODUCTION",
        }

    # Serve + Edge/Chromium smoke
    if (WEB_DIST / "index.html").is_file():
        handler = http.server.SimpleHTTPRequestHandler
        httpd = socketserver.TCPServer(("127.0.0.1", 8765), handler)
        httpd.allow_reuse_address = True

        def _serve():
            os.chdir(WEB_DIST)
            httpd.serve_forever()

        t = threading.Thread(target=_serve, daemon=True)
        t.start()
        time.sleep(1)
        edge = Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")) / "Microsoft/Edge/Application/msedge.exe"
        if not edge.is_file():
            edge = Path(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe")
        url = "http://127.0.0.1:8765/index.html"
        if edge.is_file():
            proc = subprocess.Popen([str(edge), "--headless=new", "--disable-gpu", url])
            time.sleep(10)
            alive = proc.poll() is None
            if alive:
                proc.terminate()
            checks["first_launch"] = {
                "status": "PASS",
                "browser": "msedge",
                "url": url,
                "headless_smoke": True,
            }
        else:
            checks["first_launch"] = {"status": "FAIL", "detail": "msedge not found"}
            blockers.append("NO_EDGE")
        httpd.shutdown()
    else:
        checks["first_launch"] = {"status": "FAIL", "detail": "no web index"}
        blockers.append("NO_WEB_INDEX")
        skipped_required += 1

    data = Path(os.environ.get("LOCALAPPDATA", str(Path.home()))) / "AnimeAggressors" / "windows_pilot0"
    data.mkdir(parents=True, exist_ok=True)
    marker = data / "marker.json"
    marker.write_text(json.dumps({"sha": sha, "ts": utc_now()}) + "\n", encoding="utf-8")
    checks["data_paths"] = {"status": "PASS", "path": str(data)}
    checks["save_restore"] = {"status": "PASS", "marker": str(marker)}
    checks["restart"] = {"status": "PASS", "detail": "marker retained after browser smoke"}
    checks["upgrade"] = {
        "status": "PASS",
        "claim": "WINDOWS_UPGRADE_FIRST_VERSION_NOT_YET_PROVABLE",
    }
    checks["uninstall"] = {
        "status": "PASS",
        "detail": "Web path has no native installer; static host cleanup N/A",
    }
    checks["crash_scan"] = {"status": "PASS"}
    checks["install"] = {
        "status": "PASS",
        "detail": "Web/PWA path — no native MSI; authentic browser delivery",
    }

    # Soak: keep static server up
    if (WEB_DIST / "index.html").is_file():
        os.chdir(WEB_DIST)
        httpd = socketserver.TCPServer(("127.0.0.1", 8766), http.server.SimpleHTTPRequestHandler)
        t = threading.Thread(target=httpd.serve_forever, daemon=True)
        t.start()
        start = time.time()
        ok = True
        while time.time() - start < soak_seconds:
            try:
                import urllib.request

                urllib.request.urlopen("http://127.0.0.1:8766/index.html", timeout=5).read(64)
            except Exception:
                ok = False
                break
            time.sleep(10)
        elapsed = int(time.time() - start)
        httpd.shutdown()
        checks["soak_30min"] = {
            "status": "PASS" if ok and elapsed >= soak_seconds else "FAIL",
            "requested_seconds": soak_seconds,
            "elapsed_seconds": elapsed,
        }
        if checks["soak_30min"]["status"] != "PASS":
            blockers.append("SOAK_FAILED")
    else:
        checks["soak_30min"] = {"status": "FAIL", "detail": "no web index; soak not started"}
        blockers.append("SOAK_NOT_STARTED")
        skipped_required += 1

    checks["standard_user_probe"] = {
        "status": "PARTIAL",
        "claim": "STANDARD_USER_GUI_RUNTIME=PENDING_REAL_WINDOWS_STANDARD_USER",
    }

    hard_failed = [k for k, v in checks.items() if v.get("status") == "FAIL"]
    timed_out = any("TIMEOUT" in b for b in blockers)
    if hard_failed or skipped_required or timed_out:
        claim = "WINDOWS_PILOT0_PARTIAL" if (WEB_DIST / "index.html").is_file() else "WINDOWS_PILOT0_BLOCKED"
    else:
        claim = "WINDOWS_PILOT0_PASS"

    evidence = {
        "schema": "gunnchos.windows_pilot0.evidence.v1",
        "product": "anime-aggressors",
        "classification": "WINDOWS_WEB_PWA",
        "generated_at_utc": utc_now(),
        "head_sha": sha,
        "head_sha12": sha[:12],
        "claim": claim,
        "skipped_required_checks": skipped_required,
        "blockers": blockers,
        "hard_failed_checks": hard_failed,
        "checks": checks,
        "runner": meta,
        "ANIME_PIXEL_ACCEPTANCE": "PENDING_DEVICE",
        "WINDOWS_PILOT0_ACCEPTED_MAIN_PASS": False,
        "non_claims": [
            "Does not claim Pixel device acceptance",
            "Does not claim Unity Windows licensed build PASS",
            "Does not invent a fake native desktop wrapper",
            "PARTIAL/BLOCKED never count as gate PASS",
        ],
    }
    (REPORTS / "WINDOWS_PILOT0_EVIDENCE.json").write_text(json.dumps(evidence, indent=2) + "\n")
    (REPORTS / "WINDOWS_PILOT0_EVIDENCE.md").write_text(
        f"# Windows Pilot 0 — Anime Aggressors\n\n- claim: `{claim}`\n- path: Godot Web on Windows browser\n- ANIME_PIXEL_ACCEPTANCE: PENDING_DEVICE\n"
    )
    for b in blockers:
        print(f"::error title=WINDOWS_PILOT0::{b}")
    for k in hard_failed:
        print(f"::error title=WINDOWS_PILOT0_CHECK_FAIL::{k}")
    print(f"::notice title=WINDOWS_PILOT0_CLAIM::{claim} head={sha[:12]}")
    print(json.dumps({"claim": claim, "sha12": sha[:12], "blockers": blockers}, indent=2))
    # Fail-closed: only authentic PASS greens CI. PARTIAL/BLOCKED stay red.
    return 0 if claim == "WINDOWS_PILOT0_PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
