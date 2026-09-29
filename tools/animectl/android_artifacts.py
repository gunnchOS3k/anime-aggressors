"""Find / download / verify exact-head Android CI APK artifacts via gh."""
from __future__ import annotations

import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any

from .git_truth import git_truth
from .result import EXIT_EXTERNAL, EXIT_OK, EXIT_STALE, EXIT_VALIDATION, AnimectlResult

WORKFLOW_FILE = "android-exact-head.yml"
ARTIFACT_NAME_PREFIX = "anime-aggressors-android-"
PACKAGE_ID = "com.gunnchos.animeaggressors"
MANIFEST_NAME = "ANDROID_BUILD_MANIFEST.json"
APK_NAME = "anime-aggressors-debug.apk"


def _gh(root: Path, *args: str, check: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["gh", *args],
        cwd=root,
        text=True,
        capture_output=True,
        check=check,
    )


def _resolve_sha(root: Path, sha: str | None) -> str:
    if sha:
        return sha.strip().lower()
    return git_truth(root)["git_sha"].lower()


def _short(sha: str) -> str:
    return sha[:12]


def find_runs(root: Path, sha: str) -> list[dict[str, Any]]:
    """List successful android-exact-head runs for a commit SHA."""
    if not shutil.which("gh"):
        return []
    cp = _gh(
        root,
        "run",
        "list",
        "--workflow",
        WORKFLOW_FILE,
        "--commit",
        sha,
        "--json",
        "databaseId,headSha,status,conclusion,url,displayTitle,createdAt,workflowName",
        "--limit",
        "20",
    )
    if cp.returncode != 0:
        return []
    try:
        runs = json.loads(cp.stdout or "[]")
    except json.JSONDecodeError:
        return []
    out = []
    for r in runs:
        if str(r.get("headSha", "")).lower() != sha.lower():
            continue
        if r.get("status") == "completed" and r.get("conclusion") == "success":
            out.append(r)
        elif r.get("status") in ("in_progress", "queued", "pending"):
            out.append(r)
    return out


def artifact_dir(root: Path, sha: str) -> Path:
    return root / ".acceptance" / sha / "android"


def find_local_manifest(root: Path, sha: str) -> Path | None:
    p = artifact_dir(root, sha) / MANIFEST_NAME
    return p if p.is_file() else None


def verify_manifest(root: Path, sha: str, manifest: dict[str, Any], apk: Path) -> list[str]:
    errs: list[str] = []
    m_sha = str(manifest.get("git_sha", "")).lower()
    if m_sha != sha.lower():
        errs.append(f"manifest.git_sha={m_sha} != requested={sha}")
    if str(manifest.get("package_id")) != PACKAGE_ID:
        errs.append(f"package_id={manifest.get('package_id')}")
    if not apk.is_file():
        errs.append(f"missing apk: {apk}")
        return errs
    digest = hashlib.sha256(apk.read_bytes()).hexdigest()
    expected = str(manifest.get("artifact_sha256", "")).lower()
    if expected and digest != expected:
        errs.append(f"apk sha256 mismatch got={digest} expected={expected}")
    # embedded identity: search APK zip members for full sha
    try:
        import zipfile

        found = False
        needle = sha.encode()
        with zipfile.ZipFile(apk) as zf:
            for name in zf.namelist():
                try:
                    data = zf.read(name)
                except Exception:
                    continue
                if needle in data:
                    found = True
                    break
        if not found:
            errs.append("embedded git_sha not found inside APK")
        elif not manifest.get("embedded_identity_verified", False):
            # tolerate local re-verify when CI already stamped true
            pass
    except Exception as exc:
        errs.append(f"apk inspect failed: {exc}")
    return errs


def download_artifact(root: Path, sha: str) -> tuple[Path | None, dict[str, Any], str]:
    """Download CI artifact for exact SHA into .acceptance/<sha>/android/."""
    out = artifact_dir(root, sha)
    out.mkdir(parents=True, exist_ok=True)
    runs = find_runs(root, sha)
    success = [r for r in runs if r.get("conclusion") == "success"]
    if not success:
        pending = [r for r in runs if r.get("status") != "completed"]
        if pending:
            return None, {"runs": runs}, "ANDROID_CI_IN_PROGRESS"
        return None, {"runs": runs}, "ANDROID_CI_ARTIFACT_NOT_FOUND"

    run_id = str(success[0]["databaseId"])
    names = [
        f"{ARTIFACT_NAME_PREFIX}{_short(sha)}",
        f"{ARTIFACT_NAME_PREFIX}{sha}",
    ]
    # Clear prior download for this sha
    for child in list(out.iterdir()):
        if child.is_file():
            child.unlink()
        elif child.is_dir():
            shutil.rmtree(child)
    cp = None
    name = names[0]
    for candidate in names:
        name = candidate
        cp = _gh(root, "run", "download", run_id, "-n", name, "-D", str(out))
        if cp.returncode == 0:
            break
    if cp is None or cp.returncode != 0:
        # fallback: download all artifacts from the run
        cp2 = _gh(root, "run", "download", run_id, "-D", str(out))
        if cp2.returncode != 0:
            return None, {
                "stderr": getattr(cp, "stderr", ""),
                "stderr2": cp2.stderr,
                "run_id": run_id,
                "tried_names": names,
            }, "DOWNLOAD_FAILED"

    apk = out / APK_NAME
    # gh may nest under artifact folder name
    if not apk.is_file():
        candidates = list(out.rglob(APK_NAME))
        if candidates:
            apk = candidates[0]
            # flatten
            man_cands = list(out.rglob(MANIFEST_NAME))
            flat_apk = out / APK_NAME
            flat_man = out / MANIFEST_NAME
            if apk != flat_apk:
                shutil.copy2(apk, flat_apk)
                apk = flat_apk
            if man_cands and man_cands[0] != flat_man:
                shutil.copy2(man_cands[0], flat_man)

    man_path = out / MANIFEST_NAME
    if not man_path.is_file():
        mans = list(out.rglob(MANIFEST_NAME))
        if mans:
            shutil.copy2(mans[0], man_path)
    if not man_path.is_file() or not apk.is_file():
        return None, {"dir": str(out), "files": [str(p) for p in out.rglob("*")]}, "ARTIFACT_INCOMPLETE"

    manifest = json.loads(man_path.read_text(encoding="utf-8"))
    errs = verify_manifest(root, sha, manifest, apk)
    if errs:
        return apk, {"manifest": manifest, "errors": errs}, "VERIFY_FAILED"
    return apk, {"manifest": manifest, "run_id": run_id, "artifact_name": name}, "OK"


def artifact_command(root: Path, action: str, *, sha: str | None = None) -> AnimectlResult:
    gt = git_truth(root)
    resolved = _resolve_sha(root, sha)
    res = AnimectlResult(
        command=f"android artifact {action}",
        **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")},
    )
    res.data["requested_sha"] = resolved
    res.data["requested_sha_short"] = _short(resolved)

    if action == "find":
        if not shutil.which("gh"):
            res.add_check("GH_CLI", "FAIL", "gh not on PATH")
            res.status = "FAIL"
            res.exit_code = EXIT_EXTERNAL
            return res
        runs = find_runs(root, resolved)
        local = find_local_manifest(root, resolved)
        success = [r for r in runs if r.get("conclusion") == "success"]
        pending = [r for r in runs if r.get("status") != "completed"]
        res.data["runs"] = runs
        res.data["local_manifest"] = str(local) if local else None
        if success:
            res.add_check("ANDROID_CI_ARTIFACT", "PASS", f"run_id={success[0]['databaseId']}")
            res.status = "PASS"
            res.exit_code = EXIT_OK
        elif pending:
            res.add_check("ANDROID_CI_ARTIFACT", "PASS_WITH_NOTES", "workflow in progress")
            res.status = "PASS_WITH_NOTES"
            res.exit_code = EXIT_OK
        else:
            res.add_check("ANDROID_CI_ARTIFACT", "FAIL", "no successful run for exact SHA")
            res.status = "FAIL"
            res.exit_code = EXIT_STALE
        return res

    if action == "download":
        apk, meta, code = download_artifact(root, resolved)
        res.data.update(meta)
        if code == "OK" and apk:
            res.add_check("ANDROID_ARTIFACT_DOWNLOAD", "PASS", str(apk.relative_to(root)))
            res.artifacts.append(str(apk.relative_to(root)))
            man = artifact_dir(root, resolved) / MANIFEST_NAME
            if man.is_file():
                res.artifacts.append(str(man.relative_to(root)))
            res.status = "PASS"
            res.exit_code = EXIT_OK
        elif code == "ANDROID_CI_IN_PROGRESS":
            res.add_check("ANDROID_ARTIFACT_DOWNLOAD", "PASS_WITH_NOTES", code)
            res.status = "PASS_WITH_NOTES"
            res.exit_code = EXIT_OK
        else:
            res.add_check("ANDROID_ARTIFACT_DOWNLOAD", "FAIL", code)
            res.status = "FAIL"
            res.exit_code = EXIT_STALE if "NOT_FOUND" in code else EXIT_VALIDATION
        return res

    if action == "verify":
        out = artifact_dir(root, resolved)
        apk = out / APK_NAME
        man_path = out / MANIFEST_NAME
        if not man_path.is_file() or not apk.is_file():
            res.add_check("ANDROID_ARTIFACT_VERIFY", "FAIL", "download first")
            res.status = "FAIL"
            res.exit_code = EXIT_VALIDATION
            return res
        manifest = json.loads(man_path.read_text(encoding="utf-8"))
        errs = verify_manifest(root, resolved, manifest, apk)
        res.data["manifest"] = manifest
        if errs:
            res.add_check("ANDROID_ARTIFACT_VERIFY", "FAIL", "; ".join(errs))
            res.status = "FAIL"
            res.exit_code = EXIT_VALIDATION
        else:
            res.add_check("ANDROID_ARTIFACT_VERIFY", "PASS", f"sha={resolved[:12]}")
            res.status = "PASS"
            res.exit_code = EXIT_OK
        return res

    res.add_check("ANDROID_ARTIFACT", "FAIL", f"unknown action {action}")
    res.status = "FAIL"
    res.exit_code = EXIT_VALIDATION
    return res
