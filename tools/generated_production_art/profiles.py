"""Per-fighter generated production identity. Original designs only."""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class FighterProfile:
    fighter_id: str
    display_name: str
    element: str
    role: str
    primary: tuple[float, float, float]
    secondary: tuple[float, float, float]
    accent: tuple[float, float, float]
    charged: tuple[float, float, float]
    outline: tuple[float, float, float]
    skin: tuple[float, float, float]
    hair: tuple[float, float, float]
    body_scale: tuple[float, float, float]
    head_scale: float
    hand_scale: float
    foot_scale: float
    torso_width: float
    lean: float
    timing: float
    snap: float
    weight: float
    bounce: float
    delay: float
    false_start: float
    accessory: str
    accessory_bone: str
    clash_vfx: str
    audio_color: float
    silhouette_notes: str
    motion_notes: str


def _rgb(h: str) -> tuple[float, float, float]:
    return (int(h[0:2], 16) / 255.0, int(h[2:4], 16) / 255.0, int(h[4:6], 16) / 255.0)


PROFILES: dict[str, FighterProfile] = {
    "ember-vale": FighterProfile(
        fighter_id="ember-vale",
        display_name="Ember Vale",
        element="flame",
        role="rushdown",
        primary=_rgb("E84A3C"),
        secondary=_rgb("6C2630"),
        accent=_rgb("FFB33B"),
        charged=_rgb("FFE08A"),
        outline=_rgb("241922"),
        skin=_rgb("F3C7A8"),
        hair=_rgb("FF6A2A"),
        body_scale=(0.96, 1.02, 0.94),
        head_scale=1.04,
        hand_scale=1.28,
        foot_scale=1.12,
        torso_width=0.92,
        lean=0.22,
        timing=0.86,
        snap=0.78,
        weight=0.55,
        bounce=0.42,
        delay=0.08,
        false_start=0.04,
        accessory="flame_gauntlets",
        accessory_bone="Cloth_Flame_R",
        clash_vfx="flame_pressure",
        audio_color=220.0,
        silhouette_notes="Athletic forward wedge, angular gauntlets, ember vents.",
        motion_notes="Forward lean, explosive hip rotation, flame-follow arm trails.",
    ),
    "rook-ironside": FighterProfile(
        fighter_id="rook-ironside",
        display_name="Rook Ironside",
        element="impact",
        role="bruiser",
        primary=_rgb("8C5A3C"),
        secondary=_rgb("30384A"),
        accent=_rgb("E28A36"),
        charged=_rgb("F2C27A"),
        outline=_rgb("181A20"),
        skin=_rgb("C9A07A"),
        hair=_rgb("3A2A22"),
        body_scale=(1.22, 1.10, 1.12),
        head_scale=0.92,
        hand_scale=1.34,
        foot_scale=1.38,
        torso_width=1.28,
        lean=-0.04,
        timing=1.22,
        snap=0.42,
        weight=1.35,
        bounce=0.12,
        delay=0.18,
        false_start=0.0,
        accessory="impact_armor",
        accessory_bone="Cloth_ArmorFlap",
        clash_vfx="impact_shock",
        audio_color=90.0,
        silhouette_notes="Broad torso, heavy gauntlets, reinforced boots, strongest mass.",
        motion_notes="Planted, slow load, huge release, crushing follow-through.",
    ),
    "juno-spark": FighterProfile(
        fighter_id="juno-spark",
        display_name="Juno Spark",
        element="volt",
        role="speed",
        primary=_rgb("F4D94E"),
        secondary=_rgb("202839"),
        accent=_rgb("72E6FF"),
        charged=_rgb("E8FFFF"),
        outline=_rgb("12151D"),
        skin=_rgb("F2D2B4"),
        hair=_rgb("FFE56A"),
        body_scale=(0.88, 0.96, 0.86),
        head_scale=1.08,
        hand_scale=1.10,
        foot_scale=0.92,
        torso_width=0.82,
        lean=0.10,
        timing=0.70,
        snap=1.25,
        weight=0.40,
        bounce=0.55,
        delay=0.02,
        false_start=0.16,
        accessory="volt_panels",
        accessory_bone="Cloth_VoltTag",
        clash_vfx="electric_fork",
        audio_color=880.0,
        silhouette_notes="Lean body, sharp panels, asymmetric electric accents.",
        motion_notes="Staccato, twitch energy, snap poses, fast recovery.",
    ),
    "kaia-windrow": FighterProfile(
        fighter_id="kaia-windrow",
        display_name="Kaia Windrow",
        element="gale",
        role="aerial",
        primary=_rgb("3CBF91"),
        secondary=_rgb("1F5360"),
        accent=_rgb("B8FFF1"),
        charged=_rgb("E7FFF8"),
        outline=_rgb("15262B"),
        skin=_rgb("E8C4A4"),
        hair=_rgb("7EE0C4"),
        body_scale=(0.90, 1.04, 0.88),
        head_scale=1.02,
        hand_scale=1.08,
        foot_scale=1.00,
        torso_width=0.84,
        lean=0.08,
        timing=0.92,
        snap=0.58,
        weight=0.48,
        bounce=0.88,
        delay=0.12,
        false_start=0.06,
        accessory="gale_sash",
        accessory_bone="Cloth_Scarf",
        clash_vfx="wind_vortex",
        audio_color=340.0,
        silhouette_notes="Long flowing lines, scarf/ribbon, wing-like airfoil motifs.",
        motion_notes="Arcs, buoyancy, aerial extension, cloth follow-through.",
    ),
    "nix-calder": FighterProfile(
        fighter_id="nix-calder",
        display_name="Nix Calder",
        element="frost",
        role="precision",
        primary=_rgb("4C91D8"),
        secondary=_rgb("D8F4FF"),
        accent=_rgb("83E8FF"),
        charged=_rgb("F4FDFF"),
        outline=_rgb("172A42"),
        skin=_rgb("E4D4C6"),
        hair=_rgb("C7E8F8"),
        body_scale=(1.02, 1.00, 1.00),
        head_scale=0.98,
        hand_scale=1.20,
        foot_scale=1.16,
        torso_width=0.98,
        lean=0.00,
        timing=1.04,
        snap=0.90,
        weight=0.78,
        bounce=0.10,
        delay=0.04,
        false_start=0.0,
        accessory="frost_crystals",
        accessory_bone="Cloth_Crystal",
        clash_vfx="frost_plane",
        audio_color=510.0,
        silhouette_notes="Centered compact silhouette, crystalline details, strong gloves/boots.",
        motion_notes="Minimal wasted motion, precision, stiffness-on-impact.",
    ),
    "orion-vell": FighterProfile(
        fighter_id="orion-vell",
        display_name="Orion Vell",
        element="gravity",
        role="control",
        primary=_rgb("6554A6"),
        secondary=_rgb("252340"),
        accent=_rgb("C795FF"),
        charged=_rgb("E8D2FF"),
        outline=_rgb("161522"),
        skin=_rgb("D8C4B4"),
        hair=_rgb("3A2A4A"),
        body_scale=(1.04, 1.02, 0.96),
        head_scale=1.00,
        hand_scale=1.16,
        foot_scale=1.08,
        torso_width=1.04,
        lean=-0.06,
        timing=1.10,
        snap=0.50,
        weight=0.82,
        bounce=0.28,
        delay=0.28,
        false_start=0.08,
        accessory="gravity_rings",
        accessory_bone="Cloth_Orbit",
        clash_vfx="gravity_lens",
        audio_color=140.0,
        silhouette_notes="Orbital rings, layered geometric clothing, circular motifs.",
        motion_notes="Hand-led motion, orbit, delayed body follow, compression/release.",
    ),
    "vesper-nyx": FighterProfile(
        fighter_id="vesper-nyx",
        display_name="Vesper Nyx",
        element="void",
        role="trickster",
        primary=_rgb("7C3EA2"),
        secondary=_rgb("1D1830"),
        accent=_rgb("D272FF"),
        charged=_rgb("F0B8FF"),
        outline=_rgb("0D0B14"),
        skin=_rgb("C9B2C4"),
        hair=_rgb("2A1836"),
        body_scale=(0.92, 1.02, 0.90),
        head_scale=1.06,
        hand_scale=1.14,
        foot_scale=1.04,
        torso_width=0.88,
        lean=0.14,
        timing=0.88,
        snap=1.08,
        weight=0.52,
        bounce=0.36,
        delay=0.22,
        false_start=0.34,
        accessory="void_coat",
        accessory_bone="Coat_Panel_L",
        clash_vfx="void_fold",
        audio_color=70.0,
        silhouette_notes="Asymmetric coat, split offset panels, dark negative-space accents.",
        motion_notes="False starts, delayed tells, snaps, visual displacement.",
    ),
}


def profile(fid: str) -> FighterProfile:
    return PROFILES[fid]
