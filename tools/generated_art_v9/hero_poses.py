"""v9 acting overlays. Heroic amplitude, fighter-specific silhouettes. Not human-authored."""
from __future__ import annotations

from generated_art_v7.hero_poses import overlay_table as overlay_v7
from generated_art_v7.hero_poses import pose_delta_ok
from generated_production_art.pose_library import _e, add, blank


def _pose(**kwargs):
    out = blank()
    for key, val in kwargs.items():
        if key.startswith("loc:"):
            out[key] = val if isinstance(val, tuple) else tuple(val)
        else:
            out[key] = _e(*val) if not isinstance(val, tuple) else val
    return out


def _boost(base: dict, extra: dict) -> dict:
    out = dict(base)
    out.update(extra)
    return out


def _identity(fid: str) -> dict:
    if fid == "ember-vale":
        return {
            "idle": _pose(
                Hips=(0.12, 0.22, 0.10), Spine=(-0.24, 0.18, 0.10), Chest=(-0.42, 0.32, 0.16),
                Head=(0.14, 0.22, 0.08), UpperArm_R=(0.78, -0.88, 0.58), UpperArm_L=(0.22, 0.56, -0.36),
                LowerArm_R=(0.36, -0.18, 0.14), LowerArm_L=(0.16, 0.14, -0.10),
                UpperLeg_R=(0.20, 0.12, 0.24), UpperLeg_L=(0.08, -0.08, -0.08),
                LowerLeg_R=(0.12, 0.0, 0.06), Foot_R=(-0.08, 0.06, 0.04),
            ),
            "walk": _pose(
                Hips=(0.10, 0.36, 0.14), Chest=(-0.42, 0.44, 0.20), Head=(0.16, 0.24, 0.08),
                UpperArm_R=(0.86, -1.28, 0.28), UpperArm_L=(0.92, 1.02, -0.24),
                UpperLeg_R=(0.72, 0.12, 0.16), UpperLeg_L=(-0.28, -0.12, -0.12),
                LowerLeg_R=(0.22, 0.0, 0.06),
            ),
            "run": _pose(
                Hips=(-0.12, 0.42, 0.16), Chest=(-0.28, 0.58, 0.24), Head=(0.14, 0.32, 0.10),
                UpperArm_R=(1.06, -1.36, 0.24), UpperArm_L=(1.10, 1.18, -0.22),
                UpperLeg_R=(0.96, 0.14, 0.16), UpperLeg_L=(-0.42, -0.14, -0.14),
            ),
            "dash": _pose(
                Hips=(-0.28, 0.52, 0.18), Chest=(0.18, 0.68, 0.26), Head=(-0.12, 0.40, 0.14),
                UpperArm_R=(1.28, -0.28, 1.10), UpperArm_L=(0.18, 0.92, -0.56),
                UpperLeg_R=(0.22, 0.16, 0.22), UpperLeg_L=(0.78, -0.14, -0.16),
            ),
            "charge": _pose(
                Hips=(-0.48, 0.28, 0.08), Spine=(-0.72, 0.26, 0.12), Chest=(-1.18, 0.42, 0.24),
                Head=(-0.52, 0.28, 0.10), UpperArm_R=(1.06, 0.42, 1.18), UpperArm_L=(1.02, -0.36, -1.12),
                UpperLeg_R=(0.36, 0.18, 0.36), UpperLeg_L=(0.42, -0.16, -0.28),
                **{"loc:Hips": (0.00, 0.04, -0.06)},
            ),
            "heavy_pre": _pose(
                Hips=(-0.32, 0.38, 0.14), Chest=(-0.92, 0.58, 0.22), Head=(-0.34, 0.32, 0.12),
                UpperArm_R=(1.42, 0.48, 0.92), UpperArm_L=(0.16, 0.72, -0.48),
                UpperLeg_R=(0.22, 0.16, 0.28), UpperLeg_L=(0.42, -0.12, -0.18),
                **{"loc:Hips": (-0.04, 0.06, -0.04)},
            ),
            "heavy_precontact": _pose(
                Hips=(-0.36, 0.46, 0.16), Chest=(-0.28, 0.72, 0.26), Head=(-0.18, 0.36, 0.14),
                UpperArm_R=(1.28, 0.10, 1.18), UpperArm_L=(0.20, 0.80, -0.56),
                UpperLeg_R=(0.18, 0.18, 0.30), UpperLeg_L=(0.48, -0.14, -0.20),
            ),
            "heavy_contact": _pose(
                Hips=(-0.28, 0.38, 0.12), Spine=(0.22, 0.28, 0.10), Chest=(0.62, 0.58, 0.20),
                Head=(-0.16, 0.26, 0.10), UpperArm_R=(1.02, -0.12, 1.08), UpperArm_L=(0.14, 0.68, -0.46),
                LowerArm_R=(0.12, 0.08, 0.20), UpperLeg_R=(0.10, 0.14, 0.20), UpperLeg_L=(0.36, -0.12, -0.14),
            ),
            "heavy_follow": _pose(
                Hips=(0.16, 0.58, 0.20), Chest=(1.08, 0.66, 0.24), Head=(0.22, 0.30, 0.14),
                UpperArm_R=(0.52, -1.02, 1.08), UpperArm_L=(0.36, 0.74, -0.40),
                UpperLeg_R=(0.28, 0.14, 0.22), UpperLeg_L=(0.22, -0.14, -0.16),
            ),
            "hurt_pre": _pose(
                Hips=(0.10, 0.12, 0.06), Chest=(-0.16, 0.18, 0.10), Head=(0.12, 0.14, 0.06),
                UpperArm_R=(0.52, -0.52, 0.46), UpperArm_L=(0.48, 0.50, -0.42),
            ),
            "hurt_peak": _pose(
                Hips=(0.36, -0.28, 0.16), Spine=(0.46, -0.22, 0.12), Chest=(0.82, -0.42, 0.18),
                Head=(0.68, -0.36, 0.16), UpperArm_R=(-0.28, -0.86, 0.24), UpperArm_L=(-0.22, 0.82, -0.22),
                UpperLeg_R=(0.40, 0.14, 0.22), UpperLeg_L=(-0.18, -0.16, -0.12),
                LowerLeg_R=(0.20, 0.0, 0.08), Foot_R=(-0.10, 0.08, 0.06),
            ),
            "launch": _pose(
                Hips=(0.72, -0.28, 0.24), Chest=(1.28, -0.42, 0.26), Head=(0.96, -0.36, 0.22),
                UpperArm_R=(-0.42, -1.16, 0.28), UpperArm_L=(-0.34, 1.10, -0.24),
                UpperLeg_R=(0.70, 0.14, 0.22), UpperLeg_L=(0.16, -0.18, -0.14),
                **{"loc:Hips": (0.10, -0.02, 0.08)},
            ),
            "super": _pose(
                Hips=(-0.58, 0.48, 0.20), Spine=(0.36, 0.44, 0.16), Chest=(1.22, 0.82, 0.28),
                Head=(-0.28, 0.40, 0.16), UpperArm_R=(1.62, -0.22, 0.54), UpperArm_L=(0.18, 1.12, -0.36),
                UpperLeg_R=(0.16, 0.18, 0.26), UpperLeg_L=(0.52, -0.16, -0.18),
                **{"loc:Hips": (0.00, 0.08, -0.04)},
            ),
            "clash_start": _pose(Hips=(-0.16, 0.20, 0.04), Chest=(-0.32, 0.26, 0.04), UpperArm_R=(0.64, 0.68, 0.72), UpperArm_L=(0.64, -0.68, -0.72)),
            "clash_lock": _pose(
                Hips=(-0.28, 0.22, 0.04), Spine=(-0.48, 0.22, 0.04), Chest=(-0.68, 0.38, 0.06),
                Head=(-0.24, 0.26, 0.04), UpperArm_R=(0.86, 0.92, 1.02), UpperArm_L=(0.86, -0.92, -1.02),
                UpperLeg_R=(0.46, 0.18, 0.36), UpperLeg_L=(0.46, -0.18, -0.36),
                **{"loc:Hips": (0.04, 0.06, -0.02)},
            ),
            "clash_push": _pose(Hips=(-0.36, 0.24, 0.04), Chest=(-0.78, 0.42, 0.06), UpperArm_R=(0.94, 0.98, 1.08), UpperArm_L=(0.94, -0.98, -1.08), Head=(-0.28, 0.28, 0.04)),
            "clash_win": _pose(Hips=(-0.18, 0.30, 0.08), Chest=(-0.12, 0.52, 0.14), UpperArm_R=(1.02, 0.68, 0.92), UpperArm_L=(0.62, -0.78, -0.82), Head=(0.14, 0.24, 0.06), **{"loc:Hips": (0.06, 0.08, 0.00)}),
            "clash_lose": _pose(Hips=(0.32, -0.16, 0.04), Chest=(0.48, -0.28, 0.04), Head=(0.38, -0.22, 0.04), UpperArm_R=(0.48, 0.62, 0.68), UpperArm_L=(0.48, -0.62, -0.68), **{"loc:Hips": (-0.06, -0.02, -0.04)}),
            "clash_break": _pose(Hips=(0.10, 0.28, 0.10), Chest=(0.24, 0.34, 0.14), UpperArm_R=(0.28, -0.52, 0.40), UpperArm_L=(0.28, 0.52, -0.40)),
        }
    if fid == "rook-ironside":
        return {
            "idle": _pose(
                Hips=(0.18, 0.0, 0.0), Spine=(0.16, 0.0, 0.0), Chest=(0.28, 0.0, 0.0),
                Head=(-0.16, 0.0, 0.0), UpperArm_R=(0.78, -0.52, 0.86), UpperArm_L=(0.78, 0.52, -0.86),
                LowerArm_R=(0.72, -0.18, 0.26), LowerArm_L=(0.72, 0.18, -0.26),
                UpperLeg_R=(0.42, 0.20, 0.44), UpperLeg_L=(0.42, -0.20, -0.44),
                LowerLeg_R=(0.28, 0.0, 0.10), LowerLeg_L=(0.28, 0.0, -0.10),
                **{"loc:Hips": (0.00, 0.00, -0.10)},
            ),
            "walk": _pose(Hips=(0.08, 0.10, 0.0), Chest=(0.20, 0.12, 0.0), UpperArm_R=(0.58, -0.62, 0.52), UpperArm_L=(0.58, 0.62, -0.52), UpperLeg_R=(0.52, 0.16, 0.24), UpperLeg_L=(0.08, -0.16, -0.24)),
            "run": _pose(Hips=(-0.08, 0.16, 0.0), Chest=(0.26, 0.20, 0.0), UpperArm_R=(0.76, -0.78, 0.42), UpperArm_L=(0.76, 0.78, -0.42), UpperLeg_R=(0.68, 0.16, 0.20), UpperLeg_L=(-0.16, -0.16, -0.20)),
            "dash": _pose(Hips=(-0.22, 0.14, 0.0), Chest=(0.44, 0.18, 0.0), UpperArm_R=(1.12, -0.22, 0.92), UpperArm_L=(0.42, 0.56, -0.38), UpperLeg_R=(0.30, 0.18, 0.28), UpperLeg_L=(0.50, -0.14, -0.22)),
            "charge": _pose(
                Hips=(-0.38, 0.0, 0.0), Spine=(-0.52, 0.0, 0.0), Chest=(-0.86, 0.0, 0.0),
                Head=(-0.28, 0.0, 0.0), UpperArm_R=(0.98, 0.32, 1.02), UpperArm_L=(0.98, -0.32, -1.02),
                UpperLeg_R=(0.40, 0.20, 0.40), UpperLeg_L=(0.40, -0.20, -0.40),
                **{"loc:Hips": (0.00, 0.00, -0.12)},
            ),
            "heavy_pre": _pose(Hips=(-0.28, 0.12, 0.0), Chest=(-0.48, 0.18, 0.0), UpperArm_R=(1.48, 0.22, 0.78), UpperArm_L=(0.32, 0.48, -0.32), **{"loc:Hips": (0.00, 0.02, -0.10)}),
            "heavy_precontact": _pose(Hips=(-0.34, 0.18, 0.0), Chest=(0.18, 0.28, 0.0), UpperArm_R=(1.32, 0.04, 1.12), UpperArm_L=(0.34, 0.56, -0.38)),
            "heavy_contact": _pose(
                Hips=(-0.38, 0.22, 0.0), Chest=(0.78, 0.36, 0.0), Head=(-0.20, 0.16, 0.0),
                UpperArm_R=(1.38, -0.12, 1.22), UpperArm_L=(0.34, 0.58, -0.40),
                UpperLeg_R=(0.26, 0.18, 0.32), UpperLeg_L=(0.32, -0.16, -0.26),
                **{"loc:Hips": (0.06, 0.04, -0.08)},
            ),
            "heavy_follow": _pose(Hips=(0.12, 0.16, 0.0), Chest=(0.56, 0.22, 0.0), UpperArm_R=(0.66, -0.48, 0.92), UpperArm_L=(0.38, 0.48, -0.32)),
            "hurt_pre": _pose(Hips=(0.08, 0.0, 0.0), Chest=(0.14, 0.0, 0.0), UpperArm_R=(0.48, -0.38, 0.52), UpperArm_L=(0.48, 0.38, -0.52)),
            "hurt_peak": _pose(
                Hips=(0.42, 0.0, 0.0), Spine=(0.52, 0.0, 0.0), Chest=(0.88, 0.0, 0.0),
                Head=(0.64, 0.0, 0.0), UpperArm_R=(-0.22, -0.86, 0.26), UpperArm_L=(-0.22, 0.86, -0.26),
                UpperLeg_R=(0.46, 0.16, 0.26), UpperLeg_L=(0.18, -0.16, -0.18),
                **{"loc:Hips": (0.08, 0.00, -0.08)},
            ),
            "launch": _pose(Hips=(0.56, 0.0, 0.0), Chest=(0.98, 0.0, 0.0), Head=(0.68, 0.0, 0.0), UpperArm_R=(-0.30, -0.92, 0.22), UpperArm_L=(-0.26, 0.92, -0.22)),
            "super": _pose(
                Hips=(-0.36, 0.0, 0.0), Chest=(0.72, 0.28, 0.0), Head=(-0.20, 0.16, 0.0),
                UpperArm_R=(1.62, -0.08, 0.36), UpperArm_L=(0.32, 0.56, -0.26),
                UpperLeg_R=(0.28, 0.18, 0.32), UpperLeg_L=(0.32, -0.16, -0.26),
                **{"loc:Hips": (0.00, 0.00, -0.08)},
            ),
            "clash_start": _pose(Hips=(-0.16, 0.0, 0.0), Chest=(-0.28, 0.0, 0.0), UpperArm_R=(0.62, 0.66, 0.74), UpperArm_L=(0.62, -0.66, -0.74)),
            "clash_lock": _pose(
                Hips=(-0.36, 0.0, 0.0), Spine=(-0.52, 0.0, 0.0), Chest=(-0.82, 0.0, 0.0),
                Head=(-0.32, 0.0, 0.0), UpperArm_R=(1.08, 1.02, 1.16), UpperArm_L=(1.08, -1.02, -1.16),
                UpperLeg_R=(0.52, 0.22, 0.42), UpperLeg_L=(0.52, -0.22, -0.42),
            ),
            "clash_push": _pose(Hips=(-0.38, 0.0, 0.0), Chest=(-0.80, 0.0, 0.0), UpperArm_R=(1.02, 1.00, 1.14), UpperArm_L=(1.02, -1.00, -1.14)),
            "clash_win": _pose(Hips=(-0.16, 0.0, 0.0), Chest=(-0.10, 0.18, 0.0), UpperArm_R=(1.08, 0.62, 0.86), UpperArm_L=(0.56, -0.70, -0.78), **{"loc:Hips": (0.06, 0.00, -0.06)}),
            "clash_lose": _pose(Hips=(0.34, 0.0, 0.0), Chest=(0.52, 0.0, 0.0), Head=(0.36, 0.0, 0.0), **{"loc:Hips": (-0.06, 0.00, -0.10)}),
            "clash_break": _pose(Hips=(0.10, 0.10, 0.0), Chest=(0.20, 0.12, 0.0), UpperArm_R=(0.32, -0.42, 0.36), UpperArm_L=(0.32, 0.42, -0.36)),
        }
    if fid == "juno-spark":
        return {
            "idle": _pose(
                Hips=(-0.06, 0.28, 0.08), Chest=(-0.12, 0.40, 0.10), Head=(0.10, 0.18, 0.06),
                UpperArm_R=(0.32, -0.48, 0.26), UpperArm_L=(0.28, 0.44, -0.24),
                LowerArm_R=(0.16, -0.10, 0.08), UpperLeg_R=(0.10, 0.06, 0.08),
                UpperLeg_L=(0.26, -0.08, -0.06), LowerLeg_L=(-0.16, 0.0, 0.0), Foot_L=(0.20, 0.0, 0.0),
            ),
            "walk": _pose(Hips=(0.04, 0.48, 0.12), Chest=(-0.12, 0.70, 0.16), UpperArm_R=(0.72, -1.18, 0.18), UpperArm_L=(0.78, 1.08, -0.16), UpperLeg_R=(0.86, 0.08, 0.10), UpperLeg_L=(-0.32, -0.08, -0.08)),
            "run": _pose(Hips=(-0.10, 0.56, 0.14), Chest=(-0.08, 0.82, 0.18), UpperArm_R=(1.02, -1.32, 0.16), UpperArm_L=(1.06, 1.22, -0.14), UpperLeg_R=(1.08, 0.10, 0.10), UpperLeg_L=(-0.48, -0.10, -0.10)),
            "dash": _pose(Hips=(-0.22, 0.62, 0.16), Chest=(0.16, 0.88, 0.20), UpperArm_R=(1.22, -0.18, 0.92), UpperArm_L=(0.16, 0.86, -0.42), UpperLeg_L=(0.86, -0.12, -0.12)),
            "charge": _pose(
                Hips=(-0.22, 0.52, 0.10), Chest=(-0.68, 0.78, 0.18), Head=(-0.28, 0.36, 0.10),
                UpperArm_R=(0.72, 0.38, 0.86), UpperArm_L=(0.18, 0.72, -0.36),
                UpperLeg_L=(0.48, -0.12, -0.10), Foot_L=(0.32, 0.0, 0.0),
                **{"loc:Hips": (0.00, 0.06, 0.02)},
            ),
            "heavy_pre": _pose(Hips=(-0.24, 0.48, 0.12), Chest=(-0.72, 0.82, 0.18), UpperArm_R=(1.36, 0.42, 0.64), UpperArm_L=(0.18, 0.58, -0.32)),
            "heavy_precontact": _pose(Hips=(-0.18, 0.56, 0.14), Chest=(0.22, 0.92, 0.20), UpperArm_R=(1.18, 0.08, 1.08), UpperArm_L=(0.20, 0.68, -0.40)),
            "heavy_contact": _pose(
                Hips=(-0.28, 0.62, 0.16), Chest=(0.86, 1.02, 0.22), Head=(-0.16, 0.42, 0.12),
                UpperArm_R=(1.28, -0.10, 1.28), UpperArm_L=(0.16, 0.78, -0.48),
                UpperLeg_R=(0.18, 0.10, 0.16), UpperLeg_L=(0.46, -0.12, -0.12),
            ),
            "heavy_follow": _pose(Hips=(0.12, 0.58, 0.14), Chest=(1.02, 0.72, 0.18), UpperArm_R=(0.42, -0.86, 0.92), UpperArm_L=(0.28, 0.62, -0.28)),
            "hurt_pre": _pose(Hips=(0.08, 0.16, 0.06), Chest=(-0.10, 0.22, 0.08), Head=(0.10, 0.14, 0.06)),
            "hurt_peak": _pose(
                Hips=(0.48, -0.52, 0.22), Spine=(0.62, -0.42, 0.16), Chest=(1.12, -0.78, 0.26),
                Head=(0.92, -0.64, 0.26), UpperArm_R=(-0.52, -1.28, 0.32), UpperArm_L=(-0.46, 1.22, -0.28),
                UpperLeg_R=(0.48, 0.14, 0.22), **{"loc:Hips": (0.08, -0.04, 0.02)},
            ),
            "launch": _pose(Hips=(0.68, -0.32, 0.20), Chest=(1.18, -0.46, 0.22), Head=(0.88, -0.38, 0.20), UpperArm_R=(-0.40, -1.18, 0.24), UpperArm_L=(-0.34, 1.12, -0.22)),
            "super": _pose(
                Hips=(-0.42, 0.92, 0.18), Chest=(0.42, 1.38, 0.22), Head=(-0.12, 0.48, 0.14),
                UpperArm_R=(1.68, 0.28, 0.36), UpperArm_L=(0.22, 0.86, -0.28),
                UpperLeg_L=(0.62, -0.16, -0.12), **{"loc:Hips": (0.00, 0.08, 0.04)},
            ),
            "clash_start": _pose(Hips=(-0.12, 0.24, 0.06), Chest=(-0.24, 0.32, 0.08), UpperArm_R=(0.58, 0.62, 0.68), UpperArm_L=(0.58, -0.62, -0.68)),
            "clash_lock": _pose(
                Hips=(-0.24, 0.28, 0.08), Chest=(-0.56, 0.46, 0.10), Head=(-0.18, 0.28, 0.08),
                UpperArm_R=(0.82, 0.86, 0.94), UpperArm_L=(0.82, -0.86, -0.94),
                UpperLeg_R=(0.38, 0.14, 0.28), UpperLeg_L=(0.38, -0.14, -0.28),
            ),
            "clash_push": _pose(Hips=(-0.32, 0.30, 0.08), Chest=(-0.68, 0.50, 0.10), UpperArm_R=(0.90, 0.92, 1.00), UpperArm_L=(0.90, -0.92, -1.00)),
            "clash_win": _pose(Hips=(-0.14, 0.36, 0.10), Chest=(-0.08, 0.62, 0.14), UpperArm_R=(1.02, 0.58, 0.78), **{"loc:Hips": (0.06, 0.06, 0.02)}),
            "clash_lose": _pose(Hips=(0.28, -0.18, 0.06), Chest=(0.42, -0.28, 0.06), Head=(0.32, -0.22, 0.06), **{"loc:Hips": (-0.06, -0.02, 0.00)}),
            "clash_break": _pose(Hips=(0.08, 0.28, 0.08), Chest=(0.16, 0.32, 0.10), UpperArm_R=(0.22, -0.42, 0.28), UpperArm_L=(0.22, 0.42, -0.28)),
        }
    if fid == "kaia-windrow":
        return {
            "idle": _pose(
                Hips=(-0.12, 0.22, 0.18), Chest=(-0.08, 0.38, 0.42), Head=(0.10, 0.24, 0.16),
                UpperArm_L=(0.92, 1.08, -0.42), UpperArm_R=(0.18, -0.42, 0.28),
                UpperLeg_L=(0.72, -0.22, -0.16), UpperLeg_R=(0.08, 0.12, 0.14),
                **{"loc:Hips": (0.02, 0.04, 0.02)},
            ),
            "walk": _pose(Hips=(-0.06, 0.28, 0.20), Chest=(-0.04, 0.44, 0.46), UpperArm_L=(1.02, 1.18, -0.36), UpperLeg_L=(0.88, -0.18, -0.14), UpperLeg_R=(-0.18, 0.12, 0.12)),
            "run": _pose(Hips=(-0.14, 0.36, 0.22), Chest=(0.06, 0.54, 0.50), UpperArm_L=(1.16, 1.28, -0.32), UpperLeg_L=(1.08, -0.16, -0.12), UpperLeg_R=(-0.32, 0.12, 0.12)),
            "dash": _pose(Hips=(-0.22, 0.42, 0.24), Chest=(0.18, 0.62, 0.54), UpperArm_L=(1.28, 0.86, -0.28), UpperLeg_L=(1.18, -0.18, -0.14)),
            "charge": _pose(
                Hips=(-0.28, 0.32, 0.26), Chest=(-0.36, 0.58, 0.62), Head=(-0.18, 0.32, 0.22),
                UpperArm_L=(1.18, 1.22, -0.38), UpperArm_R=(0.42, -0.58, 0.36),
                UpperLeg_L=(0.86, -0.24, -0.18), **{"loc:Hips": (0.00, 0.06, 0.00)},
            ),
            "heavy_pre": _pose(Hips=(-0.22, 0.28, 0.24), Chest=(-0.18, 0.52, 0.58), UpperArm_L=(1.32, 0.72, -0.32), UpperLeg_L=(1.18, -0.24, -0.16)),
            "heavy_precontact": _pose(Hips=(-0.18, 0.34, 0.28), Chest=(0.22, 0.58, 0.52), UpperArm_L=(1.18, 0.62, -0.28), UpperLeg_L=(1.28, -0.20, -0.14)),
            "heavy_contact": _pose(
                Hips=(-0.36, 0.38, 0.32), Chest=(0.48, 0.66, 0.52), Head=(0.12, 0.36, 0.24),
                UpperArm_L=(1.18, 0.68, -0.32), UpperLeg_L=(1.42, -0.26, -0.16),
                **{"loc:Hips": (0.04, 0.08, 0.02)},
            ),
            "heavy_follow": _pose(Hips=(0.10, 0.36, 0.26), Chest=(0.62, 0.48, 0.42), UpperArm_L=(0.72, 0.86, -0.28), UpperLeg_L=(0.92, -0.18, -0.12)),
            "hurt_pre": _pose(Hips=(0.08, 0.10, 0.10), Chest=(0.12, 0.16, 0.18), Head=(0.10, 0.12, 0.10)),
            "hurt_peak": _pose(
                Hips=(0.48, 0.32, 0.30), Spine=(0.58, 0.28, 0.24), Chest=(1.02, 0.48, 0.52),
                Head=(0.78, 0.42, 0.30), UpperArm_L=(-0.32, 1.18, -0.28), UpperLeg_L=(-0.32, -0.28, -0.20),
                **{"loc:Hips": (0.08, 0.04, 0.00)},
            ),
            "launch": _pose(Hips=(0.62, 0.22, 0.28), Chest=(1.16, 0.36, 0.42), Head=(0.82, 0.30, 0.26), UpperArm_L=(-0.28, 1.08, -0.24)),
            "super": _pose(
                Hips=(-0.36, 0.38, 0.36), Chest=(-0.16, 0.72, 0.74), Head=(-0.10, 0.36, 0.28),
                UpperArm_L=(1.52, 0.58, -0.28), UpperLeg_L=(1.08, -0.24, -0.16),
                **{"loc:Hips": (0.00, 0.08, 0.02)},
            ),
            "clash_start": _pose(Hips=(-0.12, 0.16, 0.12), Chest=(-0.18, 0.26, 0.22), UpperArm_L=(0.68, 0.72, -0.42), UpperArm_R=(0.42, -0.48, 0.36)),
            "clash_lock": _pose(
                Hips=(-0.24, 0.20, 0.16), Chest=(-0.42, 0.36, 0.32), Head=(-0.16, 0.24, 0.16),
                UpperArm_L=(0.86, 0.92, -0.48), UpperArm_R=(0.62, -0.68, 0.52),
                UpperLeg_L=(0.52, -0.18, -0.22), UpperLeg_R=(0.36, 0.16, 0.24),
            ),
            "clash_push": _pose(Hips=(-0.30, 0.22, 0.16), Chest=(-0.52, 0.40, 0.34), UpperArm_L=(0.94, 0.98, -0.50)),
            "clash_win": _pose(Hips=(-0.14, 0.28, 0.20), Chest=(-0.08, 0.48, 0.40), UpperArm_L=(1.08, 0.72, -0.36), **{"loc:Hips": (0.06, 0.06, 0.02)}),
            "clash_lose": _pose(Hips=(0.30, -0.16, 0.12), Chest=(0.46, -0.22, 0.16), Head=(0.32, -0.18, 0.12), **{"loc:Hips": (-0.06, -0.02, 0.00)}),
            "clash_break": _pose(Hips=(0.08, 0.20, 0.14), Chest=(0.16, 0.26, 0.20), UpperArm_L=(0.32, 0.48, -0.24)),
        }
    if fid == "nix-calder":
        return {
            "idle": _pose(
                Hips=(0.0, 0.0, 0.0), Spine=(0.04, 0.0, 0.0), Chest=(0.08, 0.06, 0.0),
                Head=(-0.04, 0.08, 0.0), UpperArm_R=(0.62, -0.58, 0.68), UpperArm_L=(0.58, 0.54, -0.64),
                LowerArm_R=(0.42, -0.12, 0.18), LowerArm_L=(0.42, 0.12, -0.18),
                UpperLeg_R=(0.16, 0.10, 0.18), UpperLeg_L=(0.16, -0.10, -0.18),
            ),
            "walk": _pose(Hips=(0.02, 0.08, 0.0), Chest=(0.08, 0.10, 0.0), UpperArm_R=(0.48, -0.72, 0.36), UpperArm_L=(0.48, 0.72, -0.36), UpperLeg_R=(0.46, 0.10, 0.14), UpperLeg_L=(0.02, -0.10, -0.14)),
            "run": _pose(Hips=(-0.04, 0.12, 0.0), Chest=(0.12, 0.16, 0.0), UpperArm_R=(0.68, -0.86, 0.30), UpperArm_L=(0.68, 0.86, -0.30), UpperLeg_R=(0.64, 0.10, 0.12), UpperLeg_L=(-0.16, -0.10, -0.12)),
            "dash": _pose(Hips=(-0.16, 0.10, 0.0), Chest=(0.28, 0.16, 0.0), UpperArm_R=(0.96, -0.18, 0.82), UpperArm_L=(0.28, 0.48, -0.32), UpperLeg_L=(0.42, -0.12, -0.16)),
            "charge": _pose(
                Hips=(-0.18, 0.0, 0.0), Spine=(-0.28, 0.0, 0.0), Chest=(-0.52, 0.10, 0.0),
                Head=(-0.22, 0.12, 0.0), UpperArm_R=(0.86, 0.18, 0.92), UpperArm_L=(0.82, -0.16, -0.88),
                UpperLeg_R=(0.22, 0.12, 0.22), UpperLeg_L=(0.22, -0.12, -0.22),
            ),
            "heavy_pre": _pose(Hips=(-0.16, 0.08, 0.0), Chest=(-0.36, 0.14, 0.0), UpperArm_R=(1.22, 0.22, 0.72), UpperArm_L=(0.28, 0.42, -0.28)),
            "heavy_precontact": _pose(Hips=(-0.20, 0.12, 0.0), Chest=(0.12, 0.20, 0.0), UpperArm_R=(1.12, 0.04, 1.02), UpperArm_L=(0.30, 0.48, -0.32)),
            "heavy_contact": _pose(
                Hips=(-0.24, 0.16, 0.0), Chest=(0.62, 0.24, 0.0), Head=(-0.08, 0.12, 0.0),
                UpperArm_R=(1.18, -0.08, 1.16), UpperArm_L=(0.32, 0.52, -0.36),
                UpperLeg_R=(0.18, 0.12, 0.20), UpperLeg_L=(0.24, -0.12, -0.18),
            ),
            "heavy_follow": _pose(Hips=(0.08, 0.12, 0.0), Chest=(0.42, 0.16, 0.0), UpperArm_R=(0.48, -0.42, 0.78), UpperArm_L=(0.30, 0.40, -0.26)),
            "hurt_pre": _pose(Hips=(0.06, 0.0, 0.0), Chest=(0.10, 0.0, 0.0), UpperArm_R=(0.42, -0.36, 0.44), UpperArm_L=(0.42, 0.36, -0.44)),
            "hurt_peak": _pose(
                Hips=(0.38, 0.0, 0.0), Spine=(0.56, 0.0, 0.0), Chest=(0.96, 0.0, 0.0),
                Head=(0.78, 0.0, 0.0), UpperArm_R=(-0.32, -0.98, 0.24), UpperArm_L=(-0.32, 0.98, -0.24),
                UpperLeg_R=(0.36, 0.12, 0.20), **{"loc:Hips": (0.06, 0.00, -0.02)},
            ),
            "launch": _pose(Hips=(0.52, 0.0, 0.0), Chest=(1.06, 0.0, 0.0), Head=(0.78, 0.0, 0.0), UpperArm_R=(-0.36, -1.06, 0.20), UpperArm_L=(-0.32, 1.06, -0.20)),
            "super": _pose(
                Hips=(-0.18, 0.0, 0.0), Chest=(0.28, 0.14, 0.0), Head=(-0.08, 0.12, 0.0),
                UpperArm_R=(1.18, 0.32, 0.92), UpperArm_L=(1.18, -0.32, -0.92),
            ),
            "clash_start": _pose(Hips=(-0.10, 0.0, 0.0), Chest=(-0.20, 0.0, 0.0), UpperArm_R=(0.54, 0.58, 0.66), UpperArm_L=(0.54, -0.58, -0.66)),
            "clash_lock": _pose(
                Hips=(-0.22, 0.0, 0.0), Spine=(-0.34, 0.0, 0.0), Chest=(-0.52, 0.0, 0.0),
                Head=(-0.18, 0.0, 0.0), UpperArm_R=(0.78, 0.82, 0.92), UpperArm_L=(0.78, -0.82, -0.92),
                UpperLeg_R=(0.34, 0.14, 0.28), UpperLeg_L=(0.34, -0.14, -0.28),
            ),
            "clash_push": _pose(Hips=(-0.28, 0.0, 0.0), Chest=(-0.62, 0.0, 0.0), UpperArm_R=(0.86, 0.88, 0.98), UpperArm_L=(0.86, -0.88, -0.98)),
            "clash_win": _pose(Hips=(-0.12, 0.0, 0.0), Chest=(-0.08, 0.16, 0.0), UpperArm_R=(0.92, 0.58, 0.78), **{"loc:Hips": (0.05, 0.00, 0.00)}),
            "clash_lose": _pose(Hips=(0.28, 0.0, 0.0), Chest=(0.42, 0.0, 0.0), Head=(0.30, 0.0, 0.0), **{"loc:Hips": (-0.05, 0.00, -0.02)}),
            "clash_break": _pose(Hips=(0.06, 0.08, 0.0), Chest=(0.12, 0.10, 0.0), UpperArm_R=(0.22, -0.36, 0.28), UpperArm_L=(0.22, 0.36, -0.28)),
        }
    if fid == "orion-vell":
        return {
            "idle": _pose(
                Hips=(-0.10, 0.0, 0.0), Chest=(-0.18, 0.12, 0.0), Head=(-0.12, 0.08, 0.0),
                UpperArm_R=(0.86, -0.72, 0.42), LowerArm_R=(0.38, -0.16, 0.18),
                UpperArm_L=(0.22, 0.48, -0.28), UpperLeg_R=(0.12, 0.10, 0.12), UpperLeg_L=(0.18, -0.08, -0.10),
                **{"loc:Hips": (0.00, -0.04, 0.02)},
            ),
            "walk": _pose(Hips=(-0.06, 0.08, 0.0), Chest=(-0.12, 0.16, 0.0), UpperArm_R=(0.68, -0.86, 0.24), UpperArm_L=(0.62, 0.72, -0.20), UpperLeg_R=(0.48, 0.10, 0.12), UpperLeg_L=(-0.08, -0.10, -0.10)),
            "run": _pose(Hips=(-0.10, 0.14, 0.0), Chest=(-0.08, 0.22, 0.0), UpperArm_R=(0.86, -1.02, 0.20), UpperArm_L=(0.82, 0.90, -0.18), UpperLeg_R=(0.68, 0.10, 0.12), UpperLeg_L=(-0.22, -0.10, -0.10)),
            "dash": _pose(Hips=(-0.20, 0.12, 0.0), Chest=(0.16, 0.24, 0.0), UpperArm_R=(1.12, -0.22, 0.78), UpperArm_L=(0.24, 0.56, -0.32)),
            "charge": _pose(
                Hips=(-0.22, 0.0, 0.0), Chest=(-0.62, 0.16, 0.0), Head=(-0.28, 0.12, 0.0),
                UpperArm_R=(1.02, -0.42, 0.62), UpperArm_L=(0.86, 0.48, -0.46),
                **{"loc:Hips": (0.00, -0.06, 0.00)},
            ),
            "heavy_pre": _pose(Hips=(-0.18, 0.08, 0.0), Chest=(-0.48, 0.18, 0.0), UpperArm_R=(1.28, 0.18, 0.56), UpperArm_L=(0.86, -0.22, -0.48)),
            "heavy_precontact": _pose(Hips=(-0.22, 0.12, 0.0), Chest=(0.18, 0.22, 0.0), UpperArm_R=(1.16, -0.08, 0.92), UpperArm_L=(0.72, 0.28, -0.36)),
            "heavy_contact": _pose(
                Hips=(-0.28, 0.16, 0.0), Chest=(0.72, 0.28, 0.0), Head=(-0.16, 0.14, 0.0),
                UpperArm_R=(1.22, -0.16, 1.08), UpperArm_L=(0.42, 0.58, -0.36),
            ),
            "heavy_follow": _pose(Hips=(0.10, 0.14, 0.0), Chest=(0.86, 0.20, 0.0), UpperArm_R=(0.48, -0.62, 0.86), UpperArm_L=(0.92, 0.42, -0.28)),
            "hurt_pre": _pose(Hips=(0.08, 0.0, 0.0), Chest=(0.14, 0.0, 0.0), Head=(0.10, 0.0, 0.0)),
            "hurt_peak": _pose(
                Hips=(0.46, 0.0, 0.0), Spine=(0.62, 0.0, 0.0), Chest=(1.08, 0.0, 0.0),
                Head=(0.84, 0.0, 0.0), UpperArm_R=(-0.38, -1.08, 0.24), UpperArm_L=(-0.30, 1.10, -0.22),
                **{"loc:Hips": (0.08, 0.00, 0.00)},
            ),
            "launch": _pose(Hips=(0.62, 0.0, 0.0), Chest=(1.18, 0.0, 0.0), Head=(0.86, 0.0, 0.0), UpperArm_R=(-0.40, -1.14, 0.20), UpperArm_L=(-0.32, 1.12, -0.18)),
            "super": _pose(
                Hips=(-0.16, 0.0, 0.0), Head=(-0.48, 0.0, 0.0), UpperArm_R=(1.42, -0.68, 0.22),
                UpperArm_L=(1.36, 0.70, -0.20), Chest=(0.22, 0.16, 0.0),
            ),
            "clash_start": _pose(Hips=(-0.12, 0.0, 0.0), Chest=(-0.22, 0.0, 0.0), UpperArm_R=(0.58, 0.62, 0.68), UpperArm_L=(0.58, -0.62, -0.68)),
            "clash_lock": _pose(
                Hips=(-0.24, 0.0, 0.0), Spine=(-0.36, 0.0, 0.0), Chest=(-0.56, 0.0, 0.0),
                Head=(-0.22, 0.0, 0.0), UpperArm_R=(0.82, 0.86, 0.94), UpperArm_L=(0.82, -0.86, -0.94),
                UpperLeg_R=(0.32, 0.12, 0.24), UpperLeg_L=(0.32, -0.12, -0.24),
            ),
            "clash_push": _pose(Hips=(-0.30, 0.0, 0.0), Chest=(-0.66, 0.0, 0.0), UpperArm_R=(0.90, 0.92, 1.00), UpperArm_L=(0.90, -0.92, -1.00)),
            "clash_win": _pose(Hips=(-0.12, 0.0, 0.0), Chest=(-0.06, 0.18, 0.0), UpperArm_R=(0.98, 0.56, 0.76), **{"loc:Hips": (0.06, 0.00, 0.00)}),
            "clash_lose": _pose(Hips=(0.30, 0.0, 0.0), Chest=(0.46, 0.0, 0.0), Head=(0.34, 0.0, 0.0), **{"loc:Hips": (-0.06, 0.00, 0.00)}),
            "clash_break": _pose(Hips=(0.06, 0.10, 0.0), Chest=(0.14, 0.12, 0.0), UpperArm_R=(0.24, -0.38, 0.28), UpperArm_L=(0.24, 0.38, -0.28)),
        }
    # vesper-nyx
    return {
        "idle": _pose(
            Hips=(0.08, 0.28, 0.16), Chest=(0.18, -0.42, 0.22), Head=(0.16, 0.22, -0.12),
            UpperArm_R=(0.28, -0.92, 0.36), UpperArm_L=(0.72, 0.86, -0.42),
            UpperLeg_R=(0.22, 0.14, 0.18), UpperLeg_L=(0.34, -0.18, -0.16),
            **{"loc:Hips": (0.02, 0.02, 0.00)},
        ),
        "walk": _pose(Hips=(0.06, 0.32, 0.16), Chest=(0.14, -0.36, 0.20), UpperArm_R=(0.52, -1.02, 0.22), UpperArm_L=(0.68, 0.92, -0.28), UpperLeg_R=(0.52, 0.12, 0.14), UpperLeg_L=(-0.12, -0.14, -0.12)),
        "run": _pose(Hips=(-0.06, 0.38, 0.18), Chest=(0.18, -0.28, 0.22), UpperArm_R=(0.76, -1.16, 0.18), UpperArm_L=(0.82, 1.06, -0.24), UpperLeg_R=(0.72, 0.12, 0.14), UpperLeg_L=(-0.28, -0.14, -0.12)),
        "dash": _pose(Hips=(-0.18, 0.42, 0.20), Chest=(0.28, -0.18, 0.24), UpperArm_R=(1.08, -0.22, 0.82), UpperArm_L=(0.28, 0.78, -0.40)),
        "charge": _pose(
            Hips=(-0.18, 0.32, 0.18), Chest=(0.42, -0.58, 0.28), Head=(0.22, 0.18, -0.16),
            UpperArm_R=(0.42, -1.08, 0.42), UpperArm_L=(0.96, 0.98, -0.48),
            UpperLeg_L=(0.42, -0.22, -0.18),
        ),
        "heavy_pre": _pose(Hips=(-0.16, 0.30, 0.16), Chest=(0.22, -0.48, 0.24), UpperArm_R=(1.18, 0.28, 0.62), UpperArm_L=(0.48, 0.72, -0.36)),
        "heavy_precontact": _pose(Hips=(-0.20, 0.36, 0.18), Chest=(0.36, -0.22, 0.26), UpperArm_R=(1.22, 0.02, 0.98), UpperArm_L=(0.42, 0.78, -0.40)),
        "heavy_contact": _pose(
            Hips=(-0.26, 0.42, 0.22), Chest=(0.68, -0.18, 0.30), Head=(0.10, 0.26, -0.10),
            UpperArm_R=(1.28, -0.14, 1.18), UpperArm_L=(0.22, 0.86, -0.46),
            UpperLeg_R=(0.16, 0.16, 0.22), UpperLeg_L=(0.40, -0.18, -0.16),
        ),
        "heavy_follow": _pose(Hips=(0.12, 0.38, 0.20), Chest=(0.78, -0.28, 0.26), UpperArm_R=(0.46, -0.82, 0.88), UpperArm_L=(0.58, 0.72, -0.32)),
        "hurt_pre": _pose(Hips=(0.08, 0.10, 0.08), Chest=(0.14, -0.16, 0.10), Head=(0.12, 0.10, -0.08)),
        "hurt_peak": _pose(
            Hips=(0.48, -0.48, 0.24), Spine=(0.62, -0.38, 0.20), Chest=(1.06, -0.72, 0.32),
            Head=(0.86, 0.44, -0.28), UpperArm_R=(-0.42, -1.14, 0.26), UpperArm_L=(-0.34, 1.16, -0.24),
            **{"loc:Hips": (0.08, -0.04, 0.00)},
        ),
        "launch": _pose(Hips=(0.64, -0.32, 0.22), Chest=(1.16, -0.48, 0.28), Head=(0.88, 0.32, -0.22), UpperArm_R=(-0.38, -1.12, 0.22), UpperArm_L=(-0.30, 1.08, -0.20)),
        "super": _pose(
            Hips=(-0.32, 0.58, 0.26), Chest=(0.78, -0.56, 0.34), Head=(0.18, 0.32, -0.18),
            UpperArm_R=(1.48, 0.22, 0.38), UpperArm_L=(0.18, 1.08, -0.36),
            **{"loc:Hips": (0.00, 0.06, 0.00)},
        ),
        "clash_start": _pose(Hips=(-0.12, 0.16, 0.10), Chest=(-0.18, -0.22, 0.12), UpperArm_R=(0.56, 0.62, 0.68), UpperArm_L=(0.56, -0.62, -0.68)),
        "clash_lock": _pose(
            Hips=(-0.24, 0.20, 0.12), Spine=(-0.32, -0.18, 0.10), Chest=(-0.48, -0.36, 0.16),
            Head=(-0.16, 0.20, -0.10), UpperArm_R=(0.80, 0.86, 0.94), UpperArm_L=(0.80, -0.86, -0.94),
            UpperLeg_R=(0.36, 0.16, 0.26), UpperLeg_L=(0.36, -0.16, -0.26),
        ),
        "clash_push": _pose(Hips=(-0.30, 0.22, 0.12), Chest=(-0.58, -0.42, 0.16), UpperArm_R=(0.88, 0.92, 1.00), UpperArm_L=(0.88, -0.92, -1.00)),
        "clash_win": _pose(Hips=(-0.14, 0.28, 0.16), Chest=(0.16, -0.28, 0.20), UpperArm_R=(0.98, 0.58, 0.76), **{"loc:Hips": (0.06, 0.04, 0.00)}),
        "clash_lose": _pose(Hips=(0.30, -0.22, 0.10), Chest=(0.48, -0.36, 0.12), Head=(0.34, -0.24, -0.10), **{"loc:Hips": (-0.06, -0.02, 0.00)}),
        "clash_break": _pose(Hips=(0.08, 0.22, 0.12), Chest=(0.16, -0.18, 0.14), UpperArm_R=(0.24, -0.42, 0.28), UpperArm_L=(0.24, 0.42, -0.28)),
    }


def pose_v9(fid: str, action: str):
    table = _identity(fid)
    if action in table:
        return table[action]
    if action == "personality_idle":
        return add(table["idle"], {"Head": _e(0.10, 0.14, 0.08), "Chest": _e(-0.08, 0.10, 0.06)})
    return table.get("idle", blank())


def idle_v9(fid: str):
    return pose_v9(fid, "idle")


def charge_100_v9(fid: str):
    return pose_v9(fid, "charge")


def super_pose_v9(fid: str):
    return pose_v9(fid, "super")


def overlay_table(fid: str) -> dict:
    table = overlay_v7(fid)
    table["idle"] = {1: pose_v9(fid, "idle")}
    table["personality_idle"] = {8: pose_v9(fid, "personality_idle")}
    table["walk"] = {8: pose_v9(fid, "walk"), 16: pose_v9(fid, "walk")}
    table["run"] = {6: pose_v9(fid, "run"), 12: pose_v9(fid, "run")}
    table["dash"] = {4: pose_v9(fid, "dash")}
    table["charged_idle"] = {12: pose_v9(fid, "charge")}
    table["charge_full"] = {12: pose_v9(fid, "charge")}
    table["heavy"] = {
        4: pose_v9(fid, "heavy_pre"),
        8: pose_v9(fid, "heavy_precontact"),
        11: pose_v9(fid, "heavy_contact"),
        16: pose_v9(fid, "heavy_follow"),
    }
    table["hurt_heavy"] = {
        2: pose_v9(fid, "hurt_pre"),
        6: pose_v9(fid, "hurt_peak"),
        10: pose_v9(fid, "launch"),
    }
    table["launch"] = {4: pose_v9(fid, "launch")}
    table["clash_lock"] = {
        2: pose_v9(fid, "clash_start"),
        8: pose_v9(fid, "clash_lose"),
        12: pose_v9(fid, "clash_lock"),
        16: pose_v9(fid, "clash_push"),
        20: pose_v9(fid, "clash_win"),
        24: pose_v9(fid, "clash_break"),
    }
    table["signature_lane_finisher"] = {16: pose_v9(fid, "super")}
    table["aura_signature"] = {12: pose_v9(fid, "super")}
    table["aura_burst_super_pose"] = {16: pose_v9(fid, "super")}
    return table


STRESS_POSE_ALIASES = {
    "idle": ("idle", "idle"),
    "walk_extreme": ("walk", "walk"),
    "run_extreme": ("run", "run"),
    "dash": ("dash", "dash"),
    "heavy_anticipation": ("heavy_pre", "heavy_pre"),
    "heavy_contact": ("heavy_contact", "heavy_contact"),
    "heavy_follow": ("heavy_follow", "heavy_follow"),
    "hurt_heavy": ("hurt_peak", "hurt_peak"),
    "launch_start": ("launch", "launch"),
    "charge_100": ("charge", "charge"),
    "super": ("super", "super"),
    "clash_start": ("clash_start", "clash_start"),
    "clash_lock": ("clash_lock", "clash_lock"),
    "clash_push": ("clash_push", "clash_push"),
    "clash_win": ("clash_win", "clash_win"),
    "clash_lose": ("clash_lose", "clash_lose"),
    "KO": ("launch", "launch"),
}
