# Free Toolchain and License Matrix

Wave012 zero-cost character / motion / juice pipeline.
`CORE_PIPELINE_MONETARY_COST_USD=0`

Pinned prerequisites:
- `ANIME_ACCEPTED_MAIN_SHA=3b01c3d3473ec5372c5c1e3126305488dc26a08a` (PR #81 MERGED; Wave011 PASS)
- `FIELD_KIT_ACCEPTED_MAIN_SHA=12f4416fee08d266b4a34fd43198094ba42ef6d1` (PR #117 MERGED; GAME-AA-001..010 accepted)

| Tool | Version / commit | URL | License / terms | Monetary cost | Account | GPU | Redistribution | Provenance | Class |
|------|------------------|-----|-----------------|---------------|---------|-----|----------------|------------|-------|
| Godot 4 | 4.5+ / local 4.7.1 | https://godotengine.org | MIT | $0 | none | none | yes (engine MIT) | runtime binary | CORE |
| Blender | 3.3+ (local 3.3.1; target 4.x+) | https://www.blender.org | GPL-2.0-or-later / Blender license | $0 | none | none for DCC | yes for original .blend/.glb | DCC | CORE |
| VRoid Studio | current free desktop | https://vroid.com/en/studio | pixiv/VRoid ToS; item-specific | $0 software | free pixiv account for some features | none | obey item licenses; no franchise packs | human GUI export | CORE |
| VRM Add-on for Blender | open-source VRM bridge | https://vrm-addon-for-blender.info | MIT (project) | $0 | none | none | yes for original exports | bridge | CORE |
| anyCreature | `ab5b1ce5c13e` | https://github.com/Ariescar/anyCreature | MIT | $0 | none | CPU OK | yes (MIT outputs) | local generator | CORE (creatures/props/silhouette; humanoid pilot only) |
| Adobe Mixamo | web utility | https://www.mixamo.com | Adobe ToS; utility only | $0 where available | Adobe ID | none | **do not redistribute raw Mixamo assets** | acquisition log required | CORE (utility) |
| mixamo-llm-mocap | `00dfd5385506` | https://github.com/squall01337/mixamo-llm-mocap | MIT (README); GitHub license NOASSERTION | $0 software | free SMPL-X registration | NVIDIA ~8GB VRAM | yes for derived original clips after retarget | optional advanced motion | OPTIONAL |
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
