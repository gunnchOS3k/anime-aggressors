"""Exercise refusal, ownership, partial-file preservation and successful exit."""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
import native_recording_guard as guard


class RecordingStorageSafety(unittest.TestCase):
    def test_owned_resource_timeout_preserves_evidence(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);output=root/"review";output.mkdir();movie=root/"new.avi"
            preflight=guard.budget(root,movie,10,60);preflight["PASS"]=True
            child=[sys.executable,"-c","import time; from pathlib import Path; Path("+repr(str(movie))+").write_bytes(b'preserved'); time.sleep(10)"]
            with patch.object(guard,"active_media_jobs",return_value=[]),patch.object(guard.shutil,"disk_usage",return_value=SimpleNamespace(free=preflight["required_free_bytes"]+100_000_000)):
                self.assertEqual(guard.run_owned_recording(child,root,movie,output,preflight,max_seconds=.1),75)
            self.assertEqual(json.loads((output/"RECORDING_STATE.json").read_text())["status"],"INTERRUPTED_RESOURCE_GUARD")
            self.assertEqual(movie.read_bytes(),b"preserved")

    def test_zero_exit_with_script_error_is_failed_and_evidence_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); output=root/"review"; output.mkdir()
            movie=root/"new.avi"; log=output/"native.log"
            preflight=guard.budget(root,movie,10,60); preflight["PASS"]=True
            child=[sys.executable,"-c","from pathlib import Path; Path("+repr(str(log))+").write_text('SCRIPT ERROR: actual failure\\n'); Path("+repr(str(movie))+").write_bytes(b'preserved')"]
            with patch.object(guard,"active_media_jobs",return_value=[]),patch.object(guard.shutil,"disk_usage",return_value=SimpleNamespace(free=preflight["required_free_bytes"]+100_000_000)):
                self.assertEqual(guard.run_owned_recording(child,root,movie,output,preflight,error_log=log),1)
            state=json.loads((output/"RECORDING_STATE.json").read_text())
            self.assertEqual(state["status"],"FAILED_SCRIPT_ERROR_PRESERVED")
            self.assertEqual(movie.read_bytes(),b"preserved")

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
            with patch.object(guard, "active_media_jobs", return_value=[]), patch.object(guard.shutil, "disk_usage", return_value=SimpleNamespace(free=preflight["required_free_bytes"] + 100_000_000)):
                self.assertEqual(guard.run_owned_recording([sys.executable, "-c", "pass"], root, movie, output, preflight), 0)
            self.assertEqual(json.loads((output / "RECORDING_STATE.json").read_text())["status"], "PROCESS_COMPLETED_PENDING_MEDIA_VERIFICATION")


GIB = 1024**3


class RecordingReserve(unittest.TestCase):
    def budget(self, free, frames=1000, movie=Path('/unused/review.avi')):
        with patch.object(guard.shutil, 'disk_usage', return_value=SimpleNamespace(free=free)) as disk:
            with patch.object(Path, 'exists', return_value=False):
                result = guard.budget('/internal/source', movie, frames, 60)
            # The destination can be external; the internal source volume is
            # still measured because imports/rendering may allocate internally.
            disk.assert_called_once_with('/internal/source')
        return result

    def test_live_below_reserve_is_refused(self):
        self.assertFalse(self.budget(18_432_000_000)['PASS'])

    def test_just_above_18_is_insufficient_for_recording(self):
        self.assertFalse(self.budget(18 * GIB + 64 * 1024**2)['PASS'])

    def test_19gib_supports_short_but_not_long_recording(self):
        self.assertTrue(self.budget(19 * GIB, 1000)['PASS'])
        self.assertFalse(self.budget(19 * GIB, 6000)['PASS'])

    def test_exact_allocation_boundary_preserves_reserve(self):
        needed = 18 * GIB + 1000 * guard.FRAME_BUDGET + guard.DERIVATION_RESERVE
        self.assertFalse(self.budget(needed - 1)['PASS'])
        result = self.budget(needed)
        self.assertTrue(result['PASS'])
        self.assertEqual(result['required_free_bytes'], needed)
        self.assertEqual(result['native_reserve_bytes'], 18 * GIB)

    def test_external_movie_does_not_waive_internal_reserve(self):
        self.assertFalse(self.budget(17 * GIB, movie=Path('/Volumes/Archive/review.avi'))['PASS'])

    def test_existing_evidence_is_never_replaced(self):
        with patch.object(Path, 'exists', return_value=True):
            with self.assertRaisesRegex(RuntimeError, 'Existing native evidence preserved'):
                guard.budget('/internal/source', Path('/unused/review.avi'), 1000, 60)

    def test_invalid_unbounded_requests_are_refused(self):
        for frames, fps in [(0, 60), (6001, 60), (1000, 120)]:
            with self.subTest(frames=frames, fps=fps):
                with self.assertRaisesRegex(RuntimeError, 'bounded native frame count'):
                    guard.budget('/internal/source', Path('/unused/review.avi'), frames, fps)


if __name__ == "__main__":
    unittest.main()
