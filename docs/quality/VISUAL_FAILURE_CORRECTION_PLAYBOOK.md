# Visual Failure Correction Playbook

Paired with GoldenVisualQA. When a capture fails image and/or semantic checks, classify with the taxonomy below and follow the diagnostic steps. Machine-readable twin: [`artifacts/visual_qa/correction_playbook.json`](../../artifacts/visual_qa/correction_playbook.json).

## Taxonomy

| Class | Severity | First look |
| --- | --- | --- |
| `MISSING_MODEL` | S0 | Cache / viewport / generation race |
| `WRONG_FIGHTER` | S0 | Focus vs fighter_id binding |
| `LEGACY_MODEL` | S1 | Asset path / representation audit |
| `MATERIAL_WHITEOUT` | S0 | Shared GLB materials / override / witness |
| `MATERIAL_GRAYSCALE` | S1 | Palette / modulate collapse |
| `WRONG_PALETTE` | S1 | Cross-fighter material reuse |
| `OVERSCALE` | S0 | PresentationContext display contract leak |
| `UNDERSCALE` | S1 | Wrong contract / camera_size |
| `OFFSCREEN` | S0 | Bounds vs target region |
| `STAGE_CLIP` | S1 | Battle scale / feet contact |
| `CAMERA_FIT` | S1 | BattleCameraController |
| `MOVE_PREVIEW_OVERFLOW` | S1 | MOVE_PREVIEW contract |
| `UI_CLIP` / `UI_OFFSCREEN` | S1 | Safe area / anchors |
| `FOCUS_NOT_VISIBLE` | S1 | Select focus chrome |
| `STALE_INSTANCE` | S0 | Shared SubViewport / generation |
| `CONTEXT_STATE_LEAK` | S0 | Cross-context scale/material leak |

## Example chains

### OVERSCALE

1. Inspect `PresentationContext`
2. Inspect display contract for the active context
3. Inspect camera framing
4. Verify model root scale remains `Vector3.ONE`
5. Inspect cross-context state leak
6. Run `make wave020-transform-isolation-diagnostic`

### MATERIAL_WHITEOUT

1. Inspect material fingerprint / luma / whiteout mesh count
2. Inspect shared resources vs localized duplicates
3. Inspect `material_override`
4. Inspect witness instrumentation (must stay non-invasive)
5. Inspect card/victory bake
6. Run `make wave020-material-persistence-diagnostic`

## Rules

- Do not weaken visibility counters to green a gate.
- Do not use stick/block proxies as substitutes for body presence.
- Prefer short gates before long soak.
- Owner taste / model presentation approvals remain human.
