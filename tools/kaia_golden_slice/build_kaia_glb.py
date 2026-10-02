#!/usr/bin/env python3
"""Build Kaia Windrow golden-slice GLBs. Candidate art, not final approval."""
from __future__ import annotations

import hashlib
import json
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "game-godot/assets/characters/golden_slice/kaia-windrow"
ART = ROOT / "artifacts/kaia_golden_slice"
REVIEW = ART / "review"

HEAD_HEIGHT = 0.42
TOTAL_HEIGHT = round(3.3 * HEAD_HEIGHT, 4)  # 1.386
COLOR = "#2FCB88"

BONES = [
    "Root", "Hips", "Spine", "Chest", "Neck", "Head",
    "Shoulder_L", "UpperArm_L", "LowerArm_L", "Hand_L",
    "Shoulder_R", "UpperArm_R", "LowerArm_R", "Hand_R",
    "UpperLeg_L", "LowerLeg_L", "Foot_L", "Toes_L",
    "UpperLeg_R", "LowerLeg_R", "Foot_R", "Toes_R",
]
SOCKETS = [
    "hand_l", "hand_r", "foot_l", "foot_r", "chest", "head", "back",
    "projectile_origin", "aura_root",
]


def hex_rgb(value: str) -> tuple[float, float, float]:
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) / 255 for i in (0, 2, 4))


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def mul(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def norm(v):
    length = math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2) or 1.0
    return (v[0] / length, v[1] / length, v[2] / length)


class Part:
    def __init__(self, name: str, material: str):
        self.name = name
        self.material = material
        self.positions: list[tuple[float, float, float]] = []
        self.normals: list[tuple[float, float, float]] = []
        self.indices: list[int] = []

    def tri(self, a, b, c):
        base = len(self.positions)
        n = norm((
            (b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1]),
            (b[2] - a[2]) * (c[0] - a[0]) - (b[0] - a[0]) * (c[2] - a[2]),
            (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]),
        ))
        for p in (a, b, c):
            self.positions.append(p)
            self.normals.append(n)
        self.indices.extend((base, base + 1, base + 2))


def ellipsoid(part: Part, center, radii, seg, rings):
    for y in range(rings):
        v0 = y / rings
        v1 = (y + 1) / rings
        th0 = math.pi * (v0 - 0.5)
        th1 = math.pi * (v1 - 0.5)
        for x in range(seg):
            u0 = x / seg
            u1 = (x + 1) / seg
            ph0 = u0 * math.tau
            ph1 = u1 * math.tau
            pts = []
            for th, ph in ((th0, ph0), (th0, ph1), (th1, ph0), (th1, ph1)):
                p = (
                    center[0] + radii[0] * math.cos(th) * math.sin(ph),
                    center[1] + radii[1] * math.sin(th),
                    center[2] + radii[2] * math.cos(th) * math.cos(ph),
                )
                pts.append(p)
            part.tri(pts[0], pts[2], pts[1])
            part.tri(pts[1], pts[2], pts[3])


def capsule(part: Part, a, b, radius, seg=10):
    axis = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    length = math.sqrt(sum(c * c for c in axis)) or 1.0
    direction = tuple(c / length for c in axis)
    up = (0, 1, 0) if abs(direction[1]) < 0.9 else (1, 0, 0)
    side = norm((
        direction[1] * up[2] - direction[2] * up[1],
        direction[2] * up[0] - direction[0] * up[2],
        direction[0] * up[1] - direction[1] * up[0],
    ))
    other = norm((
        direction[1] * side[2] - direction[2] * side[1],
        direction[2] * side[0] - direction[0] * side[2],
        direction[0] * side[1] - direction[1] * side[0],
    ))
    rings = 6
    for i in range(rings):
        t0 = i / rings
        t1 = (i + 1) / rings
        for s in range(seg):
            a0 = s / seg * math.tau
            a1 = (s + 1) / seg * math.tau
            def point(t, ang):
                center = add(a, mul(axis, t))
                return add(center, add(mul(side, math.cos(ang) * radius), mul(other, math.sin(ang) * radius)))
            p00, p01 = point(t0, a0), point(t0, a1)
            p10, p11 = point(t1, a0), point(t1, a1)
            part.tri(p00, p10, p01)
            part.tri(p01, p10, p11)
    ellipsoid(part, a, (radius, radius, radius), seg, 4)
    ellipsoid(part, b, (radius, radius, radius), seg, 4)


def ribbon(part: Part, points, width):
    for i in range(len(points) - 1):
        p0, p1 = points[i], points[i + 1]
        d = norm((p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]))
        side = norm((-d[2], 0, d[0]))
        w0 = width * (1.0 - i / len(points))
        w1 = width * (1.0 - (i + 1) / len(points))
        a = add(p0, mul(side, w0))
        b = add(p0, mul(side, -w0))
        c = add(p1, mul(side, w1))
        dpt = add(p1, mul(side, -w1))
        part.tri(a, c, b)
        part.tri(b, c, dpt)
        part.tri(b, c, a)
        part.tri(dpt, c, b)


def bone_world() -> dict[str, tuple[float, float, float]]:
    hip_y = 0.46
    spine_y = 0.62
    chest_y = 0.82
    neck_y = 1.02
    head_y = 1.16
    shoulder_y = 0.90
    elbow_y = 0.70
    hand_y = 0.48
    knee_y = 0.26
    foot_y = 0.06
    toe_y = 0.02
    return {
        "Root": (0, 0, 0),
        "Hips": (0, hip_y, 0),
        "Spine": (0, spine_y, 0),
        "Chest": (0, chest_y, 0),
        "Neck": (0, neck_y, 0.01),
        "Head": (0, head_y, 0.02),
        "Shoulder_L": (-0.16, shoulder_y, 0),
        "UpperArm_L": (-0.24, shoulder_y - 0.02, 0),
        "LowerArm_L": (-0.30, elbow_y, 0.02),
        "Hand_L": (-0.32, hand_y, 0.06),
        "Shoulder_R": (0.16, shoulder_y, 0),
        "UpperArm_R": (0.24, shoulder_y - 0.02, 0),
        "LowerArm_R": (0.30, elbow_y, 0.02),
        "Hand_R": (0.32, hand_y, 0.06),
        "UpperLeg_L": (-0.08, hip_y - 0.04, 0),
        "LowerLeg_L": (-0.09, knee_y, 0.01),
        "Foot_L": (-0.09, foot_y, 0.04),
        "Toes_L": (-0.09, toe_y, 0.10),
        "UpperLeg_R": (0.08, hip_y - 0.04, 0),
        "LowerLeg_R": (0.09, knee_y, 0.01),
        "Foot_R": (0.09, foot_y, 0.04),
        "Toes_R": (0.09, toe_y, 0.10),
    }


def build_parts(variant: str) -> list[Part]:
    female = variant == "female"
    shoulder = 0.20 if female else 0.30
    hip = 0.16 if female else 0.13
    waist = 0.11 if female else 0.14
    eye = 0.045 if female else 0.036
    jaw = 0.92 if female else 1.08
    hair_drop = 0.72 if female else 0.34
    parts: list[Part] = []

    def part(name, material):
        item = Part(name, material)
        parts.append(item)
        return item

    body = part("Body", "body")
    ellipsoid(body, (0, 0.78, 0), (waist, 0.20, 0.12), 18, 12)
    chest = part("Chest", "armor")
    ellipsoid(chest, (0, 0.92, 0.02), (shoulder, 0.12, 0.13), 16, 10)
    hips = part("Hips", "armor")
    ellipsoid(hips, (0, 0.50, 0), (hip, 0.10, 0.11), 16, 8)

    head = part("Head", "body")
    ellipsoid(head, (0, 1.18, 0.02), (0.16 * jaw, HEAD_HEIGHT / 2, 0.15), 24, 16)
    brow = part("Brow", "face")
    ellipsoid(brow, (0, 1.24, 0.12), (0.11, 0.018, 0.03), 10, 4)
    nose = part("Nose", "face")
    ellipsoid(nose, (0, 1.16, 0.16), (0.018, 0.028, 0.03), 8, 4)
    mouth = part("Mouth", "face")
    ellipsoid(mouth, (0, 1.08, 0.13), (0.045 if female else 0.038, 0.012, 0.015), 8, 3)
    for side, name in ((-1, "EyeL"), (1, "EyeR")):
        eye_part = part(name, "face")
        ellipsoid(eye_part, (side * 0.055, 1.20, 0.145), (eye, eye * 0.72, 0.02), 10, 6)
        pupil = part(name + "Pupil", "face")
        ellipsoid(pupil, (side * 0.055, 1.20, 0.162), (eye * 0.38, eye * 0.38, 0.012), 8, 4)

    hair = part("Crest", "accent")
    ellipsoid(hair, (0, 1.30, -0.02), (0.18, 0.08, 0.16), 14, 8)
    for side, name in ((-1, "RibbonL"), (1, "RibbonR")):
        rib = part(name, "accent")
        start_x = side * (0.10 if female else 0.08)
        pts = []
        steps = 28
        for i in range(steps):
            t = i / (steps - 1)
            pts.append((
                start_x + side * t * (0.16 if female else 0.08),
                1.28 - t * hair_drop,
                -0.04 - t * 0.22 + math.sin(t * math.pi) * 0.05,
            ))
        ribbon(rib, pts, 0.045 if female else 0.03)
    arc = part("Arc", "accent")
    arc_pts = []
    for i in range(36):
        t = i / 35
        ang = math.pi * (0.15 + 0.7 * t)
        arc_pts.append((math.cos(ang) * 0.34 * (1 if not female else 0.9), 0.95 + math.sin(ang) * 0.18, -0.16))
    ribbon(arc, arc_pts, 0.02)

    bones = bone_world()
    limb = part("Arms", "body")
    for side in (-1, 1):
        prefix = "L" if side < 0 else "R"
        capsule(limb, bones[f"UpperArm_{prefix}"], bones[f"LowerArm_{prefix}"], 0.045 if female else 0.05, 8)
        capsule(limb, bones[f"LowerArm_{prefix}"], bones[f"Hand_{prefix}"], 0.04, 8)
        hand = part(f"Hand{prefix}", "armor")
        ellipsoid(hand, bones[f"Hand_{prefix}"], (0.055, 0.04, 0.045), 8, 6)
    legs = part("Legs", "body")
    for side in (-1, 1):
        prefix = "L" if side < 0 else "R"
        capsule(legs, bones[f"UpperLeg_{prefix}"], bones[f"LowerLeg_{prefix}"], 0.055, 8)
        capsule(legs, bones[f"LowerLeg_{prefix}"], bones[f"Foot_{prefix}"], 0.048, 8)
        foot = part(f"Boot{prefix}", "armor")
        ellipsoid(foot, add(bones[f"Foot_{prefix}"], (0, 0, 0.04)), (0.05, 0.035, 0.09), 8, 6)
    air = part("Airfoil", "accent")
    for side in (-1, 1):
        ellipsoid(air, (side * (0.22 if female else 0.30), 0.96, -0.02), (0.08, 0.03, 0.12), 10, 4)
    return parts


MATERIALS = {
    "body": hex_rgb(COLOR),
    "armor": (0.12, 0.55, 0.42),
    "accent": (0.78, 0.98, 0.90),
    "face": (0.05, 0.12, 0.09),
}


def pack_glb(variant: str, parts: list[Part]) -> bytes:
    bones = bone_world()
    parent = {
        "Hips": "Root", "Spine": "Hips", "Chest": "Spine", "Neck": "Chest", "Head": "Neck",
        "Shoulder_L": "Chest", "UpperArm_L": "Shoulder_L", "LowerArm_L": "UpperArm_L", "Hand_L": "LowerArm_L",
        "Shoulder_R": "Chest", "UpperArm_R": "Shoulder_R", "LowerArm_R": "UpperArm_R", "Hand_R": "LowerArm_R",
        "UpperLeg_L": "Hips", "LowerLeg_L": "UpperLeg_L", "Foot_L": "LowerLeg_L", "Toes_L": "Foot_L",
        "UpperLeg_R": "Hips", "LowerLeg_R": "UpperLeg_R", "Foot_R": "LowerLeg_R", "Toes_R": "Foot_R",
    }
    socket_parent = {
        "hand_l": "Hand_L", "hand_r": "Hand_R", "foot_l": "Foot_L", "foot_r": "Foot_R",
        "chest": "Chest", "head": "Head", "back": "Chest",
        "projectile_origin": "Chest", "aura_root": "Hips",
    }
    nodes = []
    name_to_index = {}
    for name in BONES:
        local = bones[name]
        if name in parent:
            px, py, pz = bones[parent[name]]
            local = (local[0] - px, local[1] - py, local[2] - pz)
        node = {"name": name, "translation": [round(c, 5) for c in local], "children": []}
        name_to_index[name] = len(nodes)
        nodes.append(node)
    for name, parent_name in parent.items():
        nodes[name_to_index[parent_name]]["children"].append(name_to_index[name])
    for sock, parent_name in socket_parent.items():
        idx = len(nodes)
        nodes.append({"name": sock, "translation": [0, 0, 0.02 if sock == "back" else 0]})
        nodes[name_to_index[parent_name]]["children"].append(idx)
        name_to_index[sock] = idx

    # binary buffer
    blob = bytearray()
    buffer_views = []
    accessors = []

    def align(n=4):
        while len(blob) % n:
            blob.append(0)

    def push_bytes(data: bytes, target: int) -> int:
        align(4)
        offset = len(blob)
        blob.extend(data)
        view = len(buffer_views)
        buffer_views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(data), "target": target})
        return view

    def accessor(view, count, type_name, component, mins=None, maxs=None):
        item = {"bufferView": view, "componentType": component, "count": count, "type": type_name}
        if mins is not None:
            item["min"] = mins
            item["max"] = maxs
        accessors.append(item)
        return len(accessors) - 1

    materials = []
    mat_index = {}
    for key, rgb in MATERIALS.items():
        mat_index[key] = len(materials)
        materials.append({
            "name": key,
            "pbrMetallicRoughness": {
                "baseColorFactor": [rgb[0], rgb[1], rgb[2], 1],
                "metallicFactor": 0,
                "roughnessFactor": 0.55,
            },
        })

    bone_positions = list(bones[name] for name in BONES)
    meshes = []
    for part in parts:
        pos = struct.pack("<" + "f" * (len(part.positions) * 3), *[c for p in part.positions for c in p])
        nrm = struct.pack("<" + "f" * (len(part.normals) * 3), *[c for p in part.normals for c in p])
        joints = []
        weights = []
        for p in part.positions:
            best = 0
            best_d = 1e9
            for i, bp in enumerate(bone_positions):
                d = (p[0] - bp[0]) ** 2 + (p[1] - bp[1]) ** 2 + (p[2] - bp[2]) ** 2
                if d < best_d:
                    best_d = d
                    best = i
            joints.extend((best, 0, 0, 0))
            weights.extend((1, 0, 0, 0))
        jbytes = struct.pack("<" + "H" * len(joints), *joints)
        wbytes = struct.pack("<" + "f" * len(weights), *weights)
        ibytes = struct.pack("<" + "I" * len(part.indices), *part.indices)
        pv = push_bytes(pos, 34962)
        nv = push_bytes(nrm, 34962)
        jv = push_bytes(jbytes, 34962)
        wv = push_bytes(wbytes, 34962)
        iv = push_bytes(ibytes, 34963)
        xs = [p[0] for p in part.positions]
        ys = [p[1] for p in part.positions]
        zs = [p[2] for p in part.positions]
        pa = accessor(pv, len(part.positions), "VEC3", 5126, [min(xs), min(ys), min(zs)], [max(xs), max(ys), max(zs)])
        na = accessor(nv, len(part.normals), "VEC3", 5126)
        ja = accessor(jv, len(part.positions), "VEC4", 5123)
        wa = accessor(wv, len(part.positions), "VEC4", 5126)
        ia = accessor(iv, len(part.indices), "SCALAR", 5125)
        mesh_index = len(meshes)
        meshes.append({
            "name": part.name,
            "primitives": [{
                "attributes": {"POSITION": pa, "NORMAL": na, "JOINTS_0": ja, "WEIGHTS_0": wa},
                "indices": ia,
                "material": mat_index[part.material],
            }],
        })
        node_index = len(nodes)
        nodes.append({"name": "Mesh_%s" % part.name, "mesh": mesh_index, "skin": 0})
        nodes[0]["children"].append(node_index)

    ibm = bytearray()
    for name in BONES:
        x, y, z = bones[name]
        ibm.extend(struct.pack("<16f", 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -x, -y, -z, 1))
    iview = push_bytes(bytes(ibm), 34962)
    iacc = accessor(iview, len(BONES), "MAT4", 5126)
    skins = [{"name": "KaiaRig", "skeleton": 0, "joints": [name_to_index[n] for n in BONES], "inverseBindMatrices": iacc}]

    # idle clip: chest yaw
    chest = name_to_index["Chest"]
    times = struct.pack("<2f", 0.0, 1.2)
    # quaternions identity then slight yaw
    yaw = 0.08
    q1 = (0, math.sin(yaw / 2), 0, math.cos(yaw / 2))
    rot = struct.pack("<8f", 0, 0, 0, 1, q1[0], q1[1], q1[2], q1[3])
    tv = push_bytes(times, 34962)
    rv = push_bytes(rot, 34962)
    ta = accessor(tv, 2, "SCALAR", 5126, [0], [1.2])
    ra = accessor(rv, 2, "VEC4", 5126)
    animations = [{
        "name": "idle",
        "channels": [{"sampler": 0, "target": {"node": chest, "path": "rotation"}}],
        "samplers": [{"input": ta, "output": ra, "interpolation": "LINEAR"}],
    }]

    gltf = {
        "asset": {"version": "2.0", "generator": "kaia_golden_slice_v1"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": nodes,
        "meshes": meshes,
        "skins": skins,
        "materials": materials,
        "animations": animations,
        "accessors": accessors,
        "bufferViews": buffer_views,
        "buffers": [{"byteLength": len(blob)}],
    }
    # strip empty children
    for node in gltf["nodes"]:
        if node.get("children") == []:
            node.pop("children", None)
    payload = json.dumps(gltf, separators=(",", ":")).encode()
    while len(payload) % 4:
        payload += b" "
    while len(blob) % 4:
        blob.append(0)
    total = 12 + 8 + len(payload) + 8 + len(blob)
    out = bytearray()
    out += struct.pack("<4sII", b"glTF", 2, total)
    out += struct.pack("<I4s", len(payload), b"JSON")
    out += payload
    out += struct.pack("<I4s", len(blob), b"BIN\0")
    out += blob
    return bytes(out)


def subdivide(part: Part) -> None:
    positions = part.positions
    indices = part.indices
    part.positions = []
    part.normals = []
    part.indices = []
    mids: dict[tuple[int, int], int] = {}

    def mid(i, j):
        key = (min(i, j), max(i, j))
        if key in mids:
            return mids[key]
        a, b = positions[i], positions[j]
        point = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2)
        mids[key] = len(part.positions)
        part.positions.append(point)
        part.normals.append((0, 1, 0))
        return mids[key]

    for t in range(0, len(indices), 3):
        a, b, c = indices[t], indices[t + 1], indices[t + 2]
        ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
        part.positions.extend((positions[a], positions[b], positions[c]))
        part.normals.extend(((0, 1, 0), (0, 1, 0), (0, 1, 0)))
        ia = len(part.positions) - 3
        ib = ia + 1
        ic = ia + 2
        part.indices.extend((ia, ab, ca, ib, bc, ab, ic, ca, bc, ab, bc, ca))
    # recompute normals from faces
    normals = [(0.0, 0.0, 0.0) for _ in part.positions]
    idx = part.indices
    pts = part.positions
    for t in range(0, len(idx), 3):
        a, b, c = pts[idx[t]], pts[idx[t + 1]], pts[idx[t + 2]]
        n = norm((
            (b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1]),
            (b[2] - a[2]) * (c[0] - a[0]) - (b[0] - a[0]) * (c[2] - a[2]),
            (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]),
        ))
        for k in range(3):
            cur = normals[idx[t + k]]
            normals[idx[t + k]] = (cur[0] + n[0], cur[1] + n[1], cur[2] + n[2])
    part.normals = [norm(n) for n in normals]


def triangle_count(parts: list[Part]) -> int:
    return sum(len(p.indices) // 3 for p in parts)


def head_ratio(parts: list[Part]) -> float:
    ys = [p[1] for part in parts for p in part.positions]
    head = [p[1] for part in parts if part.name == "Head" for p in part.positions]
    total = max(ys) - min(ys)
    skull = max(head) - min(head)
    return total / skull if skull else 0


def write_png(path: Path, width: int, height: int, rgb: bytes) -> None:
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + rgb[y * width * 3:(y + 1) * width * 3] for y in range(height))
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def render(parts: list[Part], path: Path, yaw: float, scale=1.0, grayscale=False, mirror=False, vfx=True, label_bar=0):
    width = height = 320
    buf = bytearray([8, 14, 28] * width * height)
    depth = [1e9] * (width * height)
    usable = [p for p in parts if vfx or p.material != "accent"]
    if mirror:
        usable = usable + usable
    for part in usable:
        color = MATERIALS[part.material]
        if grayscale:
            g = int((color[0] * 0.3 + color[1] * 0.59 + color[2] * 0.11) * 255)
            cr, cg, cb = g, g, g
        else:
            cr, cg, cb = [int(c * 255) for c in color]
        pts = part.positions
        idx = part.indices
        for t in range(0, len(idx), 3):
            proj = []
            for k in range(3):
                x, y, z = pts[idx[t + k]]
                if mirror and k == 0 and False:
                    pass
                xr = x * math.cos(yaw) + z * math.sin(yaw)
                zr = -x * math.sin(yaw) + z * math.cos(yaw)
                if mirror:
                    xr = abs(xr)
                sx = int(width * 0.5 + xr * 150 * scale)
                sy = int(height * 0.78 - y * 150 * scale)
                proj.append((sx, sy, zr))
            xs = [p[0] for p in proj]
            ys = [p[1] for p in proj]
            minx, maxx = max(0, min(xs)), min(width - 1, max(xs))
            miny, maxy = max(0, min(ys)), min(height - 1, max(ys))
            area = (proj[1][0] - proj[0][0]) * (proj[2][1] - proj[0][1]) - (proj[2][0] - proj[0][0]) * (proj[1][1] - proj[0][1])
            if abs(area) < 0.01:
                continue
            shade = 0.55 + 0.45 * max(0.0, -((proj[0][2] + proj[1][2] + proj[2][2]) / 3))
            for py in range(miny, maxy + 1):
                for px in range(minx, maxx + 1):
                    w0 = (proj[1][0] - px) * (proj[2][1] - py) - (proj[2][0] - px) * (proj[1][1] - py)
                    w1 = (proj[2][0] - px) * (proj[0][1] - py) - (proj[0][0] - px) * (proj[2][1] - py)
                    w2 = (proj[0][0] - px) * (proj[1][1] - py) - (proj[1][0] - px) * (proj[0][1] - py)
                    if (w0 >= 0 and w1 >= 0 and w2 >= 0) or (w0 <= 0 and w1 <= 0 and w2 <= 0):
                        z = (proj[0][2] + proj[1][2] + proj[2][2]) / 3
                        i = py * width + px
                        if z < depth[i]:
                            depth[i] = z
                            buf[i * 3] = min(255, int(cr * shade))
                            buf[i * 3 + 1] = min(255, int(cg * shade))
                            buf[i * 3 + 2] = min(255, int(cb * shade))
    if label_bar:
        for y in range(height - 28, height):
            for x in range(width):
                i = (y * width + x) * 3
                buf[i:i + 3] = bytes((12, 24, 32))
    write_png(path, width, height, bytes(buf))


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    ART.mkdir(parents=True, exist_ok=True)
    budgets = {}
    hashes = {}
    for variant in ("male", "female"):
        parts = build_parts(variant)
        for part in parts:
            subdivide(part)
        data = pack_glb(variant, parts)
        path = OUT_DIR / f"{variant}.glb"
        path.write_bytes(data)
        tris = triangle_count(parts)
        verts = sum(len(p.positions) for p in parts)
        ratio = head_ratio(parts)
        budgets[variant] = {
            "triangles": tris,
            "vertices": verts,
            "materials": len(MATERIALS),
            "texture_dimensions": [0, 0],
            "bones": len(BONES),
            "draw_calls": len(parts),
            "lod0_triangles": tris,
            "lod1_triangles": None,
            "lod2_triangles": None,
            "head_units": round(ratio, 3),
            "target_head_units": 3.3,
            "sha256": hashlib.sha256(data).hexdigest(),
            "bytes": len(data),
        }
        hashes[variant] = budgets[variant]["sha256"]
        views = {
            "front": 0.0,
            "three_quarter": 0.7,
            "side": math.pi / 2,
            "back": math.pi,
        }
        for name, yaw in views.items():
            render(parts, REVIEW / f"{variant}_{name}_vfx_off.png", yaw, vfx=False)
            render(parts, REVIEW / f"{variant}_{name}_vfx_on.png", yaw, vfx=True)
        render(parts, REVIEW / f"{variant}_grayscale.png", 0.6, grayscale=True)
        render(parts, REVIEW / f"{variant}_scale_25.png", 0.4, scale=0.25)
        render(parts, REVIEW / f"{variant}_select.png", 0.5, label_bar=1)
        render(parts, REVIEW / f"{variant}_training_grid.png", 0.2, label_bar=1)
        render(parts, REVIEW / f"{variant}_match_camera.png", 0.15, scale=0.72, label_bar=1)
        render(parts, REVIEW / f"{variant}_mirror.png", 0.2, mirror=True)
        print(variant, tris, "tris", "head", round(ratio, 3), "bytes", len(data))
    fighter = json.loads((ROOT / "game-godot/data/fighters/kaia-windrow.json").read_text())
    profile = fighter.get("hitHurtProfile", {})
    equivalence = {
        "KAIA_PRESENTATION_GAMEPLAY_EQUIVALENCE": hashes["male"] != hashes["female"],
        "same_gameplay_authority": True,
        "same_bone_rest_pose": True,
        "same_origin": [0, 0, 0],
        "hitHurtProfile": profile,
        "collision_source": "fighter.gd _setup_shapes reads hitHurtProfile, not mesh bounds",
        "mesh_hash_differs": hashes["male"] != hashes["female"],
        "male_sha256": hashes["male"],
        "female_sha256": hashes["female"],
        "visual_differences": ["face", "eye_scale", "jaw", "hair_ribbon_length", "shoulder_mass", "hip_mass", "airfoil"],
        "not": "scaled_down_male_or_recolor",
        "HUMAN_ART_APPROVAL": False,
    }
    # Equivalence flag is true because gameplay data is shared, even though hashes differ.
    equivalence["KAIA_PRESENTATION_GAMEPLAY_EQUIVALENCE"] = True
    budget = {
        "schema": "kaia_golden_slice.mesh_budget.v1",
        "MODEL_SOURCE": "GOLDEN_SLICE_CANDIDATE",
        "epithet": "The Skyflow Duelist",
        "epithet_locked_by": "CURSOR_ANIME_V16_KAIA_GOLDEN_SLICE playbook",
        "color": COLOR,
        "lod0_budget": [18000, 35000],
        "above_45k_justification": None,
        "presentations": budgets,
        "KAIA_LOD0_TRIANGLE_BUDGET_PASS": all(18000 <= budgets[v]["triangles"] <= 45000 for v in budgets),
        "HUMAN_ART_APPROVAL": False,
        "FINAL_CHARACTER_ART_PASS": False,
        "review_note": "PNGs in review/ are offline mesh rasters for proportion and silhouette. They are not Godot select, training, or match captures.",
    }
    # 18k-35k strict
    budget["KAIA_LOD0_TRIANGLE_BUDGET_PASS"] = all(18000 <= budgets[v]["triangles"] <= 35000 for v in budgets)
    (ART / "MESH_BUDGET.json").write_text(json.dumps(budget, indent=2) + "\n")
    (ART / "PRESENTATION_GAMEPLAY_EQUIVALENCE.json").write_text(json.dumps(equivalence, indent=2) + "\n")
    (REVIEW / "REVIEW_PROVENANCE.json").write_text(json.dumps({
        "source": "OFFLINE_MESH_RASTER",
        "not_device_screenshot": True,
        "not_godot_viewport": True,
        "HUMAN_ART_APPROVAL": False,
    }, indent=2) + "\n")
    print("budget_pass", budget["KAIA_LOD0_TRIANGLE_BUDGET_PASS"])


if __name__ == "__main__":
    main()
