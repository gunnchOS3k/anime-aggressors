#!/usr/bin/env python3
"""Generate Wave012 design docs, packets, manifests, and honest status artifacts."""
from __future__ import annotations

import json
import platform
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

ANIME_SHA = "3b01c3d3473ec5372c5c1e3126305488dc26a08a"
FIELD_SHA = "12f4416fee08d266b4a34fd43198094ba42ef6d1"
ANYCREATURE_SHA = "ab5b1ce5c13e632f00f7f7cbfdb7a746e315000d"
MOCAP_SHA = "00dfd5385506022d533c84f6737a09f5f4392623"

FIGHTERS = [
    {
        "id": "ember-vale",
        "name": "Ember Vale",
        "lane": "fire/heat/combustion",
        "aura": "charges to overwhelm",
        "palette": ["#E8453C", "#F28C28", "#1A0A08", "#FFD27A"],
        "silhouette": "forward-leaning sprinter, asymmetric ember gauntlets, flame-tail hair volume",
    },
    {
        "id": "rook-ironside",
        "name": "Rook Ironside",
        "lane": "impact/strength/earth/quake/armor",
        "aura": "charges to armor through",
        "palette": ["#6B5B4B", "#C4A574", "#2B2B2B", "#8A7A6A"],
        "silhouette": "wide basalt stance, riveted pauldrons, low center of gravity",
    },
    {
        "id": "juno-spark",
        "name": "Juno Spark",
        "lane": "electricity/lightning/speed/magnetism",
        "aura": "charges to confirm",
        "palette": ["#F5D042", "#3D5AFE", "#0D1B2A", "#7EF9FF"],
        "silhouette": "compact core, capacitor spines, trailing volt scarf",
    },
    {
        "id": "kaia-windrow",
        "name": "Kaia Windrow",
        "lane": "wind/air/storm/flight/pressure",
        "aura": "charges to control air",
        "palette": ["#3CB371", "#A8E6CF", "#1B4332", "#E9F5DB"],
        "silhouette": "upward lines, ribbon glider pack, cross-body gale sash",
    },
    {
        "id": "nix-calder",
        "name": "Nix Calder",
        "lane": "ice/frost/snow/freezing/control",
        "aura": "charges to lock space",
        "palette": ["#4A90D9", "#D6EAF8", "#1B263B", "#A0C4FF"],
        "silhouette": "tall narrow profile, frost mantle, paired shoulder crystals",
    },
    {
        "id": "orion-vell",
        "name": "Orion Vell",
        "lane": "gravity/weight/vectors/attraction/repulsion",
        "aura": "charges to manipulate launch",
        "palette": ["#5B4B8A", "#C9B6E4", "#12081F", "#8E7CC3"],
        "silhouette": "offset gravity rings, suspended orbit nodes, weighted boots",
    },
    {
        "id": "vesper-nyx",
        "name": "Vesper Nyx",
        "lane": "void/darkness/shadow/phase/intangibility",
        "aura": "charges to misdirect/deceive",
        "palette": ["#9B59B6", "#2D132C", "#E0AAFF", "#0B090D"],
        "silhouette": "deep hood, segmented void cape, narrow phase outline",
    },
]

CLIP_KINDS = [
    "idle",
    "run",
    "jump",
    "fall",
    "landing",
    "jab_chain",
    "directional_normals",
    "aerials",
    "heavy",
    "aura_charge",
    "projectile_tap",
    "projectile_medium",
    "projectile_full",
    "grab",
    "throw_forward",
    "throw_back",
    "throw_up",
    "throw_down",
    "shield",
    "dodge",
    "air_dodge",
    "hurt",
    "launch",
    "tumble",
    "recovery",
    "ko",
    "victory",
    "defeat",
]

# Research names appear in design docs only; production names stay original.
ICONIC_STUDIES = {
    "ember-vale": [
        ("Naruto (franchise study)", "Rasengan formation spiral before impact", "build-up spiral readability", "Heat Spiral Latch"),
        ("Avatar: The Last Airbender", "firebending breath + forward surge", "breath-to-strike chain", "Combustion Breath Rush"),
        ("My Hero Academia", "One For All smash windup glow", "power telegraph before smash", "Overheat Gauntlet Break"),
        ("Street Fighter", "Shoryuken rising punch camera lift", "anti-air rise silhouette", "Ember Rising Hook"),
        ("Demon Slayer", "Hinokami dance flame arcs", "arc trail continuity", "Cinder Arc Sweep"),
        ("DBZ (genre study)", "Kamehameha charge crouch", "long charge commitment", "Solar Core Burst"),
    ],
    "rook-ironside": [
        ("JoJo (pose grammar study)", "heavy stance commitment", "pose weight before impact", "Basalt Guard Stance"),
        ("Attack on Titan", "hardened strike impact frames", "armor-crack telegraph", "Plate Fracture Slam"),
        ("Gears of War (weight study)", "shoulder charge commitment", "armor-through pressure", "Ironside Shoulder Drive"),
        ("God of War", "leviathan slam ground quake", "ground-coupled shock", "Quake Hammer Drop"),
        ("Tekken", "king piledriver risk/reward", "command grab risk", "Anvil Directional Crush"),
    ],
    "juno-spark": [
        ("One Punch Man", "speed blitz afterimage", "confirm from dash", "Capacitor Blink Confirm"),
        ("The Flash (genre)", "lightning trail dash", "trail confirms path", "Volt Scarf Dash"),
        ("Kill la Kill", "snap-cut camera on hit", "cutaway confirm", "Snap Arc Confirm"),
        ("InFamous", "chain lightning spread", "multi-target confirm", "Magnet Needle Chain"),
        ("Street Fighter", "electric stun setups", "stun window convert", "Static Hold Convert"),
    ],
    "kaia-windrow": [
        ("Naruto", "wind blade cutting arcs", "curved projectile path", "Gale Ribbon Slice"),
        ("Avatar", "air scooter mobility", "air-column control", "Pressure Column Ride"),
        ("One Piece", "Garp/wind punch shockwave", "pressure wave hit", "Storm Palm Push"),
        ("Bayonetta", "witch time aerial float", "air drift cancel", "Glider Drift Cancel"),
        ("Kid Icarus", "angled arrow arcs", "curved zoning", "Boomerang Gust Blade"),
    ],
    "nix-calder": [
        ("Frozen (elemental study)", "ice wall raise", "terrain denial", "Frost Mantle Wall"),
        ("Sub-Zero (genre)", "ice clone misdirect", "trap persistence", "Chill Decoy Trap"),
        ("Re:Zero", "absolute freeze hold", "lock-space timing", "Absolute Chill Lock"),
        ("Ice Climbers", "stage control platforms", "temporary footing", "Crystal Footing"),
        ("Ori", "freeze projectile pin", "pin then convert", "Rime Pin Convert"),
    ],
    "orion-vell": [
        ("Katamari (vector study)", "attraction gather", "pull field timing", "Orbit Gather Field"),
        ("Portal", "vector remap joke-serious", "launch remap", "Vector Swap Launch"),
        ("Gravity Rush", "tilt fall control", "weight shift recovery", "Mass Tilt Recovery"),
        ("JoJo", "orbiting stands grammar", "orbit nodes", "Suspended Node Orbit"),
        ("Mass Effect", "biotic pull/throw", "pull then throw", "Attraction Slam Route"),
    ],
    "vesper-nyx": [
        ("Hunter x Hunter", "zetsu presence drop", "presence misdirect", "Null Presence Fade"),
        ("Persona", "shadow phase step", "phase cancel", "Umbral Phase Step"),
        ("Hollow Knight", "shade dash i-frames", "intangible dodge", "Void Cape Slip"),
        ("Death Note (tone)", "misdirection timing", "deception beat", "Mark Delay Feint"),
        ("Bayonetta", "witch time slow", "time-skew juice", "Phase Skew Burst"),
    ],
}


def run(cmd: list[str]) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except Exception as e:  # noqa: BLE001
        return 1, str(e)


def detect_env() -> dict:
    blender = "/Applications/Blender.app/Contents/MacOS/Blender"
    blender_ok = Path(blender).exists()
    blender_ver = ""
    if blender_ok:
        _code, out = run([blender, "--version"])
        blender_ver = out.splitlines()[0] if out else ""
    node_code, node_out = run(["node", "-v"])
    py_ver = sys.version.split()[0]
    nv_code, nv_out = run(["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"])
    has_nvidia = nv_code == 0 and bool(nv_out.strip()) and "failed" not in nv_out.lower()
    machine = platform.machine()
    if machine in ("arm64", "aarch64") and platform.system() == "Darwin":
        has_nvidia = False
        gpu_note = "Apple Silicon (Metal); no NVIDIA CUDA GPU"
    else:
        gpu_note = nv_out.strip() or "nvidia-smi unavailable"
    mem_gb = None
    code, out = run(["sysctl", "-n", "hw.memsize"])
    if code == 0 and out.strip().isdigit():
        mem_gb = round(int(out.strip()) / (1024**3), 1)
    disk_free_gb = None
    try:
        usage = shutil.disk_usage(str(ROOT))
        disk_free_gb = round(usage.free / (1024**3), 1)
    except Exception:  # noqa: BLE001
        pass
    vroid = bool(list(Path("/Applications").glob("VRoid*"))) if Path("/Applications").exists() else False
    return {
        "detected_at_utc": NOW,
        "os": f"{platform.system()} {platform.release()}",
        "machine": machine,
        "blender": {"present": blender_ok, "path": blender if blender_ok else None, "version": blender_ver or None},
        "node": {"present": node_code == 0, "version": node_out.strip() if node_code == 0 else None},
        "python": {"present": True, "version": py_ver},
        "nvidia_gpu": {"present": has_nvidia, "detail": gpu_note},
        "cuda": {"present": False, "note": "CUDA requires NVIDIA GPU"},
        "ram_gb": mem_gb,
        "disk_free_gb": disk_free_gb,
        "vroid_studio": {"present": vroid, "note": "GUI authoring; not automatable in this environment"},
        "godot": {"present": shutil.which("godot") is not None or Path("/Applications/Godot.app").exists()},
        "MIXAMO_LLM_MOCAP_EXECUTION": "BLOCKED_ENVIRONMENT_GPU" if not has_nvidia else "ENVIRONMENT_SUPPORTS_GPU",
        "VROID_MODEL_CREATION": "HUMAN_GUI_REQUIRED",
        "MIXAMO_ASSET_ACQUISITION": "HUMAN_ACCOUNT_ACTION_REQUIRED",
    }


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=False) + "\n", encoding="utf-8")


def matrix_md() -> str:
    return f"""# Free Toolchain and License Matrix

Wave012 zero-cost character / motion / juice pipeline.
`CORE_PIPELINE_MONETARY_COST_USD=0`

Pinned prerequisites:
- `ANIME_ACCEPTED_MAIN_SHA={ANIME_SHA}` (PR #81 MERGED; Wave011 PASS)
- `FIELD_KIT_ACCEPTED_MAIN_SHA={FIELD_SHA}` (PR #117 MERGED; GAME-AA-001..010 accepted)

| Tool | Version / commit | URL | License / terms | Monetary cost | Account | GPU | Redistribution | Provenance | Class |
|------|------------------|-----|-----------------|---------------|---------|-----|----------------|------------|-------|
| Godot 4 | 4.5+ / local 4.7.1 | https://godotengine.org | MIT | $0 | none | none | yes (engine MIT) | runtime binary | CORE |
| Blender | 3.3+ (local 3.3.1; target 4.x+) | https://www.blender.org | GPL-2.0-or-later / Blender license | $0 | none | none for DCC | yes for original .blend/.glb | DCC | CORE |
| VRoid Studio | current free desktop | https://vroid.com/en/studio | pixiv/VRoid ToS; item-specific | $0 software | free pixiv account for some features | none | obey item licenses; no franchise packs | human GUI export | CORE |
| VRM Add-on for Blender | open-source VRM bridge | https://vrm-addon-for-blender.info | MIT (project) | $0 | none | none | yes for original exports | bridge | CORE |
| anyCreature | `{ANYCREATURE_SHA[:12]}` | https://github.com/Ariescar/anyCreature | MIT | $0 | none | CPU OK | yes (MIT outputs) | local generator | CORE (creatures/props/silhouette; humanoid pilot only) |
| Adobe Mixamo | web utility | https://www.mixamo.com | Adobe ToS; utility only | $0 where available | Adobe ID | none | **do not redistribute raw Mixamo assets** | acquisition log required | CORE (utility) |
| mixamo-llm-mocap | `{MOCAP_SHA[:12]}` | https://github.com/squall01337/mixamo-llm-mocap | MIT (README); GitHub license NOASSERTION | $0 software | free SMPL-X registration | NVIDIA ~8GB VRAM | yes for derived original clips after retarget | optional advanced motion | OPTIONAL |
| Twinforge | not pinned | n/a | unclear / time-limited | unknown | unknown | unknown | unknown | not evaluated as required | EXPERIMENTAL_TRANSIENT_TOOL / not required |
| sprite-sheet-creator (fal.ai) | n/a | fal.ai dependent | paid API risk | not permanently $0 | API key | cloud | n/a | excluded | REJECTED from CORE |

## Doctrine

1. CORE tools must remain `$0` monetary software/service fees.
2. Optional tools (`required_for_build=false`) may need GPU/account but never gate CI PASS for CORE.
3. No copyrighted franchise assets in production.
4. Time-limited free betas = `EXPERIMENTAL_TRANSIENT_TOOL` only.
5. `CORE_PIPELINE_MONETARY_COST_USD=0` is enforced by `tools/art_pipeline/check_zero_cost_dependencies.py`.

## Honest environment notes

See `artifacts/engineering_wave012/ENVIRONMENT_PROBE.json`.
On Apple Silicon without NVIDIA CUDA: `MIXAMO_LLM_MOCAP_EXECUTION=BLOCKED_ENVIRONMENT_GPU`.
VRoid model creation cannot be automated here: `VROID_MODEL_CREATION=HUMAN_GUI_REQUIRED`.
"""


def bible_md() -> str:
    lines = [
        "# Character Combat Inspiration Bible",
        "",
        "Design-only research anchors. Production names, costumes, animations, VFX, and SFX remain original.",
        "Aura grammar: Ember overwhelms · Rook armors through · Juno confirms · Kaia controls air · Nix locks space · Orion manipulates launch · Vesper misdirects.",
        "",
    ]
    for f in FIGHTERS:
        studies = ICONIC_STUDIES[f["id"]]
        anchors = ", ".join(s[0] for s in studies[:4])
        lines += [
            f"## {f['name']}",
            "",
            f"1. **Original identity** — {f['lane']}; aura {f['aura']}; silhouette: {f['silhouette']}.",
            f"2. **Primary inspiration anchors** — {anchors} (grammar only).",
            "3. **Secondary reference library** — genre elemental fighters, platform-fighter movement, shōnen telegraph timing.",
            "4. **Iconic-moment studies** — see ICONIC_MOMENT_TO_ORIGINAL_MOVE_MATRIX.md.",
            "5. **Movement grammar** — readable acceleration, committed dashes, distinct air drift.",
            "6. **Melee grammar** — clear startup/active/recovery silhouettes; no licensed pose sequences.",
            "7. **Projectile grammar** — lane-colored shapes with unique travel curves.",
            "8. **Defense/recovery grammar** — shield/dodge/recovery match aura personality.",
            "9. **Grab/throw grammar** — four directional throws with original angles.",
            f"10. **Aura/power-up grammar** — {f['aura']}.",
            "11. **Game-juice/camera principles** — hitstop tiers, shake tiers, lane-colored impact flashes.",
            f"12. **Original silhouette brief** — {f['silhouette']}.",
            f"13. **Original costume/material language** — palette {', '.join(f['palette'])}; matte + emissive accents only.",
            "14. **Animation/choreography brief** — see CHOREOGRAPHY_LIBRARY.md + choreography_manifest.json.",
            f"15. **VFX shape/color language** — lane `{f['lane']}` shapes; never copy franchise VFX glyphs.",
            "16. **Explicit do-not-copy boundary** — no franchise costumes, logos, named techniques, voice lines, or 1:1 scenes.",
            "17. **Original move concepts** — derived from ≥3 anchors; production names only (see matrix).",
            "",
        ]
    return "\n".join(lines)


def iconic_md() -> str:
    lines = [
        "# Iconic Moment → Original Move Matrix",
        "",
        "Each study lists research references for designers. Production moves are original composites.",
        "No production move maps 1:1 to a single protected scene. No copyrighted clips/images committed.",
        "",
    ]
    total = 0
    for f in FIGHTERS:
        lines.append(f"## {f['name']}")
        lines.append("")
        for ref, moment, why, original in ICONIC_STUDIES[f["id"]]:
            total += 1
            lines += [
                f"### Study — {original}",
                f"- **Reference character/work (design only):** {ref}",
                f"- **Broad moment description:** {moment}",
                f"- **Why memorable:** {why}",
                "- **Motion principle:** clear anticipation → committed contact → readable follow-through",
                "- **Power principle:** aura-scaled payoff matching fighter lane",
                "- **Camera principle:** short push-in or lift on confirm; never franchise framing copy",
                "- **Impact principle:** lane-colored flash + hitstop tier",
                "- **Risk/reward principle:** longer charge / committed recovery for bigger reward",
                "- **What must NOT be copied:** costume, named technique, exact choreography, SFX, logo",
                f"- **Original Anime Aggressors concept:** `{original}` synthesizing multiple anchors for {f['name']}",
                "",
            ]
    lines.append(f"_Total studies: {total}_")
    return "\n".join(lines)


def vroid_packet(f: dict, detailed: bool) -> str:
    depth = "production-detailed" if detailed else "scale packet"
    return f"""# VRoid Authoring Packet — {f['name']}

Status: `{depth}`
`VROID_MODEL_CREATION=HUMAN_GUI_REQUIRED` (GUI cannot be automated in this environment; do not fabricate VRM/GLB)

## Proportions
- Adult anime-humanoid, readable at game-camera distance
- Lane silhouette: {f['silhouette']}

## Face
- Original facial structure; avoid franchise eye/hair icons
- High-contrast brows for combat readability

## Hair silhouette
- Distinct from other six fighters at black-silhouette distance
- Physics goals: secondary motion without covering hurtbox core

## Outfit construction
- Modular pieces exportable as VRM materials
- Palette: {', '.join(f['palette'])}

## Texture guide
- Base albedo, roughness, emissive accents for aura sockets
- No licensed decals

## Hand/foot readability
- Oversized combat gloves/boots preferred for hitbox alignment

## Accessories
- Lane-specific props only if they do not clip canonical sockets

## Prohibited franchise resemblance
- No costumes/logos/haircuts that read as a single protected property

## Silhouette gates
- Front / side / back black-silhouette must pass distinctiveness vs roster

## Export settings
- VRM 0.x/1.0 compatible; T-pose; meters; -Z forward / Y up after Blender normalize

## Provenance checklist
- [ ] Human GUI authored in VRoid Studio
- [ ] Export logged in content/provenance.json
- [ ] Originality review signed
- [ ] Blender normalize + rig validate PASS
"""


def choreography_md() -> str:
    lines = [
        "# Choreography Library",
        "",
        "Clip intents for all seven fighters. Timing numbers are design targets for animators;",
        "runtime frame data remains owned by `game-godot/data/moves/*.json`.",
        "",
    ]
    for f in FIGHTERS:
        lines.append(f"## {f['name']}")
        lines.append("")
        for clip in CLIP_KINDS:
            lines.append(
                f"- **{clip}** — intent:{f['lane']}/{clip}; anticipation 2–6f; contact readable; "
                f"follow-through lane-colored; recovery punishable; silhouette poses distinct; "
                f"VFX/SFX/camera cues via GAME_JUICE_EVENT_CONTRACT."
            )
        lines.append("")
    return "\n".join(lines)


def choreography_manifest() -> dict:
    fighters = {}
    for f in FIGHTERS:
        clips = {}
        for clip in CLIP_KINDS:
            clips[clip] = {
                "intent": f"{f['id']}:{clip}",
                "anticipation_frames": 4,
                "contact_or_release": "contact" if clip not in ("idle", "run", "fall") else "loop",
                "follow_through_frames": 6,
                "recovery_frames": 8,
                "silhouette_poses": ["anticipation", "extremum", "recovery"],
                "timing_ms_target": 400,
                "hitbox_window": "see moves json" if "jab" in clip or clip in ("heavy", "aerials") else "n/a",
                "vfx_cue": f"juice.{f['id']}.{clip}.vfx",
                "sfx_cue": f"juice.{f['id']}.{clip}.sfx",
                "camera_cue": f"juice.{f['id']}.{clip}.camera",
                "cancels": [],
                "accessibility": {"reduce_flash": True, "reduce_shake": True},
                "status": "REQUIRES_ART_PRODUCTION",
            }
        fighters[f["id"]] = {
            "display_name": f["name"],
            "aura_grammar": f["aura"],
            "clips": clips,
        }
    return {
        "schema_version": 1,
        "wave": "wave012",
        "CORE_PIPELINE_MONETARY_COST_USD": 0,
        "fighters": fighters,
    }


def juice_contract_md() -> str:
    return """# Game Juice Event Contract

Canonical event bus for battle presentation. Normal battle HUD stays clean; debug overlays remain training-only.

## Event families

| Event | Payload keys | Default tier | Notes |
|-------|--------------|--------------|-------|
| `hitstop` | `tier`, `frames` | light/medium/heavy/aura/super | Driven by CombatFeedback |
| `camera_shake` | `tier`, `intensity`, `duration_s` | same tiers | Accessibility can zero |
| `impact_vfx` | `socket`, `element`, `tier` | sockets hand_l/r foot_l/r chest head | |
| `aura_buildup` | `fighter_id`, `level`, `pct` | 0..3 | charge personality per fighter |
| `projectile_trail` | `element`, `charge` | tap/medium/full | |
| `shield_flash` | `fighter_id` | — | |
| `dodge_phase` | `fighter_id`, `air` | — | Vesper-readable phase |
| `grab_flash` | `direction` | — | |
| `landing_dust` | `fighter_id` | — | |
| `recovery_trail` | `element` | — | |
| `ko_burst` | `fighter_id` | heavy | |
| `victory_presentation` | `fighter_id` | — | |
| `sfx` | `event_id`, `category` | — | AudioDirector / procedural bank |
| `rumble` | `strength`, `duration_ms` | optional | controller only |
| `accessibility_reduce` | `flash`, `shake`, `particles` | — | DeviceRoleRuntime |

## Godot hooks

- `game-godot/scripts/combat/combat_feedback.gd` — hitstop/shake/VFX/SFX
- `game-godot/scripts/juice/juice_event_bus.gd` — typed emit/subscribe
- Battle HUD: clean versus presentation
- Training: DebugHud only when competitive rules allow

## Do not

- Put frame-data debug on versus HUD
- Hardcode aggregate PASS for missing art
- Import fal.ai sprite paths into CORE
"""


def canonical_rig_md() -> str:
    return """# Canonical Humanoid Rig

Production characters must validate against `tools/art_pipeline/validate_character_rig.py`.

## Required bones
`Root`, `Hips`, `Spine`, `Chest`, `Neck`, `Head`,
`Shoulder_L`, `UpperArm_L`, `LowerArm_L`, `Hand_L`,
`Shoulder_R`, `UpperArm_R`, `LowerArm_R`, `Hand_R`,
`UpperLeg_L`, `LowerLeg_L`, `Foot_L`, `Toes_L`,
`UpperLeg_R`, `LowerLeg_R`, `Foot_R`, `Toes_R`

## Optional bones
Finger chains, twist bones, skirt/cape/hair chains, weapon props.

## Axes / rest pose
- Rest: T-pose or A-pose documented per asset
- Forward: -Z after Blender normalize; Up: +Y; meters

## Attachment / VFX sockets (required markers or empty nodes)
`hand_l`, `hand_r`, `foot_l`, `foot_r`, `chest`, `head`, `back`, `projectile_origin`, `aura_root`

## Policy
No model is production-ready without validation PASS.
`art_source/` holds authoring; production GLBs live under `game-godot/assets/characters/`.
"""


def mixamo_md() -> str:
    return """# Mixamo Usage and Provenance

Adobe Mixamo is a **no-cost utility** (Adobe ID) for rigging/animation reference where currently available.

## Rules
1. Do **not** redistribute raw Mixamo stock assets in the repository or releases.
2. Prefer modified / original choreography for signature moves.
3. Record acquisition date, Adobe account action, terms snapshot, and derivative transform.
4. If login/manual download is required: `MIXAMO_ASSET_ACQUISITION=HUMAN_ACCOUNT_ACTION_REQUIRED`.

## Current status
`MIXAMO_ASSET_ACQUISITION=HUMAN_ACCOUNT_ACTION_REQUIRED`

No Mixamo FBX files are committed in Wave012.
Derived original clips (after human acquisition + retarget + originality pass) may be logged later under `FINAL_LICENSED` or `FINAL_ORIGINAL` with provenance.
"""


def mocap_gpu_md() -> str:
    return f"""# mixamo-llm-mocap GPU Execution Packet

Pinned: https://github.com/squall01337/mixamo-llm-mocap @{MOCAP_SHA}

## Status
`MIXAMO_LLM_MOCAP_EXECUTION=BLOCKED_ENVIRONMENT_GPU`

This machine has no compatible NVIDIA CUDA GPU (Apple Silicon / Metal only).
Wave012 still ships the full integration packet under `tools/art_pipeline/mocap/`.

## Gates implemented
- environment checker
- install verifier
- GPU/VRAM gate
- SMPL-X gate
- GVHMR checkpoint gate
- Mixamo rig-profile gate
- locked-camera video validator
- action specs (one/two performer)
- retarget QA parser
- Blender apply/export stubs
- Godot import checklist

## Do not
- Buy cloud GPU time
- Fake mocap execution artifacts as PASS
"""


def ember_vertical_slice_md() -> str:
    return """# Ember Vale Free Art Pipeline Vertical Slice

Milestone token: `EMBER_FREE_ART_PIPELINE_VERTICAL_SLICE_PASS` is **PARTIAL** until human VRoid GUI art lands.

## Pipeline stages

| Stage | Status |
|-------|--------|
| brief | PASS (docs) |
| authored/generated model source | `HUMAN_GUI_REQUIRED` / anyCreature pilot LIMITED |
| Blender cleanup automation | PASS (scripts present; Blender 3.3 CLI smoke) |
| canonical rig | PASS (spec + validator) |
| animations | `REQUIRES_ART_PRODUCTION` (choreography authored) |
| GLB | existing procedural_final proxy only — not final VRoid art |
| Godot import | PASS for existing procedural assets |
| hitbox/hurtbox alignment | PASS hooks on current runtime |
| aura/VFX/SFX/camera hooks | PASS (juice contract + CombatFeedback deepen) |
| playable BattleScene | PASS (Wave011 accepted main) |

## Truthful flags
- `EMBER_MODEL_SOURCE=HUMAN_GUI_REQUIRED`
- `EMBER_DIGITAL_PREPARATION_PASS=true`
- `EMBER_FINAL_ART_RUNTIME_PASS=false`
"""


def main() -> int:
    env = detect_env()
    write_json(ROOT / "artifacts/engineering_wave012/ENVIRONMENT_PROBE.json", env)
    write_json(ROOT / "vendor_pins/WAVE012_TOOL_PINS.json", {
        "schema_version": 1,
        "generated_for": "engineering_wave012",
        "CORE_PIPELINE_MONETARY_COST_USD": 0,
        "pins": {
            "anyCreature": {
                "url": "https://github.com/Ariescar/anyCreature",
                "commit": ANYCREATURE_SHA,
                "license": "MIT",
                "classification": "CORE",
                "required_for_build": False,
                "role": "creatures_props_silhouette_optional_humanoid_pilot",
            },
            "mixamo-llm-mocap": {
                "url": "https://github.com/squall01337/mixamo-llm-mocap",
                "commit": MOCAP_SHA,
                "license": "MIT (README); GitHub license field NOASSERTION",
                "classification": "OPTIONAL",
                "required_for_build": False,
                "gpu_requirement": "NVIDIA ~8GB VRAM CUDA",
                "blender_requirement": "5.1+",
            },
            "sprite-sheet-creator-fal-ai": {
                "classification": "REJECTED",
                "required_for_build": False,
                "reason": "fal.ai API not permanently $0",
            },
            "Twinforge": {
                "classification": "EXPERIMENTAL_TRANSIENT_TOOL",
                "required_for_build": False,
                "reason": "Not pinned; unclear zero-cost permanence / license",
            },
        },
        "prerequisites": {
            "ANIME_ACCEPTED_MAIN_SHA": ANIME_SHA,
            "ANIME_PR_81": "MERGED",
            "FIELD_KIT_ACCEPTED_MAIN_SHA": FIELD_SHA,
            "FIELD_KIT_PR_117": "MERGED",
            "WAVE011_ACCEPTED_MAIN_STATUS": "PASS",
        },
    })

    write(ROOT / "docs/art_pipeline/FREE_TOOLCHAIN_AND_LICENSE_MATRIX.md", matrix_md())
    write(ROOT / "docs/design/CHARACTER_COMBAT_INSPIRATION_BIBLE.md", bible_md())
    write(ROOT / "docs/design/ICONIC_MOMENT_TO_ORIGINAL_MOVE_MATRIX.md", iconic_md())
    write(ROOT / "docs/design/CHOREOGRAPHY_LIBRARY.md", choreography_md())
    write(ROOT / "docs/art_pipeline/GAME_JUICE_EVENT_CONTRACT.md", juice_contract_md())
    write(ROOT / "docs/art_pipeline/CANONICAL_HUMANOID_RIG.md", canonical_rig_md())
    write(ROOT / "docs/art_pipeline/MIXAMO_USAGE_AND_PROVENANCE.md", mixamo_md())
    write(ROOT / "docs/art_pipeline/MOCAP_GPU_EXECUTION.md", mocap_gpu_md())
    write(ROOT / "docs/art_pipeline/EMBER_FREE_ART_PIPELINE_VERTICAL_SLICE.md", ember_vertical_slice_md())
    write_json(ROOT / "content/choreography/choreography_manifest.json", choreography_manifest())

    for f in FIGHTERS:
        write(
            ROOT / f"docs/art_pipeline/VRoid_FIGHTER_AUTHORING_PACKETS/{f['id']}.md",
            vroid_packet(f, detailed=(f["id"] == "ember-vale")),
        )

    write_json(ROOT / "artifacts/engineering_wave012/MOCAP_GPU_EXECUTION_PACKET.json", {
        "MIXAMO_LLM_MOCAP_EXECUTION": env["MIXAMO_LLM_MOCAP_EXECUTION"],
        "pin_url": "https://github.com/squall01337/mixamo-llm-mocap",
        "pin_commit": MOCAP_SHA,
        "integration_packet": "tools/art_pipeline/mocap/",
        "paid_cloud_gpu": False,
        "execution_attempted": False,
        "reason": env["nvidia_gpu"]["detail"],
    })

    write_json(ROOT / "content/wave012_provenance_overlay.json", {
        "schema_version": 1,
        "wave": "wave012",
        "entries": [
            {
                "id": "pipeline.docs.toolchain_matrix",
                "status": "FINAL_ORIGINAL",
                "path": "docs/art_pipeline/FREE_TOOLCHAIN_AND_LICENSE_MATRIX.md",
            },
            {
                "id": "fighter.vroid.ember-vale",
                "status": "HUMAN_GUI_REQUIRED",
                "path": "docs/art_pipeline/VRoid_FIGHTER_AUTHORING_PACKETS/ember-vale.md",
            },
            {
                "id": "pipeline.mocap.mixamo_llm",
                "status": "BLOCKED_ENVIRONMENT_GPU",
                "path": "tools/art_pipeline/mocap/",
            },
            {
                "id": "pipeline.anycreature.humanoid_pilot",
                "status": "REQUIRES_ART_PRODUCTION",
                "path": "tools/art_pipeline/anycreature_adapter/",
                "note": "Fit classification emitted at runtime; not forced as hero path",
            },
            {
                "id": "choreography.manifest",
                "status": "REQUIRES_ART_PRODUCTION",
                "path": "content/choreography/choreography_manifest.json",
            },
            {
                "id": "sprite_sheet_fal_ai",
                "status": "REQUIRES_ART_PRODUCTION",
                "path": None,
                "note": "REJECTED from CORE — fal.ai not permanently $0",
            },
        ],
    })

    print("Wave012 content generated", NOW)
    print("GPU execution:", env["MIXAMO_LLM_MOCAP_EXECUTION"])
    print("VRoid:", env["VROID_MODEL_CREATION"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
