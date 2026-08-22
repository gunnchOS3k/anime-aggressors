# Blender apply / export (mixamo-llm-mocap)

When `MIXAMO_LLM_MOCAP_EXECUTION` is not blocked:

1. Open Mixamo rig profile scene.
2. Apply FK clip via project scripts (`apply_mixamo_fk.py` from pinned repo).
3. Export GLB to `art_source/mocap_derived/` (not production).
4. Run originality / root-motion policy.
5. Promote only after provenance + QA PASS.

On this host: **BLOCKED_ENVIRONMENT_GPU** — do not fake outputs.
