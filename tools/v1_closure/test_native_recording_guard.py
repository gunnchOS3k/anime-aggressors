"""Exercise refusal, ownership, partial-file preservation and successful exit."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import native_recording_guard as guard


class RecordingStorageSafety(unittest.TestCase):
    def test_budget_requires_raw_and_derivation_headroom(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with patch.object(guard.shutil, "disk_usage", return_value=type("Disk", (), {"free": guard.NATIVE_RESERVE + 100})()):
                self.assertFalse(guard.budget(root, root / "unique.avi", 900, 60)["PASS"])
            (root / "existing.avi").write_bytes(b"protected")
            with self.assertRaises(RuntimeError):
                guard.budget(root, root / "existing.avi", 900, 60)
            self.assertEqual((root / "existing.avi").read_bytes(), b"protected")

    def test_low_space_stops_only_owned_child_and_preserves_partial_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); output = root / "review"; output.mkdir()
            movie = root / "new.avi"
            preflight = guard.budget(root, movie, 10, 60); preflight["PASS"] = True
            high = guard.NATIVE_RESERVE + guard.DERIVATION_RESERVE + 100_000_000
            values = iter([high, high, guard.NATIVE_RESERVE - 1, high])
            disk = lambda _: type("Disk", (), {"free": next(values)})()
            child = [sys.executable, "-c", "from pathlib import Path; import time; Path('" + str(movie) + "').write_bytes(b'partial-original'); time.sleep(30)"]
            with patch.object(guard, "active_media_jobs", return_value=[]), patch.object(guard.shutil, "disk_usage", side_effect=disk):
                self.assertEqual(guard.run_owned_recording(child, root, movie, output, preflight), 73)
            state = json.loads((output / "RECORDING_STATE.json").read_text())
            self.assertEqual(state["status"], "INTERRUPTED_STORAGE_RESERVE")
            self.assertEqual(movie.read_bytes(), b"partial-original")
            self.assertFalse((root / "artifacts/v1_closure/spectral_feedback/local_media/native_recording.lock").exists())

    def test_success_remains_unverified_and_active_jobs_are_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); output = root / "review"; output.mkdir(); movie = root / "new.avi"
            preflight = guard.budget(root, movie, 10, 60); preflight["PASS"] = True
            with patch.object(guard, "active_media_jobs", return_value=[{"pid": 12, "application": "Godot"}]):
                with self.assertRaises(RuntimeError):
                    guard.run_owned_recording([sys.executable, "-c", "pass"], root, movie, output, preflight)
            self.assertFalse((output / "RECORDING_STATE.json").exists())
            with patch.object(guard, "active_media_jobs", return_value=[]):
                self.assertEqual(guard.run_owned_recording([sys.executable, "-c", "pass"], root, movie, output, preflight), 0)
            self.assertEqual(json.loads((output / "RECORDING_STATE.json").read_text())["status"], "PROCESS_COMPLETED_PENDING_MEDIA_VERIFICATION")


if __name__ == "__main__":
    unittest.main()
