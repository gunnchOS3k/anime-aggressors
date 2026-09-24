# Generated Art v8 — Rigged Costume Integrity + Impact Choreography

Keeps the v6/v7 **graphic_lowpoly_cel_combat** style lock. This pass is
structural coherence, not a new art direction.

Generated production art only. Not human-authored final art.

## Still locked

- full-body undersuits (never peach/clay)
- faceless masks / helmets / cowls
- stylized glove families
- integrated boot families
- cel shading
- no voxel remesh
- no realistic faces
- canonical skeleton, sockets, action IDs
- CombatMath / gameplay physics unchanged

## Attachment classes

Every non-body visible object is exactly one of:

- `SKINNED_COSTUME` — armature-bound shells with normalized weights
- `BONE_RIGID` — bone-parented plates with inverse + local offset
- `SECONDARY_CHAIN` — stable root (scarf / coat tails)
- `VFX_ORBIT` — intentional floating only
- `WORLD_STATIC` — ground/ref only; never fighter costume

## v8 goals

1. Costume plates stay attached in heavy / hurt / clash.
2. Juno / Kaia / Orion / Vesper read 3+ value groups without emission.
3. Heavy pairs physically meet (review-only solver; no gameplay change).
4. Hurt / charge / super / clash acting stay identity-specific.
5. Gloves and boots read at gameplay scale.
6. Digital gates describe structural prerequisites only.

## Human gates

`HUMAN_*`, `MERGE_AUTHORIZED`, and `FINAL_AUTHORED_ANIMATION_PASS` stay false
until a human actually approves.
