"""ADB capability probe — digital CI must not crash when adb is absent."""
from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Sequence

from .process import run

WhichFn = Callable[[str], str | None]
RunFn = Callable[..., object]


@dataclass(frozen=True)
class AdbProbe:
    adb_available: bool
    adb_path: str | None
    pixel_adb_state: str
    devices: list[str]
    unauthorized: list[str]
    detail: str = ""

    @property
    def has_authorized_device(self) -> bool:
        return bool(self.devices)


def probe_adb(
    root: Path,
    *,
    which: WhichFn | None = None,
    runner: RunFn | None = None,
) -> AdbProbe:
    """Probe ADB without raising when the binary is missing from PATH."""
    which_fn = which or shutil.which
    adb_path = which_fn("adb")
    if not adb_path:
        return AdbProbe(
            adb_available=False,
            adb_path=None,
            pixel_adb_state="NOT_AVAILABLE_ON_RUNNER",
            devices=[],
            unauthorized=[],
            detail="adb binary not found on PATH",
        )

    run_fn = runner or run
    cp = run_fn(["adb", "devices", "-l"], cwd=root)
    stdout = getattr(cp, "stdout", "") or ""
    devices: list[str] = []
    unauthorized: list[str] = []
    offline: list[str] = []
    for ln in stdout.splitlines()[1:]:
        parts = ln.split()
        if len(parts) < 2:
            continue
        serial, state = parts[0], parts[1]
        if state == "device":
            devices.append(serial)
        elif state == "unauthorized":
            unauthorized.append(serial)
        elif state == "offline":
            offline.append(serial)

    if devices:
        state = "DEVICE"
    elif unauthorized:
        state = "UNAUTHORIZED"
    elif offline:
        state = "OFFLINE"
    else:
        state = "NO_DEVICE"

    return AdbProbe(
        adb_available=True,
        adb_path=adb_path,
        pixel_adb_state=state,
        devices=devices,
        unauthorized=unauthorized,
        detail=f"adb={adb_path} state={state} devices={len(devices)}",
    )


def physical_gate_statuses(probe: AdbProbe) -> dict[str, str]:
    """Statuses for acceptance / doctor when physical tooling is absent or unused."""
    if not probe.adb_available:
        return {
            "ADB_AVAILABLE": "false",
            "PIXEL_ADB_STATE": "NOT_AVAILABLE_ON_RUNNER",
            "PIXEL_SIGNER_SAFETY": "NOT_APPLICABLE",
            "PIXEL_INSTALL": "NOT_APPLICABLE",
            "PIXEL_MATCH_SMOKE": "NOT_APPLICABLE",
            "PIXEL_STORY_SMOKE": "NOT_APPLICABLE",
            "G7_PIXEL_PHYSICAL": "REQUIRES_PHYSICAL",
        }
    if probe.pixel_adb_state == "UNAUTHORIZED":
        return {
            "ADB_AVAILABLE": "true",
            "PIXEL_ADB_STATE": "UNAUTHORIZED",
            "PIXEL_SIGNER_SAFETY": "NOT_APPLICABLE",
            "PIXEL_INSTALL": "NOT_APPLICABLE",
            "PIXEL_MATCH_SMOKE": "NOT_APPLICABLE",
            "PIXEL_STORY_SMOKE": "NOT_APPLICABLE",
            "G7_PIXEL_PHYSICAL": "REQUIRES_PHYSICAL",
        }
    if not probe.has_authorized_device:
        return {
            "ADB_AVAILABLE": "true",
            "PIXEL_ADB_STATE": probe.pixel_adb_state,
            "PIXEL_SIGNER_SAFETY": "NOT_APPLICABLE",
            "PIXEL_INSTALL": "NOT_APPLICABLE",
            "PIXEL_MATCH_SMOKE": "NOT_APPLICABLE",
            "PIXEL_STORY_SMOKE": "NOT_APPLICABLE",
            "G7_PIXEL_PHYSICAL": "REQUIRES_PHYSICAL",
        }
    return {
        "ADB_AVAILABLE": "true",
        "PIXEL_ADB_STATE": "DEVICE",
        "PIXEL_SIGNER_SAFETY": "PENDING",
        "PIXEL_INSTALL": "PENDING",
        "PIXEL_MATCH_SMOKE": "PENDING",
        "PIXEL_STORY_SMOKE": "PENDING",
        "G7_PIXEL_PHYSICAL": "PENDING_PHYSICAL",
    }


def safe_adb_argv(cmd: Sequence[str], *, which: WhichFn | None = None) -> list[str] | None:
    """Return argv only when adb exists; otherwise None (caller must not invoke)."""
    which_fn = which or shutil.which
    if not which_fn("adb"):
        return None
    return list(cmd)
