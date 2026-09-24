#!/usr/bin/env python3
"""Digital hero-pose uniqueness for the six proof actions. Not human acting."""
from __future__ import annotations

from pathlib import Path

from .common import FIGHTER_IDS, REPORTS, write_json
from .hero_poses_v3 import charge_100_v3, heavy_sequence_v3, hurt_heavy_sequence_v3, idle_v3, super_pose_v3
from .pose_library import pose_delta_metrics
from .validate_exaggeration import CHARGE_MIN, HEAVY_MIN, HURT_MIN, _pass

REVIEW = Path(__file__).resolve().parents[2] / "artifacts/vxp3/review/generated_art_v3"
SHEETS = REVIEW / "design_sheets"

PACKET_LABELS = (
    "idle",
    "walk",
    "run",
    "close_body_3q",
    "silhouette",
    "head_detail",
    "hand_detail",
    "foot_detail",
    "costume_detail",
    "heavy_anticipation",
    "heavy_contact",
    "heavy_follow",
    "hurt_heavy",
    "charge_100_vfx_on",
    "charge_100_vfx_off",
    "super",
    "KO",
)
SHEET_LABELS = (
    "front",
    "side",
    "back",
    "3q",
    "silhouette",
    "head_detail",
    "hand_foot_detail",
    "costume_detail",
    "charge_100",
    "heavy_contact",
)
MIN_CROSS = 0.85


def _cross(fn) -> list[dict]:
    poses = {fid: fn(fid) for fid in FIGHTER_IDS}
    rows = []
    ids = list(FIGHTER_IDS)
    for i, a in enumerate(ids):
        for b in ids[i + 1 :]:
            metrics = pose_delta_metrics(poses[a], poses[b])
            rows.append({"a": a, "b": b, **metrics, "ok": metrics["silhouette_delta"] >= MIN_CROSS})
    return rows


def _packet_ok() -> bool:
    for fid in FIGHTER_IDS:
        for label in PACKET_LABELS:
            if not (REVIEW / fid / f"{label}.png").is_file():
                return False
    return True


def _sheets_ok() -> bool:
    for fid in FIGHTER_IDS:
        for label in SHEET_LABELS:
            if not (SHEETS / fid / f"{label}.png").is_file():
                return False
    return True


def validate() -> dict:
    heavy_ok = True
    hurt_ok = True
    charge_ok = True
    failures = []
    per = {}
    for fid in FIGHTER_IDS:
        idle = idle_v3(fid)
        heavy = pose_delta_metrics(idle, heavy_sequence_v3(fid)["CONTACT"])
        hurt = pose_delta_metrics(idle, hurt_heavy_sequence_v3(fid)["CONTACT"])
        charge = pose_delta_metrics(idle, charge_100_v3(fid))
        super_m = pose_delta_metrics(idle, super_pose_v3(fid))
        h_ok, h_fail = _pass(heavy, HEAVY_MIN)
        u_ok, u_fail = _pass(hurt, HURT_MIN)
        c_ok, c_fail = _pass(charge, CHARGE_MIN)
        s_ok = super_m["silhouette_delta"] >= 2.2
        heavy_ok = heavy_ok and h_ok
        hurt_ok = hurt_ok and u_ok
        charge_ok = charge_ok and c_ok
        if not h_ok:
            failures.append({"fighter": fid, "action": "heavy", "fails": h_fail})
        if not u_ok:
            failures.append({"fighter": fid, "action": "hurt", "fails": u_fail})
        if not c_ok:
            failures.append({"fighter": fid, "action": "charge", "fails": c_fail})
        if not s_ok:
            failures.append({"fighter": fid, "action": "super", "fails": [f"silhouette {super_m['silhouette_delta']:.3f} < 2.2"]})
        per[fid] = {"heavy": heavy, "hurt": hurt, "charge": charge, "super": super_m, "super_ok": s_ok}
    heavy_x = _cross(lambda fid: heavy_sequence_v3(fid)["CONTACT"])
    hurt_x = _cross(lambda fid: hurt_heavy_sequence_v3(fid)["CONTACT"])
    super_x = _cross(super_pose_v3)
    packet = _packet_ok()
    sheets = _sheets_ok()
    payload = {
        "ok": heavy_ok and hurt_ok and charge_ok and not failures,
        "failures": failures,
        "fighters": per,
        "heavy_cross": heavy_x,
        "hurt_cross": hurt_x,
        "super_cross": super_x,
        "GEN_ART_V3_HERO_POSE_PASS": heavy_ok and charge_ok and not failures,
        "GEN_ART_V3_HEAVY_CONTACT_PASS": heavy_ok and all(row["ok"] for row in heavy_x),
        "GEN_ART_V3_HURT_POSE_PASS": hurt_ok and all(row["ok"] for row in hurt_x),
        "GEN_ART_V3_CHARGE_BODY_READ_PASS": charge_ok,
        "GEN_ART_V3_SUPER_POSE_PASS": all(row["super_ok"] for row in per.values()) and all(row["ok"] for row in super_x),
        "GEN_ART_V3_DESIGN_SHEET_PASS": sheets,
        "packet_complete": packet,
        "design_sheets_complete": sheets,
        "human_acting": False,
    }
    write_json(REPORTS / "GENERATED_ART_V3_HERO.json", payload)
    return payload


if __name__ == "__main__":
    import json

    print(json.dumps(validate(), indent=2))
