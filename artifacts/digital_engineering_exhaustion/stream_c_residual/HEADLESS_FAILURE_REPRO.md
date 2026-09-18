# HEADLESS_FAILURE_REPRO

## Accepted main
`836bb4ace3bcb136c4cf40724b9182a627baa08c`

## Environment
- macOS 26.6.2 / arm64
- Godot `/opt/homebrew/bin/godot` → `4.7.1.stable.official.a13da4feb`
- Python 3.14.7
- Initial `.godot/`: **absent** (clean worktree)

## Exact commands

```bash
godot --version
godot --headless --path game-godot --quit-after 1
godot --headless --path game-godot -s res://tests/smoke_runner.gd
```

## Observed (clean room, no prior import)

| Step | Exit | Signal | Notes |
|------|------|--------|-------|
| version | 0 | none | 4.7.1.stable |
| `--quit-after 1` | 0 | none | Does **not** populate `.godot/imported`; emits add_child/look_at errors |
| smoke_runner | **1** | none (not -6) | Failed loading bed.wav imports + CharacterSelectShowcaseFlourish parse + (after proper import) release_mode/beta modelPath |

**Not SIGABRT/SIGSEGV.** Failure is assertion/parse/resource load (exit 1).

## Classification matrix

| Probe | Result | Class signal |
|-------|--------|--------------|
| Current `.godot/` (absent) + quit-after | smoke fail: missing `.sample` + class_name parse | STALE_IMPORT_CACHE / WRAPPER_ENVIRONMENT_DEFECT (`--quit-after` ≠ `--import`) |
| Wipe + `godot --headless --path game-godot --import` | exit 0; 212 imported; class cache has Flourish; bed.wav.sample present | Confirms import gap |
| Smoke after `--import` | exit 1; Flourish OK; audio OK; FAIL `release_mode` (missing `OS.is_debug_build()` string); FAIL `anime_beta_content` (modelPath still `*_procedural_proxy.glb`) | PROJECT_CODE_DEFECT |
| Scene lifecycle on quit-after | `add_child` busy + `look_at` not in tree from `fighter_model_3d.gd` | PROJECT_CODE_DEFECT |
| Alt Godot | only Homebrew 4.7.1 on PATH | N/A |
| `--verbose` / gl_compatibility / opengl3 | deferred (not required once root cause isolated; no crash) | — |

## Root-cause class (primary)
**PROJECT_CODE_DEFECT** (modelPath mismatch, debug HUD gate string, deferred scene-tree lifecycle)  
**plus WRAPPER_ENVIRONMENT_DEFECT** (Stream C runner treats `--quit-after 1` as full import; does not run `--import` before smoke; historically gated exhausted=true despite smoke exit 1)

## Secondary
RESOURCE_IMPORT_DEFECT only when import cache missing — wav files and `.import` sidecars exist on disk; `--import` regenerates `.godot/imported` correctly.


## Post-fix verification (clean `.godot` + `--import`)

| Step | Exit | Result |
|------|------|--------|
| `godot --import` | 0 | imports + class cache warm |
| smoke_runner | 0 | all suites passed |
| mini_soak 5x | 0×5 | no crash |
| Stream C gate | exhausted=true | rights false; quarantine true; fun HUMAN_VALIDATION_REQUIRED |

Root-cause class retained: **PROJECT_CODE_DEFECT** + **WRAPPER_ENVIRONMENT_DEFECT** (runner used `--quit-after` as import). Not SIGABRT/-6.
