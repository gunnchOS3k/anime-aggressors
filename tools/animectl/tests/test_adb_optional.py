"""Unit tests: animectl must tolerate missing / empty ADB without crashing."""
from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))

from animectl.adb_probe import physical_gate_statuses, probe_adb  # noqa: E402
from animectl.acceptance import run_acceptance  # noqa: E402
from animectl.doctor import run_doctor  # noqa: E402
from animectl.wrappers import run_android  # noqa: E402


class FakeCP(SimpleNamespace):
    pass


class AdbOptionalTests(unittest.TestCase):
    def test_probe_missing_adb(self) -> None:
        probe = probe_adb(ROOT, which=lambda _n: None)
        self.assertFalse(probe.adb_available)
        self.assertEqual(probe.pixel_adb_state, "NOT_AVAILABLE_ON_RUNNER")
        statuses = physical_gate_statuses(probe)
        self.assertEqual(statuses["G7_PIXEL_PHYSICAL"], "REQUIRES_PHYSICAL")
        self.assertEqual(statuses["PIXEL_INSTALL"], "NOT_APPLICABLE")

    def test_probe_adb_no_device(self) -> None:
        def runner(cmd, cwd=None, timeout=None):  # noqa: ANN001
            return FakeCP(returncode=0, stdout="List of devices attached\n\n", stderr="")

        probe = probe_adb(ROOT, which=lambda _n: "/usr/bin/adb", runner=runner)
        self.assertTrue(probe.adb_available)
        self.assertEqual(probe.pixel_adb_state, "NO_DEVICE")
        self.assertFalse(probe.has_authorized_device)

    def test_probe_unauthorized(self) -> None:
        def runner(cmd, cwd=None, timeout=None):  # noqa: ANN001
            return FakeCP(
                returncode=0,
                stdout="List of devices attached\nSERIAL\tunauthorized\n",
                stderr="",
            )

        probe = probe_adb(ROOT, which=lambda _n: "/usr/bin/adb", runner=runner)
        self.assertEqual(probe.pixel_adb_state, "UNAUTHORIZED")
        self.assertEqual(physical_gate_statuses(probe)["PIXEL_ADB_STATE"], "UNAUTHORIZED")

    def test_probe_device(self) -> None:
        def runner(cmd, cwd=None, timeout=None):  # noqa: ANN001
            return FakeCP(
                returncode=0,
                stdout="List of devices attached\n27211JEGR06194\tdevice usb:1\n",
                stderr="",
            )

        probe = probe_adb(ROOT, which=lambda _n: "/usr/bin/adb", runner=runner)
        self.assertEqual(probe.devices, ["27211JEGR06194"])
        self.assertEqual(probe.pixel_adb_state, "DEVICE")

    def test_doctor_without_adb_no_crash(self) -> None:
        with mock.patch("animectl.doctor._which", side_effect=lambda n: None if n == "adb" else "/bin/true"):
            with mock.patch("animectl.doctor._version", return_value="ok"):
                # Still need real which for required tools — patch only adb via tools dict path
                res = run_doctor(ROOT)
        # doctor itself uses _which internally; ensure it doesn't raise
        self.assertIn(res.status, ("PASS", "PASS_WITH_NOTES", "FAIL", "REQUIRES_PHYSICAL"))

    def test_acceptance_without_adb_no_crash(self) -> None:
        missing = FakeCP(returncode=127, stdout="", stderr="FileNotFoundError: adb")

        def fake_run(cmd, cwd=None, timeout=None):  # noqa: ANN001
            if cmd and cmd[0] == "adb":
                return missing
            # allow other probes to fail softly
            return FakeCP(returncode=1, stdout="", stderr="skip")

        with mock.patch("animectl.acceptance.probe_adb") as mocked:
            from animectl.adb_probe import AdbProbe

            mocked.return_value = AdbProbe(
                adb_available=False,
                adb_path=None,
                pixel_adb_state="NOT_AVAILABLE_ON_RUNNER",
                devices=[],
                unauthorized=[],
                detail="missing",
            )
            res = run_acceptance(ROOT, exact_head=True, mode="quick")
        self.assertEqual(res.exit_code, 0)
        g7 = [c for c in res.checks if c["id"] == "P08_PIXEL_G7_EVIDENCE"]
        self.assertTrue(g7)
        self.assertEqual(g7[0]["status"], "REQUIRES_PHYSICAL")
        # must not be FAIL solely due to missing ADB
        fail_physical = [c for c in res.checks if c["status"] == "FAIL" and "ADB" in c.get("detail", "")]
        self.assertEqual(fail_physical, [])

    def test_android_install_without_adb_exit_no_device(self) -> None:
        from animectl.adb_probe import AdbProbe

        missing = AdbProbe(
            adb_available=False,
            adb_path=None,
            pixel_adb_state="NOT_AVAILABLE_ON_RUNNER",
            devices=[],
            unauthorized=[],
        )
        with mock.patch("animectl.adb_probe.probe_adb", return_value=missing):
            res = run_android(ROOT, "install")
        self.assertEqual(res.exit_code, 7)  # EXIT_NO_DEVICE
        self.assertEqual(res.status, "REQUIRES_PHYSICAL")

    def test_process_run_missing_binary(self) -> None:
        from animectl.process import run

        cp = run(["definitely-not-a-real-binary-xyz"], cwd=ROOT)
        self.assertEqual(cp.returncode, 127)
        self.assertIn("FileNotFoundError", cp.stderr)


if __name__ == "__main__":
    unittest.main()
