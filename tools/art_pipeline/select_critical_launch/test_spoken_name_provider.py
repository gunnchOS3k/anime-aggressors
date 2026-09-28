#!/usr/bin/env python3
"""Hover stays silent; confirm speaks each roster name exactly once in source contract."""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
VOICE = (ROOT / "game-godot/scripts/audio/announcer_voice_provider.gd").read_text(encoding="utf-8")
ANNOUNCER = (ROOT / "game-godot/scripts/audio/fighter_announcer.gd").read_text(encoding="utf-8")
HARNESS = (ROOT / "game-godot/tests/presentation/SelectCriticalLaunchHarness.gd").read_text(
    encoding="utf-8"
)

SPOKEN = {
    "ember-vale": "Ember",
    "rook-ironside": "Rook",
    "juno-spark": "Juno",
    "kaia-windrow": "Kaia",
    "nix-calder": "Nix",
    "orion-vell": "Orion",
    "vesper-nyx": "Vesper",
}


class SpokenNameProviderTests(unittest.TestCase):
    def test_seven_spoken_names(self) -> None:
        for fighter_id, name in SPOKEN.items():
            self.assertIn(f'"{fighter_id}": "{name}"', VOICE)

    def test_hover_does_not_speak(self) -> None:
        self.assertIn("hover_does_not_announce", ANNOUNCER)
        self.assertIn("hover_spoke", HARNESS)
        self.assertIn("if hover:", ANNOUNCER)
        self.assertNotIn("_Voice.speak_lockin(fighter_id, host)", ANNOUNCER.split("if hover:")[1].split("if not can_announce")[0])

    def test_confirm_speaks_once_in_debounce_contract(self) -> None:
        self.assertIn("_Voice.speak_lockin", ANNOUNCER)
        self.assertIn("debounce_not_once", HARNESS)
        self.assertIn("confirm_did_not_speak", HARNESS)

    def test_rights_remain_false(self) -> None:
        self.assertIn("ANNOUNCER_FINAL_VOICE_ASSETS := false", VOICE)
        self.assertIn("SELECT_ANNOUNCER_AUDIO_RIGHTS_READY := false", VOICE)
        self.assertIn("REVIEW_ONLY := true", VOICE)
        self.assertNotIn("ANNOUNCER_FINAL_VOICE_ASSETS := true", VOICE)


if __name__ == "__main__":
    unittest.main()
