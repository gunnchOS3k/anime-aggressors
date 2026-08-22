# mixamo-llm-mocap GPU Execution Packet

Pinned: https://github.com/squall01337/mixamo-llm-mocap @00dfd5385506022d533c84f6737a09f5f4392623

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
