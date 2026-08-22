# Free Toolchain and License Matrix

Wave012 zero-cost character / motion / juice pipeline.

Canonical machine-readable source of truth: `vendor_pins/WAVE012_TOOL_PINS.json`

- `COMPUTED_CORE_PIPELINE_MONETARY_COST_USD=0` (computed from required tools; not a trusted constant)
- `SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE=true`
- `TOOLCHAIN_MD_JSON_CONSISTENT=true` (this matrix must match JSON classifications)

Doctrine: software license, checkpoint/model license, input rights, and output rights are **separate**. Never infer production output license solely from generator software license (e.g. anyCreature MIT ≠ MIT outputs).

Pinned prerequisites:
- `ANIME_ACCEPTED_MAIN_SHA=3b01c3d3473ec5372c5c1e3126305488dc26a08a` (PR #81 MERGED; Wave011 PASS)
- `FIELD_KIT_ACCEPTED_MAIN_SHA=12f4416fee08d266b4a34fd43198094ba42ef6d1` (PR #117 MERGED; GAME-AA-001..010 accepted)

| Tool | Version / commit | URL | License / terms | Monetary cost | Account | GPU | Redistribution | Provenance | Class |
|------|------------------|-----|-----------------|---------------|---------|-----|----------------|------------|-------|
| Godot 4 | 4.5+ (CI 4.5-stable) | https://godotengine.org | MIT | $0 | none | none | yes (engine MIT) | runtime binary | CORE_RUNTIME |
| Blender | 3.3+ (local 3.3.1; target 4.x+) | https://www.blender.org | GPL-2.0-or-later / Blender license | $0 | none | none for DCC | yes for original .blend/.glb | DCC export log; software GPL ≠ content license | CORE_AUTHORING |
| VRoid Studio | current free desktop | https://vroid.com/en/studio | pixiv/VRoid ToS; item-specific | $0 software | optional pixiv for some features | none | obey item licenses; no franchise packs | human GUI export; per-item terms | CORE_AUTHORING |
| VRM Add-on for Blender | open-source VRM bridge | https://vrm-addon-for-blender.info | MIT (project) | $0 | none | none | bridge MIT; content follows source assets | bridge export log | CORE_AUTHORING |
| anyCreature | `ab5b1ce5c13e632f00f7f7cbfdb7a746e315000d` | https://github.com/Ariescar/anyCreature | Software MIT; outputs NOT inferred from MIT | $0 | none | CPU OK | only with known input/output rights | generator run log + input rights; SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE | OPTIONAL |
| Adobe Mixamo | web utility | https://www.mixamo.com | Adobe ToS; utility only | $0 where available | Adobe ID | none | **do not redistribute raw Mixamo assets** | human acquisition log | OPTIONAL |
| mixamo-llm-mocap | `00dfd5385506022d533c84f6737a09f5f4392623` | https://github.com/squall01337/mixamo-llm-mocap | MIT (README); GitHub license NOASSERTION | $0 software | free SMPL-X registration | NVIDIA ~8GB VRAM | derived original clips only after retarget + rights log | GPU mocap run log; checkpoint≠output | OPTIONAL |
| Twinforge | not pinned | n/a | unclear / time-limited | unknown | unknown | unknown | unknown | not evaluated as required | EXPERIMENTAL_TRANSIENT_TOOL |
| sprite-sheet-creator (fal.ai) | n/a | fal.ai dependent | paid API risk | not permanently $0 | API key | cloud | n/a | excluded | REJECTED |

## Required vs optional

| Flag | Value |
|------|-------|
| `MIXAMO_REQUIRED_FOR_BUILD` | false |
| `MIXAMO_REQUIRED_FOR_PIPELINE_PASS` | false |
| `MIXAMO_REQUIRED_FOR_FINAL_ART` | false |
| `VROID_REQUIRED_FOR_BUILD` | false |
| `VROID_FINAL_EXPORT_PRESENT` | false |
| `EMBER_FINAL_ART_RUNTIME_PASS` | false |

Repo build / Wave012 pipeline PASS require Godot only among pinned tools (`required_for_repo_build` / `required_for_pipeline_pass`). VRoid remains the recommended humanoid authoring path but is `HUMAN_GUI_REQUIRED` and not a CI build dependency.

## Doctrine

1. Required tools (`required_for_repo_build` or `required_for_pipeline_pass`) must remain `$0` monetary software/service fees.
2. Optional / experimental / rejected tools never gate CI PASS for CORE.
3. No copyrighted franchise assets in production.
4. Time-limited free betas = `EXPERIMENTAL_TRANSIENT_TOOL` only.
5. `COMPUTED_CORE_PIPELINE_MONETARY_COST_USD=0` is enforced by `tools/art_pipeline/check_zero_cost_dependencies.py` by summing required tool costs (not trusting a predeclared constant).
6. `SOFTWARE_LICENSE_NOT_USED_AS_OUTPUT_LICENSE=true` — software MIT/GPL does not license generated art outputs.

## Honest environment notes

See `artifacts/engineering_wave012/ENVIRONMENT_PROBE.json`.
On Apple Silicon without NVIDIA CUDA: `MIXAMO_LLM_MOCAP_EXECUTION=BLOCKED_ENVIRONMENT_GPU`.
VRoid model creation cannot be automated here: `VROID_MODEL_CREATION=HUMAN_GUI_REQUIRED`.
