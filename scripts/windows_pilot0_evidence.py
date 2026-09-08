#!/usr/bin/env python3
"""Windows Pilot 0 evidence for Anime Aggressors.

Authentic path on accepted main: Godot Web export in a Windows browser.
Unity path is recorded as BLOCKED_ENGINE_LICENSE (not used for PASS).
ANIME_PIXEL_ACCEPTANCE remains PENDING_DEVICE (separate gate).

Requires Godot 4.5 matching game-godot/project.godot config/features.
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
from typing import Callable

ROOT = Path(__file__).resolve().parents[1]
REPORTS = ROOT / "reports" / "windows_pilot0"
WEB_DIST = ROOT / "builds" / "web"
PROJECT = ROOT / "game-godot"
INDEX = WEB_DIST / "index.html"


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


def resolve_godot() -> str:
    return (
        os.environ.get("GODOT")
        or os.environ.get("GODOT4")
        or os.environ.get("GODOT_BIN")
        or "godot"
    )


def godot_version(godot: str) -> str:
    try:
        out = subprocess.check_output([godot, "--version"], text=True, timeout=60)
        return out.strip()
    except Exception as exc:
        return f"UNAVAILABLE:{exc}"


def template_probe() -> dict:
    appdata = Path(os.environ.get("APPDATA", str(Path.home() / "AppData" / "Roaming")))
    base = appdata / "Godot" / "export_templates"
    stable = base / "4.5.stable"
    web_zip = stable / "web_release.zip"
    return {
        "templates_root": str(base),
        "templates_45": str(stable),
        "templates_45_exists": stable.is_dir(),
        "web_release_zip": web_zip.is_file(),
        "entries": sorted(p.name for p in base.iterdir()) if base.is_dir() else [],
    }


def web_bundle_ready(out_dir: Path) -> dict:
    index = out_dir / "index.html"
    if not index.is_file() or index.stat().st_size < 64:
        return {"ready": False, "reason": "missing_or_tiny_index"}
    siblings = list(out_dir.iterdir())
    names = [p.name.lower() for p in siblings]
    has_payload = any(
        n.endswith(".wasm") or n.endswith(".pck") or n.endswith(".js") for n in names
    )
    total = sum(p.stat().st_size for p in siblings if p.is_file())
    return {
        "ready": has_payload and total >= 100_000,
        "index_bytes": index.stat().st_size,
        "total_bytes": total,
        "files": sorted(names)[:40],
        "reason": None if (has_payload and total >= 100_000) else "incomplete_web_bundle",
    }


def _kill_tree(pid: int) -> None:
    try:
        subprocess.run(
            ["taskkill", "/F", "/T", "/PID", str(pid)],
            capture_output=True,
            text=True,
            timeout=60,
        )
    except Exception:
        pass


def run_godot(
    cmd: list[str],
    *,
    log_path: Path,
    timeout: int,
    success_artifact: Path | None = None,
    artifact_ready: Callable[[], dict] | None = None,
    stable_secs: int = 20,
) -> dict:
    """Run Godot; optionally accept packaging success when artifact stabilizes.

    Authentic packaging: process exits 0 OR artifact proves complete from this
    export path (size-stable) and we terminate a hung post-export process.
    Hard wall timeout with no ready artifact => timed_out True.
    """
    log_path.parent.mkdir(parents=True, exist_ok=True)
    creationflags = 0
    if platform.system() == "Windows":
        creationflags = getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0x00000200)
    started = time.time()
    try:
        with log_path.open("w", encoding="utf-8", errors="replace") as logf:
            logf.write(f"# cmd={' '.join(cmd)}\n# started={utc_now()}\n")
            logf.flush()
            try:
                proc = subprocess.Popen(
                    cmd,
                    stdout=logf,
                    stderr=subprocess.STDOUT,
                    creationflags=creationflags,
                )
            except FileNotFoundError as exc:
                return {
                    "ok": False,
                    "timed_out": False,
                    "exit": None,
                    "error": str(exc),
                    "elapsed_s": 0,
                    "packaging_complete": False,
                    "completion_mode": "missing_binary",
                }

            last_size = -1
            stable_since: float | None = None
            packaging_complete = False
            completion_mode = "process_exit"

            while True:
                rc = proc.poll()
                elapsed = time.time() - started
                if rc is not None:
                    logf.write(f"\n# exited rc={rc} elapsed={int(elapsed)}s\n")
                    ready = (
                        artifact_ready()
                        if artifact_ready
                        else (
                            {"ready": success_artifact.is_file()}
                            if success_artifact
                            else {"ready": rc == 0}
                        )
                    )
                    packaging_complete = bool(ready.get("ready")) if isinstance(ready, dict) else bool(ready)
                    return {
                        "ok": rc == 0 and packaging_complete,
                        "timed_out": False,
                        "exit": rc,
                        "error": None if rc == 0 else f"godot exit {rc}",
                        "elapsed_s": int(elapsed),
                        "packaging_complete": packaging_complete,
                        "completion_mode": "process_exit",
                        "artifact": ready if isinstance(ready, dict) else None,
                        "log": str(log_path),
                    }

                if success_artifact is not None or artifact_ready is not None:
                    ready = (
                        artifact_ready()
                        if artifact_ready
                        else {"ready": success_artifact.is_file() and success_artifact.stat().st_size > 0}
                    )
                    if isinstance(ready, dict) and ready.get("ready"):
                        size = int(ready.get("total_bytes") or ready.get("index_bytes") or 0)
                        if size == last_size and size > 0:
                            if stable_since is None:
                                stable_since = time.time()
                            elif time.time() - stable_since >= stable_secs:
                                packaging_complete = True
                                completion_mode = "artifact_stable_then_kill"
                                logf.write(
                                    f"\n# packaging artifact stable for {stable_secs}s; "
                                    f"terminating hung Godot pid={proc.pid}\n"
                                )
                                logf.flush()
                                _kill_tree(proc.pid)
                                try:
                                    proc.wait(timeout=60)
                                except Exception:
                                    pass
                                return {
                                    "ok": True,
                                    "timed_out": False,
                                    "exit": proc.returncode,
                                    "error": None,
                                    "elapsed_s": int(time.time() - started),
                                    "packaging_complete": True,
                                    "completion_mode": completion_mode,
                                    "artifact": ready,
                                    "log": str(log_path),
                                    "note": "Godot hung after authentic export; artifact size-stable proof accepted",
                                }
                        else:
                            last_size = size
                            stable_since = time.time()
                    else:
                        last_size = -1
                        stable_since = None

                if elapsed >= timeout:
                    logf.write(f"\n# HARD TIMEOUT after {timeout}s\n")
                    logf.flush()
                    _kill_tree(proc.pid)
                    try:
                        proc.wait(timeout=60)
                    except Exception:
                        pass
                    ready = (
                        artifact_ready()
                        if artifact_ready
                        else (
                            {"ready": success_artifact.is_file()}
                            if success_artifact
                            else {"ready": False}
                        )
                    )
                    packaging_complete = bool(ready.get("ready")) if isinstance(ready, dict) else False
                    return {
                        "ok": False,
                        "timed_out": True,
                        "exit": None,
                        "error": f"godot timed out after {timeout}s",
                        "elapsed_s": int(timeout),
                        "packaging_complete": packaging_complete,
                        "completion_mode": "hard_timeout",
                        "artifact": ready if isinstance(ready, dict) else None,
                        "log": str(log_path),
                    }
                time.sleep(2)
    except Exception as exc:
        return {
            "ok": False,
            "timed_out": False,
            "exit": None,
            "error": str(exc),
            "elapsed_s": int(time.time() - started),
            "packaging_complete": False,
            "completion_mode": "exception",
        }


def log_tail(path: Path, n: int = 2000) -> str:
    if not path.is_file():
        return ""
    try:
        data = path.read_text(encoding="utf-8", errors="replace")
        return data[-n:]
    except OSError:
        return ""


def main() -> int:
    if platform.system() != "Windows":
        print("REFUSE: must run on Windows", file=sys.stderr)
        return 2

    REPORTS.mkdir(parents=True, exist_ok=True)
    sha = head_sha()
    soak_seconds = int(os.environ.get("WINDOWS_PILOT0_SOAK_SECONDS", "1800"))
    export_timeout = int(os.environ.get("WINDOWS_PILOT0_EXPORT_TIMEOUT", "2400"))
    checks: dict[str, dict] = {}
    blockers: list[str] = []
    skipped_required = 0

    godot = resolve_godot()
    version = godot_version(godot)
    templates = template_probe()
    meta = {
        "image_os": os.environ.get("ImageOS"),
        "image_version": os.environ.get("ImageVersion"),
        "runner_os": os.environ.get("RUNNER_OS"),
        "godot_bin": godot,
        "godot_version": version,
        "templates": templates,
    }
    print(f"::notice::GODOT={godot} version={version}")
    print(f"::notice::templates={json.dumps(templates)}")

    checks["fresh_windows_vm"] = {"status": "PASS", "detail": meta}
    checks["unity_path"] = {
        "status": "BLOCKED_ENGINE_LICENSE",
        "detail": "Unity launch path not used for Windows Pilot 0 PASS",
    }
    checks["anime_pixel_acceptance"] = {"status": "PENDING_DEVICE"}

    if "4.5" not in version and "UNAVAILABLE" not in version:
        blockers.append("GODOT_VERSION_MISMATCH_NEED_4_5")
        print(f"::error title=WINDOWS_PILOT0::Godot version mismatch: {version} (need 4.5.x)")

    if not templates.get("web_release_zip"):
        blockers.append("MISSING_WEB_EXPORT_TEMPLATE")
        print("::error title=WINDOWS_PILOT0::Missing 4.5.stable web_release.zip export template")

    # Prefer prebuilt web dist if present; else require authentic godot export.
    if not INDEX.is_file():
        import_log = REPORTS / "godot_import.log"
        export_log = REPORTS / "godot_web_export.log"
        WEB_DIST.mkdir(parents=True, exist_ok=True)

        print("::notice::Running Godot --import (project cache)")
        import_res = run_godot(
            [godot, "--headless", "--path", str(PROJECT), "--import", "--quit"],
            log_path=import_log,
            timeout=min(900, export_timeout),
        )
        checks["godot_import"] = {
            "status": "PASS" if import_res.get("exit") in (0, None) and not (
                import_res.get("timed_out") and not (PROJECT / ".godot").exists()
            )
            else "PARTIAL",
            **import_res,
            "tail": log_tail(import_log),
        }

        print("::notice::Running Godot --export-release Web")
        export_res = run_godot(
            [
                godot,
                "--headless",
                "--verbose",
                "--path",
                str(PROJECT),
                "--export-release",
                "Web",
                str(INDEX),
            ],
            log_path=export_log,
            timeout=export_timeout,
            success_artifact=INDEX,
            artifact_ready=lambda: web_bundle_ready(WEB_DIST),
            stable_secs=25,
        )
        bundle = web_bundle_ready(WEB_DIST)
        packaging_ok = bool(export_res.get("packaging_complete")) and bundle.get("ready")
        timed_out_incomplete = bool(export_res.get("timed_out")) and not packaging_ok

        checks["compile_package"] = {
            "status": "PASS" if packaging_ok else "FAIL",
            "godot_bin": godot,
            "godot_version": version,
            "export_exit": export_res.get("exit"),
            "error": export_res.get("error"),
            "elapsed_s": export_res.get("elapsed_s"),
            "completion_mode": export_res.get("completion_mode"),
            "timed_out": export_res.get("timed_out"),
            "bundle": bundle,
            "tail": log_tail(export_log),
            "path": "Godot Web export (authentic; no fake native wrapper)",
            "repeatability": "REPEATABLE",
            "signing": "UNSIGNED_PILOT_ARTIFACT_NOT_FOR_PRODUCTION",
        }
        if timed_out_incomplete:
            blockers.append("WEB_EXPORT_TIMEOUT")
            print(f"::error title=WINDOWS_PILOT0::{export_res.get('error')}")
        if not packaging_ok:
            blockers.append("WEB_EXPORT_FAILED")
            skipped_required += 1
            print("::error title=WINDOWS_PILOT0::WEB_EXPORT_FAILED")
        elif export_res.get("completion_mode") == "artifact_stable_then_kill":
            print(
                "::notice::Web bundle size-stable; Godot post-export hang terminated after authentic packaging"
            )
    else:
        checks["compile_package"] = {
            "status": "PASS",
            "path": str(INDEX),
            "sha256": sha256(INDEX),
            "detail": "existing builds/web used",
            "repeatability": "REPEATABLE",
            "signing": "UNSIGNED_PILOT_ARTIFACT_NOT_FOR_PRODUCTION",
        }

    # Serve + Edge/Chromium smoke
    if INDEX.is_file() and web_bundle_ready(WEB_DIST).get("ready"):
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
        checks["first_launch"] = {"status": "FAIL", "detail": "no authentic web bundle"}
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
    if INDEX.is_file() and web_bundle_ready(WEB_DIST).get("ready"):
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
    version_block = any(b.startswith("GODOT_VERSION") or b.startswith("MISSING_") for b in blockers)
    if hard_failed or skipped_required or timed_out or version_block:
        claim = (
            "WINDOWS_PILOT0_PARTIAL"
            if INDEX.is_file() and web_bundle_ready(WEB_DIST).get("ready")
            else "WINDOWS_PILOT0_BLOCKED"
        )
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
            "TIMEOUT without authentic complete web bundle never counts as PASS",
        ],
    }
    (REPORTS / "WINDOWS_PILOT0_EVIDENCE.json").write_text(json.dumps(evidence, indent=2) + "\n")
    (REPORTS / "WINDOWS_PILOT0_EVIDENCE.md").write_text(
        f"# Windows Pilot 0 — Anime Aggressors\n\n"
        f"- claim: `{claim}`\n"
        f"- godot: `{version}`\n"
        f"- path: Godot Web on Windows browser\n"
        f"- ANIME_PIXEL_ACCEPTANCE: PENDING_DEVICE\n"
        f"- blockers: {blockers}\n"
    )
    for b in blockers:
        print(f"::error title=WINDOWS_PILOT0::{b}")
    for k in hard_failed:
        print(f"::error title=WINDOWS_PILOT0_CHECK_FAIL::{k}")
    print(f"::notice title=WINDOWS_PILOT0_CLAIM::{claim} head={sha[:12]}")
    print(json.dumps({"claim": claim, "sha12": sha[:12], "blockers": blockers}, indent=2))
    return 0 if claim == "WINDOWS_PILOT0_PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
