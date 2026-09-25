#!/usr/bin/env python3
import unittest

from validate_select_critical_launch import OWNER_FALSE, evaluate


class SelectCriticalLaunchTests(unittest.TestCase):
    def test_structural_gates(self) -> None:
        payload = evaluate()
        gates = payload["gates"]
        self.assertEqual(payload["failures"], [])
        self.assertTrue(gates["SELECT_ANNOUNCER_EVENT_PASS"])
        self.assertTrue(gates["SELECT_ANNOUNCER_REVIEW_SPOKEN_NAME_PASS"])
        self.assertFalse(gates["SELECT_ANNOUNCER_AUDIO_RIGHTS_READY"])
        self.assertFalse(gates["ANNOUNCER_FINAL_VOICE_ASSETS"])
        self.assertTrue(gates["ROSTER_ROYGBIV_SELECT_PASS"])
        self.assertTrue(gates["NORMAL_BODY_OPACITY_FLOOR_PASS"])
        self.assertEqual(gates["SELECT_CARD_AUTO_FIT_PASS"], "7/7")
        self.assertEqual(gates["CRITICAL_LAUNCH_ELEMENTAL_MAPPING_PASS"], "7/7")
        for key, value in OWNER_FALSE.items():
            self.assertIs(gates[key], value)


if __name__ == "__main__":
    unittest.main()
