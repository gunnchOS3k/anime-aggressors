"""Fighter silhouette contracts for Wave014 procedural production proxies."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence, Tuple

Vec3 = Tuple[float, float, float]


@dataclass(frozen=True)
class SilhouetteContract:
    fighter_id: str
    display_name: str
    lane: str
    visual_language: str
    primary: str
    secondary: str
    accent: str
    outline: str
    body_scale: Vec3 = (1.0, 1.0, 1.0)
    head_scale: float = 1.0
    hand_scale: float = 1.0
    boot_scale: float = 1.0
    accessory: str = "crest"
    mass_read: str = "medium"


ROSTER: Sequence[SilhouetteContract] = (
    SilhouetteContract(
        "ember-vale", "Ember Vale", "flame rushdown", "athletic ignition",
        "E84A3C", "6C2630", "FFB33B", "241922", hand_scale=1.22, accessory="flame_gauntlets", mass_read="light_aggressive",
    ),
    SilhouetteContract(
        "rook-ironside", "Rook Ironside", "impact armor", "mass armor plates",
        "8C5A3C", "30384A", "E28A36", "181A20", body_scale=(1.18, 1.10, 1.05), head_scale=0.95,
        hand_scale=1.18, boot_scale=1.28, accessory="impact_armor", mass_read="heavy_armored",
    ),
    SilhouetteContract(
        "juno-spark", "Juno Spark", "lightning speed", "compact speed lines",
        "F4D94E", "202839", "72E6FF", "12151D", body_scale=(0.90, 0.94, 0.92), head_scale=1.06,
        accessory="volt_scarf", mass_read="compact_fast",
    ),
    SilhouetteContract(
        "kaia-windrow", "Kaia Windrow", "wind aerial control", "flowing aerial sash",
        "3CBF91", "1F5360", "B8FFF1", "15262B", body_scale=(0.94, 0.98, 0.92), head_scale=1.03,
        accessory="gale_sash", mass_read="flowing_aerial",
    ),
    SilhouetteContract(
        "nix-calder", "Nix Calder", "frost stage control", "crystalline mantle",
        "4C91D8", "D8F4FF", "83E8FF", "172A42", body_scale=(1.08, 1.06, 1.04), boot_scale=1.12,
        accessory="frost_mantle", mass_read="crystalline_control",
    ),
    SilhouetteContract(
        "orion-vell", "Orion Vell", "gravity vector control", "orbit geometry rings",
        "6554A6", "252340", "C795FF", "161522", body_scale=(1.02, 1.0, 0.98),
        accessory="gravity_rings", mass_read="orbit_vector",
    ),
    SilhouetteContract(
        "vesper-nyx", "Vesper Nyx", "void phase trickster", "asymmetric void hood",
        "7C3EA2", "1D1830", "D272FF", "0D0B14", body_scale=(0.94, 0.98, 0.94), head_scale=1.05,
        accessory="void_hood", mass_read="asymmetric_void",
    ),
)


def by_id(fighter_id: str) -> SilhouetteContract:
    for item in ROSTER:
        if item.fighter_id == fighter_id:
            return item
    raise KeyError(fighter_id)
