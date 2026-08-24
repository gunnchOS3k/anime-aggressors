#!/usr/bin/env python3
"""Classify Android/Godot process-death evidence for Wave015."""
from __future__ import annotations

import re
from dataclasses import dataclass


CLASSIFICATIONS = (
    "JAVA_FATAL_EXCEPTION",
    "NATIVE_SIGNAL",
    "GODOT_SCRIPT_FATAL",
    "ANR",
    "LMKD_OOM_KILL",
    "OS_PROCESS_KILL",
    "APP_REQUESTED_QUIT",
    "HARNESS_REQUESTED_QUIT",
    "ADB_DISCONNECT_ONLY",
    "UNKNOWN_PROCESS_DEATH",
)

PACKAGE = "com.gunnchos.animeaggressors"


@dataclass
class DeathClassification:
    classification: str
    counts_as_crash: bool
    evidence: list[str]
    notes: str = ""


def classify_process_death(
    *,
    logcat_text: str = "",
    heartbeat: dict | None = None,
    harness_expected_quit: bool = False,
    adb_disconnected: bool = False,
    pid_disappeared: bool = False,
    force_stop_observed: bool = False,
) -> DeathClassification:
    """Classify a process disappearance. Unexpected PID death is never discarded solely for lack of FATAL."""
    evidence: list[str] = []
    text = logcat_text or ""
    hb = heartbeat or {}

    if adb_disconnected and not pid_disappeared:
        return DeathClassification("ADB_DISCONNECT_ONLY", False, ["adb device missing"], "Device link lost; process fate unknown")

    if re.search(rf"FATAL EXCEPTION:.*Process:\s*{re.escape(PACKAGE)}", text, re.S):
        evidence.append("AndroidRuntime FATAL EXCEPTION for package")
        return DeathClassification("JAVA_FATAL_EXCEPTION", True, evidence)

    if re.search(rf"(Fatal signal|F DEBUG).*{re.escape(PACKAGE)}", text, re.S) or re.search(
        rf">>> {re.escape(PACKAGE)} <<<", text
    ):
        evidence.append("native fatal signal / tombstone for package")
        return DeathClassification("NATIVE_SIGNAL", True, evidence)

    if re.search(r"SCRIPT ERROR:.*Error", text) and re.search(r"E godot", text):
        # Godot script errors that are fatal enough to tear down main loop.
        if re.search(r"Failed to get|Invalid get index|Attempt to call function.*(on a null|on previously freed)", text):
            evidence.append("Godot SCRIPT ERROR with null/freed access")
            return DeathClassification("GODOT_SCRIPT_FATAL", True, evidence)

    if re.search(rf"ANR in\s+{re.escape(PACKAGE)}", text):
        evidence.append("ANR in package")
        return DeathClassification("ANR", True, evidence)

    if re.search(r"lowmemorykiller|lmkd|Kill .+ to free", text, re.I) and PACKAGE.split(".")[-1] in text:
        evidence.append("LMK/OOM kill evidence")
        return DeathClassification("LMKD_OOM_KILL", True, evidence)

    if harness_expected_quit or (hb.get("clean_shutdown") is True and hb.get("last_kind") == "CLEAN_SHUTDOWN"):
        evidence.append("harness/app clean shutdown heartbeat")
        return DeathClassification(
            "HARNESS_REQUESTED_QUIT" if harness_expected_quit else "APP_REQUESTED_QUIT",
            False,
            evidence,
            "Expected quit — do not count as crash",
        )

    if force_stop_observed or re.search(rf"Force stopping\s+{re.escape(PACKAGE)}", text):
        evidence.append("am force-stop / ActivityManager Force stopping")
        return DeathClassification("OS_PROCESS_KILL", False, evidence, "External force-stop (often harness restart)")

    if re.search(rf"Killing\s+\d+:{re.escape(PACKAGE)}|Process {re.escape(PACKAGE)}.*has died", text):
        evidence.append("ActivityManager process kill/died")
        return DeathClassification("OS_PROCESS_KILL", True, evidence)

    if pid_disappeared:
        evidence.append("pidof became empty after process was observed")
        # Unexpected PID death without FATAL still counts as crash-class UNKNOWN.
        return DeathClassification(
            "UNKNOWN_PROCESS_DEATH",
            True,
            evidence,
            "PID died without AndroidRuntime FATAL — still treated as unexpected termination",
        )

    return DeathClassification("UNKNOWN_PROCESS_DEATH", False, evidence or ["no death signals"], "No process death observed")
