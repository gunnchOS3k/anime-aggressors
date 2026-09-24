"""v7 generated acting overlays. Distinct per fighter. Not human-authored."""
from __future__ import annotations

from generated_art_v6.hero_poses import apply_goal
from generated_production_art.hero_poses_v4 import charge_100_v4, idle_v4, super_pose_v4
from generated_production_art.pose_library import _e, add, blank

BONE_KEYS = (
    "Hips",
    "Spine",
    "Chest",
    "Head",
    "Neck",
    "UpperArm_L",
    "UpperArm_R",
    "LowerArm_L",
    "LowerArm_R",
    "Hand_L",
    "Hand_R",
    "UpperLeg_L",
    "UpperLeg_R",
    "LowerLeg_L",
    "LowerLeg_R",
    "Foot_L",
    "Foot_R",
)


def _pose(**kwargs):
    out = blank()
    for key, val in kwargs.items():
        out[key] = _e(*val) if not isinstance(val, tuple) else val
    return out


def _identity(fid: str) -> dict:
    if fid == "ember-vale":
        return {
            "idle": _pose(
                Hips=(0.10, 0.18, 0.08), Spine=(-0.20, 0.16, 0.08), Chest=(-0.34, 0.28, 0.16),
                Head=(0.16, 0.22, 0.08), UpperArm_R=(0.62, -0.78, 0.52), UpperArm_L=(0.30, 0.50, -0.36),
                LowerArm_R=(0.32, -0.20, 0.14), LowerArm_L=(0.18, 0.14, -0.10),
                UpperLeg_R=(0.12, 0.10, 0.20), UpperLeg_L=(0.22, -0.08, -0.12),
                LowerLeg_R=(0.10, 0.0, 0.04), LowerLeg_L=(0.16, 0.0, -0.04),
            ),
            "walk": _pose(
                Hips=(0.08, 0.22, 0.10), Chest=(-0.28, 0.32, 0.14), Head=(0.12, 0.18, 0.06),
                UpperArm_R=(0.48, -0.90, 0.20), UpperArm_L=(0.55, 0.70, -0.18),
                UpperLeg_R=(0.42, 0.08, 0.10), UpperLeg_L=(-0.10, -0.08, -0.08),
            ),
            "run": _pose(
                Hips=(-0.06, 0.28, 0.10), Chest=(-0.18, 0.40, 0.16), Head=(0.10, 0.24, 0.08),
                UpperArm_R=(0.70, -1.00, 0.18), UpperArm_L=(0.72, 0.86, -0.16),
                UpperLeg_R=(0.70, 0.10, 0.12), UpperLeg_L=(-0.28, -0.10, -0.10),
            ),
            "dash": _pose(
                Hips=(-0.16, 0.36, 0.12), Chest=(0.10, 0.48, 0.18), Head=(-0.08, 0.30, 0.10),
                UpperArm_R=(0.90, -0.20, 0.86), UpperArm_L=(0.22, 0.70, -0.40),
                UpperLeg_R=(0.18, 0.12, 0.16), UpperLeg_L=(0.55, -0.10, -0.12),
            ),
            "charge": _pose(
                Hips=(-0.30, 0.18, 0.04), Spine=(-0.46, 0.18, 0.08), Chest=(-0.88, 0.30, 0.16),
                Head=(-0.34, 0.18, 0.06), UpperArm_R=(0.78, 0.26, 0.92), UpperArm_L=(0.74, -0.22, -0.86),
                UpperLeg_R=(0.22, 0.12, 0.22), UpperLeg_L=(0.28, -0.10, -0.16),
            ),
            "heavy_pre": _pose(
                Hips=(-0.18, 0.22, 0.08), Chest=(-0.52, 0.40, 0.14), Head=(-0.20, 0.22, 0.08),
                UpperArm_R=(0.95, 0.30, 0.70), UpperArm_L=(0.20, 0.50, -0.36),
                UpperLeg_R=(0.16, 0.10, 0.18), UpperLeg_L=(0.30, -0.08, -0.12),
            ),
            "heavy_contact": _pose(
                Hips=(-0.24, 0.36, 0.12), Spine=(0.20, 0.30, 0.10), Chest=(0.58, 0.66, 0.20),
                Head=(-0.18, 0.28, 0.12), UpperArm_R=(0.88, -0.16, 1.12), UpperArm_L=(0.18, 0.66, -0.50),
                LowerArm_R=(0.12, 0.08, 0.22), UpperLeg_R=(0.10, 0.12, 0.18), UpperLeg_L=(0.34, -0.10, -0.12),
            ),
            "heavy_follow": _pose(
                Hips=(0.10, 0.40, 0.14), Chest=(0.72, 0.50, 0.16), Head=(0.16, 0.22, 0.10),
                UpperArm_R=(0.40, -0.70, 0.86), UpperArm_L=(0.30, 0.58, -0.30),
                UpperLeg_R=(0.22, 0.10, 0.16), UpperLeg_L=(0.18, -0.10, -0.12),
            ),
            "hurt_pre": _pose(
                Hips=(0.06, 0.08, 0.04), Chest=(-0.10, 0.12, 0.08), Head=(0.08, 0.10, 0.04),
                UpperArm_R=(0.40, -0.40, 0.36), UpperArm_L=(0.36, 0.38, -0.32),
            ),
            "hurt_peak": _pose(
                Hips=(0.32, -0.24, 0.14), Spine=(0.40, -0.18, 0.10), Chest=(0.78, -0.38, 0.16),
                Head=(0.62, -0.32, 0.14), UpperArm_R=(-0.22, -0.78, 0.24), UpperArm_L=(-0.16, 0.74, -0.22),
                UpperLeg_R=(0.36, 0.12, 0.20), UpperLeg_L=(-0.18, -0.14, -0.12),
                LowerLeg_R=(0.18, 0.0, 0.06), Foot_R=(-0.08, 0.06, 0.04),
            ),
            "launch": _pose(
                Hips=(0.48, -0.18, 0.16), Chest=(0.92, -0.28, 0.18), Head=(0.70, -0.24, 0.16),
                UpperArm_R=(-0.30, -0.86, 0.20), UpperArm_L=(-0.24, 0.82, -0.18),
                UpperLeg_R=(0.50, 0.10, 0.16), UpperLeg_L=(0.10, -0.12, -0.10),
            ),
            "super": _pose(
                Hips=(-0.38, 0.32, 0.14), Spine=(0.24, 0.32, 0.12), Chest=(0.90, 0.58, 0.20),
                Head=(-0.18, 0.28, 0.12), UpperArm_R=(1.22, -0.08, 0.36), UpperArm_L=(0.28, 0.82, -0.24),
                UpperLeg_R=(0.12, 0.12, 0.18), UpperLeg_L=(0.36, -0.10, -0.12),
            ),
            "clash_start": _pose(Hips=(-0.08, 0.12, 0.0), Chest=(-0.18, 0.16, 0.0), UpperArm_R=(0.40, 0.46, 0.50), UpperArm_L=(0.40, -0.46, -0.50)),
            "clash_lock": _pose(
                Hips=(-0.16, 0.12, 0.0), Spine=(-0.30, 0.14, 0.0), Chest=(-0.40, 0.24, 0.0),
                Head=(-0.14, 0.16, 0.0), UpperArm_R=(0.56, 0.66, 0.76), UpperArm_L=(0.56, -0.66, -0.76),
                UpperLeg_R=(0.30, 0.12, 0.24), UpperLeg_L=(0.30, -0.12, -0.24),
            ),
            "clash_push": _pose(Hips=(-0.22, 0.14, 0.0), Chest=(-0.48, 0.28, 0.0), UpperArm_R=(0.62, 0.70, 0.80), UpperArm_L=(0.62, -0.70, -0.80), Head=(-0.18, 0.18, 0.0)),
            "clash_win": _pose(Hips=(-0.10, 0.18, 0.0), Chest=(-0.12, 0.32, 0.08), UpperArm_R=(0.70, 0.50, 0.72), UpperArm_L=(0.48, -0.58, -0.64), Head=(0.08, 0.16, 0.0)),
            "clash_lose": _pose(Hips=(0.18, -0.08, 0.0), Chest=(0.28, -0.16, 0.0), Head=(0.22, -0.12, 0.0), UpperArm_R=(0.36, 0.48, 0.52), UpperArm_L=(0.36, -0.48, -0.52)),
            "clash_break": _pose(Hips=(0.06, 0.20, 0.08), Chest=(0.16, 0.24, 0.10), UpperArm_R=(0.22, -0.40, 0.30), UpperArm_L=(0.22, 0.40, -0.30)),
        }
    if fid == "rook-ironside":
        return {
            "idle": _pose(
                Hips=(0.06, 0.0, 0.0), Spine=(0.08, 0.0, 0.0), Chest=(0.14, 0.0, 0.0),
                Head=(-0.10, 0.0, 0.0), UpperArm_R=(0.42, -0.30, 0.50), UpperArm_L=(0.42, 0.30, -0.50),
                LowerArm_R=(0.46, -0.12, 0.18), LowerArm_L=(0.46, 0.12, -0.18),
                UpperLeg_R=(0.20, 0.12, 0.26), UpperLeg_L=(0.20, -0.12, -0.26),
            ),
            "walk": _pose(Hips=(0.04, 0.06, 0.0), Chest=(0.12, 0.08, 0.0), UpperArm_R=(0.36, -0.40, 0.36), UpperArm_L=(0.36, 0.40, -0.36), UpperLeg_R=(0.36, 0.10, 0.16), UpperLeg_L=(0.04, -0.10, -0.16)),
            "run": _pose(Hips=(-0.04, 0.10, 0.0), Chest=(0.16, 0.14, 0.0), UpperArm_R=(0.50, -0.56, 0.30), UpperArm_L=(0.50, 0.56, -0.30), UpperLeg_R=(0.50, 0.10, 0.14), UpperLeg_L=(-0.10, -0.10, -0.14)),
            "dash": _pose(Hips=(-0.12, 0.08, 0.0), Chest=(0.28, 0.12, 0.0), UpperArm_R=(0.80, -0.16, 0.70), UpperArm_L=(0.28, 0.40, -0.28), UpperLeg_R=(0.22, 0.12, 0.20), UpperLeg_L=(0.36, -0.10, -0.16)),
            "charge": _pose(
                Hips=(-0.22, 0.0, 0.0), Spine=(-0.32, 0.0, 0.0), Chest=(-0.56, 0.0, 0.0),
                Head=(-0.18, 0.0, 0.0), UpperArm_R=(0.68, 0.20, 0.76), UpperArm_L=(0.68, -0.20, -0.76),
                UpperLeg_R=(0.24, 0.12, 0.24), UpperLeg_L=(0.24, -0.12, -0.24),
            ),
            "heavy_pre": _pose(Hips=(-0.16, 0.08, 0.0), Chest=(-0.28, 0.12, 0.0), UpperArm_R=(1.05, 0.16, 0.60), UpperArm_L=(0.24, 0.36, -0.24)),
            "heavy_contact": _pose(
                Hips=(-0.22, 0.14, 0.0), Chest=(0.50, 0.24, 0.0), Head=(-0.14, 0.12, 0.0),
                UpperArm_R=(1.00, -0.08, 0.94), UpperArm_L=(0.26, 0.44, -0.30),
                UpperLeg_R=(0.18, 0.12, 0.22), UpperLeg_L=(0.22, -0.10, -0.18),
            ),
            "heavy_follow": _pose(Hips=(0.08, 0.10, 0.0), Chest=(0.36, 0.16, 0.0), UpperArm_R=(0.50, -0.36, 0.70), UpperArm_L=(0.30, 0.36, -0.24)),
            "hurt_pre": _pose(Hips=(0.04, 0.0, 0.0), Chest=(0.08, 0.0, 0.0), UpperArm_R=(0.36, -0.28, 0.40), UpperArm_L=(0.36, 0.28, -0.40)),
            "hurt_peak": _pose(
                Hips=(0.22, 0.0, 0.0), Spine=(0.30, 0.0, 0.0), Chest=(0.54, 0.0, 0.0),
                Head=(0.38, 0.0, 0.0), UpperArm_R=(-0.12, -0.58, 0.18), UpperArm_L=(-0.12, 0.58, -0.18),
                UpperLeg_R=(0.26, 0.10, 0.16), UpperLeg_L=(0.12, -0.10, -0.12),
            ),
            "launch": _pose(Hips=(0.36, 0.0, 0.0), Chest=(0.68, 0.0, 0.0), Head=(0.46, 0.0, 0.0), UpperArm_R=(-0.20, -0.64, 0.16), UpperArm_L=(-0.18, 0.64, -0.16)),
            "super": _pose(
                Hips=(-0.22, 0.0, 0.0), Chest=(0.48, 0.20, 0.0), Head=(-0.14, 0.12, 0.0),
                UpperArm_R=(1.28, -0.04, 0.28), UpperArm_L=(0.26, 0.42, -0.20),
                UpperLeg_R=(0.20, 0.12, 0.22), UpperLeg_L=(0.22, -0.10, -0.18),
            ),
            "clash_start": _pose(Hips=(-0.08, 0.0, 0.0), Chest=(-0.16, 0.0, 0.0), UpperArm_R=(0.40, 0.46, 0.54), UpperArm_L=(0.40, -0.46, -0.54)),
            "clash_lock": _pose(
                Hips=(-0.18, 0.0, 0.0), Spine=(-0.28, 0.0, 0.0), Chest=(-0.42, 0.0, 0.0),
                Head=(-0.16, 0.0, 0.0), UpperArm_R=(0.62, 0.68, 0.82), UpperArm_L=(0.62, -0.68, -0.82),
                UpperLeg_R=(0.38, 0.16, 0.30), UpperLeg_L=(0.38, -0.16, -0.30),
            ),
            "clash_push": _pose(Hips=(-0.18, 0.0, 0.0), Chest=(-0.40, 0.0, 0.0), UpperArm_R=(0.58, 0.62, 0.76), UpperArm_L=(0.58, -0.62, -0.76)),
            "clash_win": _pose(Hips=(-0.08, 0.0, 0.0), Chest=(-0.10, 0.08, 0.0), UpperArm_R=(0.66, 0.46, 0.68), UpperArm_L=(0.44, -0.50, -0.60)),
            "clash_lose": _pose(Hips=(0.16, 0.0, 0.0), Chest=(0.26, 0.0, 0.0), Head=(0.18, 0.0, 0.0), UpperArm_R=(0.34, 0.44, 0.50), UpperArm_L=(0.34, -0.44, -0.50)),
            "clash_break": _pose(Hips=(0.04, 0.0, 0.0), Chest=(0.10, 0.0, 0.0), UpperArm_R=(0.28, -0.28, 0.32), UpperArm_L=(0.28, 0.28, -0.32)),
        }
    if fid == "juno-spark":
        return {
            "idle": _pose(
                Hips=(0.04, 0.42, 0.00), Spine=(-0.08, 0.28, 0.10), Chest=(-0.12, 0.36, 0.16),
                Head=(0.28, -0.48, 0.18), UpperArm_R=(0.10, -1.02, 0.18), UpperArm_L=(0.66, 0.86, -0.20),
                UpperLeg_R=(0.06, 0.28, 0.18), UpperLeg_L=(0.32, -0.16, -0.12),
            ),
            "walk": _pose(Hips=(0.06, 0.32, 0.04), Chest=(-0.12, 0.30, 0.12), Head=(0.18, -0.28, 0.12), UpperArm_R=(0.40, -0.96, 0.12), UpperArm_L=(0.62, 0.80, -0.12), UpperLeg_R=(0.36, 0.14, 0.10), UpperLeg_L=(0.02, -0.12, -0.08)),
            "run": _pose(Hips=(-0.04, 0.40, 0.06), Chest=(-0.06, 0.48, 0.14), Head=(0.16, -0.20, 0.12), UpperArm_R=(0.72, -1.10, 0.08), UpperArm_L=(0.76, 0.96, -0.08), UpperLeg_R=(0.68, 0.12, 0.08), UpperLeg_L=(-0.22, -0.12, -0.08)),
            "dash": _pose(Hips=(-0.18, 0.50, 0.08), Chest=(0.16, 0.70, 0.16), Head=(0.08, 0.30, 0.12), UpperArm_R=(1.10, 0.10, 0.40), UpperArm_L=(0.16, 0.80, -0.20), UpperLeg_R=(0.20, 0.16, 0.12), UpperLeg_L=(0.62, -0.10, -0.08)),
            "charge": _pose(
                Hips=(-0.12, 0.24, 0.0), Spine=(-0.36, 0.18, 0.0), Chest=(-0.74, 0.24, 0.0),
                Head=(-0.18, -0.22, 0.10), UpperArm_R=(0.74, 0.30, 0.94), UpperArm_L=(0.68, -0.24, -0.90),
            ),
            "heavy_pre": _pose(Hips=(-0.10, 0.36, 0.08), Chest=(-0.30, 0.50, 0.12), UpperArm_R=(0.96, 0.20, 0.70), UpperArm_L=(-0.08, 0.60, -0.24)),
            "heavy_contact": _pose(
                Hips=(-0.18, 0.50, 0.12), Chest=(0.36, 0.84, 0.16), Head=(0.12, 0.42, 0.12),
                UpperArm_R=(0.92, 0.12, 1.16), UpperArm_L=(-0.12, 0.76, -0.32),
                UpperLeg_R=(0.16, 0.16, 0.12), UpperLeg_L=(0.40, -0.10, -0.08),
            ),
            "heavy_follow": _pose(Hips=(0.08, 0.46, 0.10), Chest=(0.28, 0.60, 0.12), UpperArm_R=(0.36, -0.70, 0.80), UpperArm_L=(0.20, 0.62, -0.22)),
            "hurt_pre": _pose(Hips=(0.06, 0.16, 0.04), Chest=(-0.08, 0.16, 0.08), Head=(0.12, -0.16, 0.08)),
            "hurt_peak": _pose(
                Hips=(0.24, -0.28, 0.12), Spine=(0.34, -0.22, 0.10), Chest=(0.66, -0.42, 0.14),
                Head=(0.52, -0.34, 0.16), UpperArm_R=(-0.24, -0.84, 0.20), UpperArm_L=(-0.20, 0.82, -0.18),
                UpperLeg_R=(0.28, 0.12, 0.12), UpperLeg_L=(-0.12, -0.12, -0.08),
            ),
            "launch": _pose(Hips=(0.40, -0.22, 0.12), Chest=(0.80, -0.34, 0.14), Head=(0.60, -0.28, 0.14), UpperArm_R=(-0.30, -0.90, 0.16), UpperArm_L=(-0.26, 0.88, -0.14)),
            "super": _pose(
                Hips=(-0.28, 0.68, 0.12), Chest=(0.26, 1.08, 0.16), Head=(0.12, 0.50, 0.14),
                UpperArm_R=(1.32, 0.18, 0.22), UpperArm_L=(0.18, 0.94, -0.16),
                UpperLeg_R=(0.16, 0.16, 0.10), UpperLeg_L=(0.48, -0.10, -0.08),
            ),
            "clash_start": _pose(Hips=(-0.06, 0.20, 0.0), Chest=(-0.14, 0.22, 0.0), Head=(0.10, -0.12, 0.08), UpperArm_R=(0.40, 0.50, 0.56), UpperArm_L=(0.40, -0.50, -0.56)),
            "clash_lock": _pose(
                Hips=(-0.10, 0.22, 0.0), Spine=(-0.16, 0.20, 0.0), Chest=(-0.26, 0.28, 0.0),
                Head=(0.14, -0.18, 0.10), UpperArm_R=(0.50, 0.62, 0.70), UpperArm_L=(0.50, -0.62, -0.70),
                UpperLeg_R=(0.22, 0.14, 0.16), UpperLeg_L=(0.22, -0.12, -0.14),
            ),
            "clash_push": _pose(Hips=(-0.16, 0.26, 0.0), Chest=(-0.32, 0.34, 0.0), UpperArm_R=(0.56, 0.66, 0.74), UpperArm_L=(0.56, -0.66, -0.74)),
            "clash_win": _pose(Hips=(-0.06, 0.30, 0.0), Chest=(-0.08, 0.40, 0.08), Head=(0.16, -0.10, 0.08), UpperArm_R=(0.68, 0.48, 0.64)),
            "clash_lose": _pose(Hips=(0.16, 0.08, 0.0), Chest=(0.24, 0.10, 0.0), Head=(0.20, -0.20, 0.10), UpperArm_R=(0.32, 0.46, 0.50), UpperArm_L=(0.32, -0.46, -0.50)),
            "clash_break": _pose(Hips=(0.04, 0.24, 0.06), Chest=(0.10, 0.28, 0.08), UpperArm_R=(0.18, -0.50, 0.22), UpperArm_L=(0.18, 0.50, -0.22)),
        }
    if fid == "kaia-windrow":
        return {
            "idle": _pose(
                Hips=(0.04, 0.08, 0.28), Spine=(-0.18, 0.12, 0.22), Chest=(-0.20, 0.16, 0.34),
                Head=(0.28, 0.14, 0.18), UpperArm_R=(0.10, -0.36, 0.12), UpperArm_L=(0.64, 0.78, -0.10),
                UpperLeg_R=(-0.04, 0.18, 0.08), UpperLeg_L=(0.34, -0.12, -0.12),
            ),
            "walk": _pose(Hips=(0.06, 0.18, 0.18), Chest=(-0.18, 0.26, 0.24), Head=(0.14, 0.22, 0.10), UpperArm_R=(0.28, -0.60, 0.16), UpperArm_L=(0.58, 0.72, -0.12), UpperLeg_R=(0.30, 0.12, 0.10), UpperLeg_L=(0.04, -0.10, -0.08)),
            "run": _pose(Hips=(-0.04, 0.22, 0.20), Chest=(-0.10, 0.34, 0.28), Head=(0.12, 0.24, 0.12), UpperArm_R=(0.50, -0.76, 0.12), UpperArm_L=(0.70, 0.84, -0.10), UpperLeg_R=(0.58, 0.12, 0.08), UpperLeg_L=(-0.16, -0.10, -0.08)),
            "dash": _pose(Hips=(-0.16, 0.20, 0.24), Chest=(0.08, 0.36, 0.36), Head=(0.10, 0.22, 0.14), UpperArm_L=(0.96, 0.40, -0.18), UpperArm_R=(0.20, -0.62, 0.16), UpperLeg_L=(0.88, -0.16, -0.10), UpperLeg_R=(0.10, 0.14, 0.10)),
            "charge": _pose(
                Hips=(-0.22, 0.16, 0.14), Spine=(-0.34, 0.18, 0.14), Chest=(-0.62, 0.26, 0.26),
                Head=(-0.18, 0.22, 0.12), UpperArm_L=(0.76, 0.22, -0.70), UpperArm_R=(0.64, -0.18, 0.66),
            ),
            "heavy_pre": _pose(Hips=(-0.16, 0.18, 0.18), Chest=(-0.20, 0.28, 0.28), UpperArm_L=(0.80, 0.36, -0.20), UpperLeg_L=(0.70, -0.14, -0.08)),
            "heavy_contact": _pose(
                Hips=(-0.22, 0.22, 0.20), Chest=(0.24, 0.40, 0.34), Head=(0.14, 0.26, 0.14),
                UpperArm_L=(0.74, 0.50, -0.24), UpperLeg_L=(0.92, -0.18, -0.12),
                UpperArm_R=(0.16, -0.48, 0.18), UpperLeg_R=(0.08, 0.14, 0.12),
            ),
            "heavy_follow": _pose(Hips=(0.08, 0.20, 0.18), Chest=(0.18, 0.30, 0.28), UpperArm_L=(0.40, 0.62, -0.18), UpperLeg_L=(0.40, -0.12, -0.10)),
            "hurt_pre": _pose(Hips=(0.06, 0.12, 0.12), Chest=(-0.10, 0.16, 0.16), Head=(0.10, 0.16, 0.08)),
            "hurt_peak": _pose(
                Hips=(0.26, 0.14, 0.16), Spine=(0.32, 0.14, 0.14), Chest=(0.60, 0.24, 0.26),
                Head=(0.46, 0.22, 0.14), UpperArm_R=(-0.18, -0.74, 0.18), UpperArm_L=(-0.14, 0.78, -0.16),
                UpperLeg_R=(0.24, 0.12, 0.12), UpperLeg_L=(-0.10, -0.12, -0.10),
            ),
            "launch": _pose(Hips=(0.38, 0.16, 0.18), Chest=(0.72, 0.26, 0.28), Head=(0.54, 0.20, 0.16), UpperArm_R=(-0.24, -0.80, 0.16), UpperArm_L=(-0.20, 0.82, -0.14)),
            "super": _pose(
                Hips=(-0.24, 0.22, 0.24), Chest=(-0.06, 0.46, 0.48), Head=(0.18, 0.28, 0.16),
                UpperArm_L=(1.14, 0.38, -0.18), UpperArm_R=(0.32, -0.62, 0.16),
                UpperLeg_L=(0.70, -0.16, -0.10), UpperLeg_R=(0.10, 0.14, 0.12),
            ),
            "clash_start": _pose(Hips=(-0.08, 0.12, 0.12), Chest=(-0.16, 0.16, 0.16), UpperArm_R=(0.38, 0.44, 0.52), UpperArm_L=(0.38, -0.44, -0.52)),
            "clash_lock": _pose(
                Hips=(-0.12, 0.14, 0.14), Spine=(-0.18, 0.16, 0.14), Chest=(-0.26, 0.22, 0.20),
                Head=(0.12, 0.18, 0.12), UpperArm_R=(0.48, 0.54, 0.64), UpperArm_L=(0.48, -0.54, -0.64),
                UpperLeg_R=(0.20, 0.12, 0.16), UpperLeg_L=(0.22, -0.10, -0.14),
            ),
            "clash_push": _pose(Hips=(-0.16, 0.16, 0.14), Chest=(-0.32, 0.26, 0.22), UpperArm_R=(0.54, 0.58, 0.68), UpperArm_L=(0.54, -0.58, -0.68)),
            "clash_win": _pose(Hips=(-0.08, 0.18, 0.16), Chest=(-0.10, 0.28, 0.24), UpperArm_L=(0.70, 0.40, -0.30), Head=(0.14, 0.20, 0.12)),
            "clash_lose": _pose(Hips=(0.16, 0.08, 0.12), Chest=(0.24, 0.12, 0.14), Head=(0.18, 0.14, 0.10), UpperArm_R=(0.30, 0.42, 0.48), UpperArm_L=(0.30, -0.42, -0.48)),
            "clash_break": _pose(Hips=(0.04, 0.16, 0.16), Chest=(0.08, 0.20, 0.20), UpperArm_R=(0.16, -0.40, 0.18), UpperArm_L=(0.40, 0.50, -0.16)),
        }
    if fid == "nix-calder":
        return {
            "idle": _pose(
                Hips=(0.00, 0.0, 0.0), Spine=(0.02, 0.0, 0.0), Chest=(0.04, 0.0, 0.0),
                Head=(0.02, 0.00, 0.0), UpperArm_R=(0.48, -0.12, 0.62), UpperArm_L=(0.48, 0.12, -0.62),
                LowerArm_R=(0.40, -0.08, 0.14), LowerArm_L=(0.40, 0.08, -0.14),
                UpperLeg_R=(0.10, 0.06, 0.12), UpperLeg_L=(0.10, -0.06, -0.12),
            ),
            "walk": _pose(Hips=(0.02, 0.04, 0.0), Chest=(0.08, 0.04, 0.0), Head=(0.04, 0.04, 0.0), UpperArm_R=(0.36, -0.28, 0.40), UpperArm_L=(0.36, 0.28, -0.40), UpperLeg_R=(0.28, 0.06, 0.10), UpperLeg_L=(0.02, -0.06, -0.10)),
            "run": _pose(Hips=(-0.02, 0.06, 0.0), Chest=(0.10, 0.08, 0.0), UpperArm_R=(0.50, -0.40, 0.34), UpperArm_L=(0.50, 0.40, -0.34), UpperLeg_R=(0.48, 0.06, 0.10), UpperLeg_L=(-0.08, -0.06, -0.10)),
            "dash": _pose(Hips=(-0.10, 0.04, 0.0), Chest=(0.20, 0.08, 0.0), UpperArm_R=(0.86, -0.06, 0.80), UpperArm_L=(0.24, 0.32, -0.24), UpperLeg_R=(0.16, 0.08, 0.12), UpperLeg_L=(0.30, -0.06, -0.10)),
            "charge": _pose(
                Hips=(-0.16, 0.0, 0.0), Spine=(-0.32, 0.0, 0.0), Chest=(-0.58, 0.0, 0.0),
                Head=(-0.20, 0.0, 0.0), UpperArm_R=(0.70, 0.16, 0.78), UpperArm_L=(0.70, -0.16, -0.78),
            ),
            "heavy_pre": _pose(Hips=(-0.10, 0.0, 0.0), Chest=(-0.16, 0.08, 0.0), UpperArm_R=(0.96, 0.08, 0.70), UpperArm_L=(0.24, 0.30, -0.24)),
            "heavy_contact": _pose(
                Hips=(-0.16, 0.0, 0.0), Spine=(0.14, 0.08, 0.0), Chest=(0.36, 0.12, 0.0),
                Head=(-0.08, 0.10, 0.0), UpperArm_R=(0.96, -0.04, 1.02), UpperArm_L=(0.26, 0.36, -0.28),
                UpperLeg_R=(0.12, 0.08, 0.14), UpperLeg_L=(0.16, -0.06, -0.12),
            ),
            "heavy_follow": _pose(Hips=(0.04, 0.0, 0.0), Chest=(0.22, 0.08, 0.0), UpperArm_R=(0.50, -0.20, 0.80), UpperArm_L=(0.28, 0.30, -0.22)),
            "hurt_pre": _pose(Hips=(0.02, 0.0, 0.0), Chest=(0.06, 0.0, 0.0), Head=(0.04, 0.0, 0.0)),
            "hurt_peak": _pose(
                Hips=(0.20, 0.0, 0.0), Spine=(0.32, 0.0, 0.0), Chest=(0.58, 0.0, 0.0),
                Head=(0.44, 0.0, 0.0), UpperArm_R=(-0.16, -0.66, 0.16), UpperArm_L=(-0.16, 0.66, -0.16),
                UpperLeg_R=(0.22, 0.08, 0.12), UpperLeg_L=(0.08, -0.08, -0.10),
            ),
            "launch": _pose(Hips=(0.32, 0.0, 0.0), Chest=(0.70, 0.0, 0.0), Head=(0.52, 0.0, 0.0), UpperArm_R=(-0.22, -0.70, 0.14), UpperArm_L=(-0.20, 0.70, -0.14)),
            "super": _pose(
                Hips=(-0.18, 0.0, 0.0), Chest=(0.28, 0.12, 0.0), Head=(-0.08, 0.10, 0.0),
                UpperArm_R=(1.24, -0.04, 0.26), UpperArm_L=(0.32, 0.42, -0.20),
                UpperLeg_R=(0.12, 0.08, 0.14), UpperLeg_L=(0.18, -0.06, -0.12),
            ),
            "clash_start": _pose(Hips=(-0.06, 0.0, 0.0), Chest=(-0.12, 0.0, 0.0), UpperArm_R=(0.42, 0.46, 0.58), UpperArm_L=(0.42, -0.46, -0.58)),
            "clash_lock": _pose(
                Hips=(-0.10, 0.0, 0.0), Spine=(-0.16, 0.0, 0.0), Chest=(-0.24, 0.0, 0.0),
                Head=(-0.08, 0.0, 0.0), UpperArm_R=(0.54, 0.56, 0.72), UpperArm_L=(0.54, -0.56, -0.72),
                UpperLeg_R=(0.22, 0.08, 0.18), UpperLeg_L=(0.22, -0.08, -0.18),
            ),
            "clash_push": _pose(Hips=(-0.14, 0.0, 0.0), Chest=(-0.30, 0.0, 0.0), UpperArm_R=(0.58, 0.60, 0.76), UpperArm_L=(0.58, -0.60, -0.76)),
            "clash_win": _pose(Hips=(-0.06, 0.0, 0.0), Chest=(-0.08, 0.08, 0.0), UpperArm_R=(0.68, 0.44, 0.66), UpperArm_L=(0.42, -0.48, -0.58)),
            "clash_lose": _pose(Hips=(0.14, 0.0, 0.0), Chest=(0.22, 0.0, 0.0), Head=(0.16, 0.0, 0.0), UpperArm_R=(0.34, 0.44, 0.52), UpperArm_L=(0.34, -0.44, -0.52)),
            "clash_break": _pose(Hips=(0.02, 0.0, 0.0), Chest=(0.08, 0.0, 0.0), UpperArm_R=(0.30, -0.22, 0.36), UpperArm_L=(0.30, 0.22, -0.36)),
        }
    if fid == "orion-vell":
        return {
            "idle": _pose(
                Hips=(0.00, 0.0, 0.0), Spine=(-0.12, 0.0, 0.0), Chest=(-0.22, 0.0, 0.0),
                Head=(-0.20, 0.0, 0.0), UpperArm_R=(0.18, -0.86, 0.10), UpperArm_L=(0.12, 0.64, -0.10),
                LowerArm_R=(0.12, -0.30, 0.08), Hand_R=(0.10, -0.16, 0.10),
            ),
            "walk": _pose(Hips=(0.02, 0.04, 0.0), Chest=(-0.14, 0.04, 0.0), UpperArm_R=(0.30, -0.72, 0.12), UpperArm_L=(0.24, 0.52, -0.12), UpperLeg_R=(0.24, 0.06, 0.10), UpperLeg_L=(0.04, -0.06, -0.10)),
            "run": _pose(Hips=(-0.02, 0.06, 0.0), Chest=(-0.10, 0.08, 0.0), UpperArm_R=(0.46, -0.80, 0.10), UpperArm_L=(0.36, 0.64, -0.10), UpperLeg_R=(0.46, 0.06, 0.10), UpperLeg_L=(-0.08, -0.06, -0.10)),
            "dash": _pose(Hips=(-0.08, 0.04, 0.0), Chest=(0.12, 0.10, 0.0), UpperArm_R=(0.80, -0.20, 0.70), UpperArm_L=(0.22, 0.46, -0.18), Head=(-0.12, 0.08, 0.0)),
            "charge": _pose(
                Hips=(0.28, 0.0, 0.0), Spine=(-0.44, 0.0, 0.0), Chest=(-0.86, 0.0, 0.0),
                Head=(-0.42, 0.0, 0.0), UpperArm_R=(0.66, 0.24, 0.78), UpperArm_L=(0.60, -0.20, -0.72),
            ),
            "heavy_pre": _pose(Hips=(0.08, 0.0, 0.0), Chest=(-0.20, 0.10, 0.0), UpperArm_R=(0.86, -0.08, 0.70), Head=(-0.16, 0.0, 0.0)),
            "heavy_contact": _pose(
                Hips=(0.12, 0.0, 0.0), Chest=(0.30, 0.16, 0.0), Head=(-0.16, 0.0, 0.0),
                UpperArm_R=(0.82, -0.12, 0.96), UpperArm_L=(0.22, 0.50, -0.24),
            ),
            "heavy_follow": _pose(Hips=(0.06, 0.0, 0.0), Chest=(0.16, 0.10, 0.0), UpperArm_R=(0.46, -0.40, 0.70), UpperArm_L=(0.24, 0.42, -0.18)),
            "hurt_pre": _pose(Hips=(0.04, 0.0, 0.0), Chest=(-0.08, 0.0, 0.0), Head=(-0.10, 0.0, 0.0)),
            "hurt_peak": _pose(
                Hips=(0.24, 0.0, 0.0), Spine=(0.36, 0.0, 0.0), Chest=(0.64, 0.0, 0.0),
                Head=(0.48, 0.0, 0.0), UpperArm_R=(-0.20, -0.72, 0.16), UpperArm_L=(-0.16, 0.74, -0.14),
                UpperLeg_R=(0.20, 0.08, 0.12), UpperLeg_L=(0.10, -0.08, -0.10),
            ),
            "launch": _pose(Hips=(0.36, 0.0, 0.0), Chest=(0.76, 0.0, 0.0), Head=(0.56, 0.0, 0.0), UpperArm_R=(-0.26, -0.76, 0.14), UpperArm_L=(-0.22, 0.78, -0.12)),
            "super": _pose(
                Hips=(0.22, 0.0, 0.0), Chest=(0.12, 0.0, 0.0), Head=(-0.28, 0.0, 0.0),
                UpperArm_R=(1.02, -0.42, 0.18), UpperArm_L=(0.96, 0.44, -0.16),
            ),
            "clash_start": _pose(Hips=(0.04, 0.0, 0.0), Chest=(-0.16, 0.0, 0.0), UpperArm_R=(0.40, 0.46, 0.54), UpperArm_L=(0.40, -0.46, -0.54)),
            "clash_lock": _pose(
                Hips=(0.06, 0.0, 0.0), Spine=(-0.20, 0.0, 0.0), Chest=(-0.30, 0.0, 0.0),
                Head=(-0.14, 0.0, 0.0), UpperArm_R=(0.52, 0.56, 0.68), UpperArm_L=(0.52, -0.56, -0.68),
                UpperLeg_R=(0.18, 0.08, 0.16), UpperLeg_L=(0.18, -0.08, -0.16),
            ),
            "clash_push": _pose(Hips=(0.04, 0.0, 0.0), Chest=(-0.36, 0.0, 0.0), UpperArm_R=(0.56, 0.60, 0.72), UpperArm_L=(0.56, -0.60, -0.72)),
            "clash_win": _pose(Hips=(0.06, 0.0, 0.0), Chest=(-0.12, 0.08, 0.0), UpperArm_R=(0.72, -0.20, 0.40), Head=(-0.16, 0.0, 0.0)),
            "clash_lose": _pose(Hips=(0.16, 0.0, 0.0), Chest=(0.24, 0.0, 0.0), Head=(0.18, 0.0, 0.0), UpperArm_R=(0.32, 0.44, 0.50), UpperArm_L=(0.32, -0.44, -0.50)),
            "clash_break": _pose(Hips=(0.04, 0.0, 0.0), Chest=(-0.08, 0.0, 0.0), UpperArm_R=(0.24, -0.50, 0.16), UpperArm_L=(0.20, 0.42, -0.14)),
        }
    # vesper-nyx
    return {
        "idle": _pose(
            Hips=(0.14, 0.34, 0.16), Spine=(-0.10, -0.18, 0.12), Chest=(-0.18, -0.36, 0.18),
            Head=(0.14, 0.40, -0.14), UpperArm_R=(0.38, -0.74, 0.30), UpperArm_L=(0.16, 0.50, -0.24),
            UpperLeg_R=(0.08, 0.16, 0.12), UpperLeg_L=(0.24, -0.12, -0.10),
        ),
        "walk": _pose(Hips=(0.12, 0.36, 0.16), Chest=(-0.14, -0.30, 0.16), Head=(0.12, 0.36, -0.12), UpperArm_R=(0.46, -0.80, 0.22), UpperArm_L=(0.20, 0.48, -0.20), UpperLeg_R=(0.30, 0.14, 0.10), UpperLeg_L=(0.04, -0.12, -0.08)),
        "run": _pose(Hips=(0.04, 0.42, 0.16), Chest=(-0.06, -0.24, 0.18), Head=(0.10, 0.38, -0.12), UpperArm_R=(0.66, -0.90, 0.16), UpperArm_L=(0.36, 0.62, -0.16), UpperLeg_R=(0.56, 0.12, 0.08), UpperLeg_L=(-0.14, -0.12, -0.08)),
        "dash": _pose(Hips=(-0.12, 0.46, 0.18), Chest=(0.20, -0.28, 0.22), Head=(0.08, 0.42, -0.14), UpperArm_R=(0.96, 0.10, 0.86), UpperArm_L=(0.14, 0.60, -0.22), UpperLeg_L=(0.50, -0.12, -0.10)),
        "charge": _pose(
            Hips=(-0.12, 0.36, 0.18), Spine=(-0.28, -0.16, 0.12), Chest=(-0.56, -0.34, 0.20),
            Head=(-0.12, 0.40, -0.14), UpperArm_R=(0.72, 0.24, 0.84), UpperArm_L=(0.62, -0.20, -0.76),
        ),
        "heavy_pre": _pose(Hips=(-0.12, 0.38, 0.16), Chest=(-0.24, -0.28, 0.18), Head=(0.08, 0.40, -0.12), UpperArm_R=(0.90, 0.16, 0.70)),
        "heavy_contact": _pose(
            Hips=(-0.18, 0.42, 0.18), Chest=(0.46, -0.34, 0.22), Head=(0.12, 0.46, -0.16),
            UpperArm_R=(0.94, 0.10, 1.06), UpperArm_L=(0.14, 0.64, -0.26),
            UpperLeg_R=(0.12, 0.16, 0.12), UpperLeg_L=(0.32, -0.12, -0.10),
        ),
        "heavy_follow": _pose(Hips=(0.08, 0.40, 0.16), Chest=(0.28, -0.28, 0.18), UpperArm_R=(0.40, -0.56, 0.80), UpperArm_L=(0.20, 0.52, -0.20)),
        "hurt_pre": _pose(Hips=(0.10, 0.24, 0.12), Chest=(-0.10, -0.22, 0.12), Head=(0.10, 0.28, -0.10)),
        "hurt_peak": _pose(
            Hips=(0.26, -0.30, 0.16), Spine=(0.34, -0.20, 0.12), Chest=(0.62, -0.42, 0.20),
            Head=(0.50, 0.28, -0.18), UpperArm_R=(-0.22, -0.78, 0.18), UpperArm_L=(-0.18, 0.80, -0.16),
            UpperLeg_R=(0.28, 0.12, 0.12), UpperLeg_L=(-0.12, -0.12, -0.10),
        ),
        "launch": _pose(Hips=(0.40, -0.24, 0.16), Chest=(0.74, -0.34, 0.20), Head=(0.56, 0.22, -0.16), UpperArm_R=(-0.28, -0.84, 0.16), UpperArm_L=(-0.22, 0.84, -0.14)),
        "super": _pose(
            Hips=(-0.20, 0.44, 0.20), Chest=(0.50, -0.36, 0.24), Head=(0.12, 0.48, -0.18),
            UpperArm_R=(1.16, 0.14, 0.26), UpperArm_L=(0.24, 0.82, -0.22),
            UpperLeg_R=(0.12, 0.16, 0.12), UpperLeg_L=(0.36, -0.12, -0.10),
        ),
        "clash_start": _pose(Hips=(-0.08, 0.26, 0.12), Chest=(-0.16, -0.20, 0.12), Head=(0.08, 0.28, -0.10), UpperArm_R=(0.42, 0.48, 0.56), UpperArm_L=(0.42, -0.48, -0.56)),
        "clash_lock": _pose(
            Hips=(-0.12, 0.30, 0.16), Spine=(-0.18, -0.14, 0.10), Chest=(-0.28, -0.28, 0.16),
            Head=(0.12, 0.34, -0.14), UpperArm_R=(0.54, 0.60, 0.72), UpperArm_L=(0.54, -0.60, -0.72),
            UpperLeg_R=(0.20, 0.14, 0.16), UpperLeg_L=(0.24, -0.12, -0.14),
        ),
        "clash_push": _pose(Hips=(-0.16, 0.32, 0.16), Chest=(-0.34, -0.24, 0.16), UpperArm_R=(0.58, 0.64, 0.76), UpperArm_L=(0.58, -0.64, -0.76)),
        "clash_win": _pose(Hips=(-0.08, 0.36, 0.16), Chest=(-0.08, -0.20, 0.18), Head=(0.14, 0.38, -0.12), UpperArm_R=(0.70, 0.40, 0.60)),
        "clash_lose": _pose(Hips=(0.18, 0.16, 0.12), Chest=(0.26, -0.30, 0.14), Head=(0.20, 0.30, -0.14), UpperArm_R=(0.32, 0.46, 0.50), UpperArm_L=(0.32, -0.46, -0.50)),
        "clash_break": _pose(Hips=(0.06, 0.28, 0.14), Chest=(0.10, -0.18, 0.14), UpperArm_R=(0.20, -0.46, 0.24), UpperArm_L=(0.16, 0.40, -0.20)),
    }


def pose_v7(fid: str, action: str):
    table = _identity(fid)
    if action in table:
        return table[action]
    if action == "personality_idle":
        return add(table["idle"], {"Head": _e(0.06, 0.08, 0.04), "Chest": _e(-0.04, 0.06, 0.02)})
    if action == "charged_idle":
        return table["charge"]
    return apply_goal(idle_v4(fid), fid, "idle")


def idle_v7(fid: str):
    return pose_v7(fid, "idle")


def charge_100_v7(fid: str):
    return pose_v7(fid, "charge")


def super_pose_v7(fid: str):
    return pose_v7(fid, "super")


def overlay_table(fid: str) -> dict:
    """action -> {frame: pose} overlays written onto generated clips."""
    return {
        "idle": {1: pose_v7(fid, "idle")},
        "personality_idle": {8: pose_v7(fid, "personality_idle")},
        "walk": {8: pose_v7(fid, "walk")},
        "run": {6: pose_v7(fid, "run")},
        "dash": {4: pose_v7(fid, "dash")},
        "charged_idle": {12: pose_v7(fid, "charge")},
        "charge_full": {12: pose_v7(fid, "charge")},
        "heavy": {
            4: pose_v7(fid, "heavy_pre"),
            11: pose_v7(fid, "heavy_contact"),
            16: pose_v7(fid, "heavy_follow"),
        },
        "hurt_heavy": {
            2: pose_v7(fid, "hurt_pre"),
            6: pose_v7(fid, "hurt_peak"),
            10: pose_v7(fid, "launch"),
        },
        "launch": {4: pose_v7(fid, "launch")},
        "launch_tumble": {4: pose_v7(fid, "launch")},
        "clash_lock": {
            2: pose_v7(fid, "clash_start"),
            8: pose_v7(fid, "clash_lose"),
            12: pose_v7(fid, "clash_lock"),
            16: pose_v7(fid, "clash_push"),
            20: pose_v7(fid, "clash_win"),
            24: pose_v7(fid, "clash_break"),
        },
        "signature_lane_finisher": {16: pose_v7(fid, "super")},
        "aura_signature": {12: pose_v7(fid, "super")},
        "aura_burst_super_pose": {16: pose_v7(fid, "super")},
    }


def pose_delta_ok(a: dict, b: dict, bones: tuple[str, ...], min_mag: float = 0.18) -> bool:
    hits = 0
    for bone in bones:
        ax, ay, az = a.get(bone, (0.0, 0.0, 0.0))
        bx, by, bz = b.get(bone, (0.0, 0.0, 0.0))
        mag = abs(ax - bx) + abs(ay - by) + abs(az - bz)
        if mag >= min_mag:
            hits += 1
    return hits >= max(3, len(bones) - 1)
