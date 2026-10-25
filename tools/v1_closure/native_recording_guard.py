"""Bounded native recording ownership. Never removes recordings or evidence."""
import json
import os
import shutil
import subprocess
import time
from pathlib import Path

HEAVY_EXPORT_RESERVE = 18 * 1024**3
# October 21 owner storage policy: recording temporary allocations must also
# leave 18 GiB on the internal source volume. External movie destinations do not
# waive this reserve. Historical receipts retain their original policy values.
NATIVE_RESERVE = HEAVY_EXPORT_RESERVE
FRAME_BUDGET = 256 * 1024  # Recorded historical MJPEG costs: approximately 48–58 KiB/frame.
DERIVATION_RESERVE = 100 * 1024**2  # Encoding and small sheets remain inside this budget.


def active_media_jobs():
    """Read process identities, without storing unrelated command lines."""
    result = subprocess.run(["ps", "-Ao", "pid=,comm="], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError("Cannot verify media process ownership; no native recording started")
    jobs = []
    for line in result.stdout.splitlines():
        parts = line.strip().split(None, 1)
        if len(parts) == 2 and Path(parts[1]).name.lower() in ("godot", "ffmpeg"):
            jobs.append({"pid": int(parts[0]), "application": Path(parts[1]).name})
    return jobs


def budget(root, movie, frames, fps):
    if frames <= 0 or frames > 6000 or fps not in (30, 60):
        raise RuntimeError("Explicit bounded native frame count and 30/60 fps required")
    if Path(movie).exists():
        raise RuntimeError("Existing native evidence preserved; choose a new movie label")
    free = shutil.disk_usage(root).free
    raw = frames * FRAME_BUDGET
    required = NATIVE_RESERVE + raw + DERIVATION_RESERVE
    return {"free_bytes": free, "frame_cap": frames, "fps": fps,
            "conservative_raw_bytes": raw, "historical_frame_cost_kib": [48, 58],
            "budget_bytes_per_frame": FRAME_BUDGET, "derivation_reserve_bytes": DERIVATION_RESERVE,
            "native_reserve_bytes": NATIVE_RESERVE, "heavy_export_reserve_bytes": HEAVY_EXPORT_RESERVE,
            "required_free_bytes": required, "PASS": free >= required,
            "quality": "Original native MJPEG/PCM; no resolution, frame-rate or fidelity reduction",
            "reserve_policy": "owner_2026_10_21_internal_18GiB_after_allocations"}


def write_state(path, state):
    temporary = path.with_suffix(".json.writing")
    temporary.write_text(json.dumps(state, indent=2) + "\n")
    temporary.replace(path)


def run_owned_recording(cmd, root, movie, output, preflight, *, error_log=None, max_seconds=None, max_rss_bytes=None):
    """Stop only our own Godot child if the protected reserve is endangered."""
    root, movie, output = Path(root), Path(movie), Path(output)
    registry = root / "artifacts/v1_closure/spectral_feedback/local_media/native_recording.lock"
    registry.parent.mkdir(parents=True, exist_ok=True)
    state_path = output / "RECORDING_STATE.json"
    if state_path.exists():
        raise RuntimeError("Existing recording state preserved; use a unique output directory")
    if not preflight["PASS"]:
        raise RuntimeError("Native reserve exhausted; no recording started")
    if active_media_jobs():
        raise RuntimeError("An existing Godot/FFmpeg job is active; no duplicate recording started")
    # A stale lock is reported, rather than silently discarded or pruning data.
    try:
        descriptor = os.open(registry, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    except FileExistsError:
        raise RuntimeError("Recording ownership lock exists; inspect its PID/state before continuing")
    state = {"status": "PREPARED", "owner_pid": os.getpid(), "movie": str(movie.resolve()),
             "output": str(output.resolve()), "storage_budget": preflight,
             "minimum_observed_free_bytes": preflight["free_bytes"], "automatic_media_deletion": False,
             "native_verification": "PENDING_FRAME_IDENTITY_AUDIO_SOURCE_CHECKS"}
    os.write(descriptor, json.dumps(state).encode())
    os.close(descriptor)
    child = None
    try:
        # Recheck immediately before launch; preparation can take time.
        free = shutil.disk_usage(root).free
        if free < preflight["required_free_bytes"]:
            state.update(status="REFUSED_RESERVE_CHANGED", free_at_launch=free)
            write_state(state_path, state)
            return 73
        child = subprocess.Popen(cmd)
        state.update(status="RUNNING", child_pid=child.pid, started_unix=time.time())
        write_state(state_path, state)
        floor = NATIVE_RESERVE + DERIVATION_RESERVE
        interrupted = False
        script_failed = False
        resource_failed = False
        while child.poll() is None:
            rss = subprocess.run(["ps", "-o", "rss=", "-p", str(child.pid)], capture_output=True, text=True) if max_rss_bytes else None
            if rss and rss.stdout.strip().isdigit():
                state["sampled_peak_RSS_bytes"] = max(state.get("sampled_peak_RSS_bytes", 0), int(rss.stdout.strip())*1024)
            if (max_rss_bytes and ((rss.returncode and child.poll() is None) or state.get("sampled_peak_RSS_bytes", 0) > max_rss_bytes)) or (max_seconds and time.time()-state["started_unix"] > max_seconds):
                resource_failed = True
                state.update(status="INTERRUPTED_RESOURCE_GUARD", max_seconds=max_seconds, max_rss_bytes=max_rss_bytes)
                child.terminate()
                try: child.wait(timeout=8)
                except subprocess.TimeoutExpired: child.kill(); child.wait()
                break
            if error_log and Path(error_log).exists() and "SCRIPT ERROR:" in Path(error_log).read_text(errors="replace"):
                script_failed = True
                state.update(status="FAILED_SCRIPT_ERROR_PRESERVED")
                child.terminate()
                try:
                    child.wait(timeout=8)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
                break
            free = shutil.disk_usage(root).free
            state["minimum_observed_free_bytes"] = min(state["minimum_observed_free_bytes"], free)
            if free < floor:
                interrupted = True
                state.update(status="INTERRUPTED_STORAGE_RESERVE", free_at_interruption=free)
                child.terminate()
                try:
                    child.wait(timeout=8)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
                break
            time.sleep(.5)
        result = child.wait()
        # Godot may exit0 even after an unhandled script error. Never promote
        # that process outcome into a successful review receipt.
        if error_log and Path(error_log).exists() and "SCRIPT ERROR:" in Path(error_log).read_text(errors="replace"):
            script_failed = True
            state["status"] = "FAILED_SCRIPT_ERROR_PRESERVED"
        state.update(exit_code=result, finished_unix=time.time(), free_after=shutil.disk_usage(root).free)
        if not interrupted and not script_failed and not resource_failed:
            state["status"] = "PROCESS_COMPLETED_PENDING_MEDIA_VERIFICATION" if result == 0 else "FAILED_PROCESS_PRESERVED"
        if movie.exists():
            info = movie.stat()
            state.update(raw_logical_bytes=info.st_size, raw_allocated_bytes=info.st_blocks * 512)
        write_state(state_path, state)
        return 73 if interrupted else 75 if resource_failed else 1 if script_failed else result
    finally:
        if child is not None and child.poll() is None:
            child.terminate()
            child.wait(timeout=8)
            state.update(status="INTERRUPTED_OWNER_PROCESS", finished_unix=time.time())
            write_state(state_path, state)
        # This is our lock, never a movie, worktree, source file or historical state.
        registry.unlink()
