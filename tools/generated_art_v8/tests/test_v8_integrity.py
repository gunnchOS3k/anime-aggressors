"""v8 stays generated, keeps the graphic style lock, and classifies every costume part."""
from __future__ import annotations

import unittest
from pathlib import Path

from generated_art_v8.attachment_map import CLASSES, classify_name
from generated_art_v8.body_profiles import (
    FIGHTER_IDS,
    STYLE_LOCK_V8,
    STYLE_PROFILES,
    load_pairs,
    load_palettes,
    luma,
    palette_value_ok,
)
from generated_art_v8.hero_poses import idle_v8, overlay_table, pose_delta_ok, pose_v8
from generated_art_v8.impact_pair_solver import geometry_ok, solve_from_rest
from generated_art_v8.pair_scenes import defender_for
from generated_art_v8.render_review import REQUIRED_SHOTS


KNOWN_PARTS = (
    "torso_shell",
    "coat_layer",
    "head_shell",
    "hand_L",
    "hand_R",
    "hand_R_open",
    "hand_R_guard",
    "boot_L",
    "boot_R",
    "frost_cuirass",
    "frost_plastron",
    "frost_pauldron_r",
    "frost_pauldron_l",
    "crystal_core",
    "crystal_trim",
    "forearm_plate_r",
    "shin_facet_r",
    "waist_band",
    "heat_cuirass",
    "heat_vent",
    "shoulder_heat_wedge",
    "chest_mass",
    "shoulder_pad_l",
    "volt_sash",
    "speed_panel_chest",
    "hip_panel_r",
    "scarf_collar",
    "scarf_fall",
    "airfoil_l",
    "airfoil_r",
    "authority_panel",
    "orbit_trim",
    "orbit_ring",
    "coat_cowl",
    "coat_panel_l",
    "coat_tail_l",
    "void_trim",
)


class V8IntegrityTests(unittest.TestCase):
    def test_doc_exists(self):
        self.assertTrue(STYLE_LOCK_V8.is_file())
        text = STYLE_LOCK_V8.read_text(encoding="utf-8")
        self.assertIn("graphic_lowpoly_cel_combat", text)
        self.assertIn("SKINNED_COSTUME", text)

    def test_known_parts_classified(self):
        for name in KNOWN_PARTS:
            classified = classify_name(name)
            self.assertIsNotNone(classified, name)
            cls, bone, _float = classified
            self.assertIn(cls, CLASSES, name)
            self.assertNotEqual(cls, "WORLD_STATIC", name)
            if cls != "SKINNED_COSTUME":
                self.assertTrue(bone, name)

    def test_orbit_is_intentional_vfx(self):
        cls, bone, floating = classify_name("orbit_ring")
        self.assertEqual(cls, "VFX_ORBIT")
        self.assertTrue(floating)
        self.assertEqual(bone, "Chest")

    def test_nix_value_split(self):
        pal = load_palettes()["nix-calder"]
        self.assertLess(luma(pal["undersuit"]), 0.12)
        self.assertGreater(luma(pal["armor"]), 0.72)
        self.assertTrue(palette_value_ok("nix-calder"))

    def test_all_palettes_have_three_groups(self):
        for fid in FIGHTER_IDS:
            self.assertTrue(palette_value_ok(fid), fid)
            self.assertLess(luma(load_palettes()[fid]["undersuit"]), 0.16, fid)

    def test_cool_fighters_have_large_mid_or_pale(self):
        for fid in ("juno-spark", "kaia-windrow", "orion-vell", "vesper-nyx"):
            pal = load_palettes()[fid]
            self.assertGreaterEqual(len(pal["value_groups"]), 3, fid)
            self.assertGreater(luma(pal["armor"]) - luma(pal["undersuit"]), 0.20, fid)

    def test_pair_matchups_and_contact_spec(self):
        defs = [defender_for(fid) for fid in FIGHTER_IDS]
        self.assertEqual(len(set(defs)), 7)
        pairs = load_pairs()
        for fid in FIGHTER_IDS:
            self.assertNotEqual(fid, defender_for(fid))
            spec = pairs["contact"][fid]
            self.assertIn(spec["anchor"], {"HEAD", "CHEST", "TORSO_LEFT", "TORSO_RIGHT", "PELVIS", "UPPER_GUARD", "LOWER_GUARD"})
            row = solve_from_rest(fid)
            self.assertTrue(row["review_only"])
            self.assertTrue(row["gameplay_unchanged"])
            self.assertTrue(geometry_ok(row), fid)

    def test_poses_cover_acting(self):
        for fid in FIGHTER_IDS:
            idle = idle_v8(fid)
            self.assertTrue(pose_delta_ok(idle, pose_v8(fid, "hurt_peak"), ("Head", "Chest", "Hips", "UpperArm_R", "UpperLeg_R")), fid)
            self.assertTrue(pose_delta_ok(idle, pose_v8(fid, "charge"), ("Chest", "Head", "Hips", "UpperArm_R", "UpperArm_L")), fid)
            self.assertTrue(pose_delta_ok(idle, pose_v8(fid, "super"), ("UpperArm_R", "UpperArm_L", "Chest", "Hips")), fid)
            table = overlay_table(fid)
            self.assertIn("walk", table)
            self.assertIn(11, table["heavy"])

    def test_idle_identities_differ(self):
        distinct = 0
        ember = idle_v8("ember-vale")
        for fid in FIGHTER_IDS:
            if fid == "ember-vale":
                continue
            if pose_delta_ok(ember, idle_v8(fid), ("Hips", "Chest", "Head", "UpperArm_R", "UpperArm_L", "UpperLeg_R")):
                distinct += 1
        self.assertGreaterEqual(distinct, 5)

    def test_packet_includes_contact_and_stress(self):
        self.assertIn("heavy_contact_pair_off", REQUIRED_SHOTS)
        self.assertIn("heavy_contact_pair_debug", REQUIRED_SHOTS)
        self.assertIn("glove_guard", REQUIRED_SHOTS)
        self.assertIn("attachment_stress", REQUIRED_SHOTS)
        self.assertIn("personality_idle", REQUIRED_SHOTS)

    def test_profiles_keep_v6_families(self):
        self.assertEqual(set(STYLE_PROFILES), set(FIGHTER_IDS))
        self.assertTrue(all(p.hero_feature for p in STYLE_PROFILES.values()))

    def test_roadmap_mentions_v8(self):
        roadmap = Path(__file__).resolve().parents[3] / "docs/art/FUTURE_HUMAN_ART_ROADMAP.md"
        text = roadmap.read_text(encoding="utf-8")
        self.assertIn("v8", text)

    def test_human_gates_stay_false_in_data(self):
        pal = json_load_human_check()
        self.assertFalse(pal.get("human_authored"))


def json_load_human_check() -> dict:
    import json

    path = Path(__file__).resolve().parents[3] / "game-godot/data/art/generated_v8/palette_blocking.json"
    return json.loads(path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
