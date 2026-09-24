# Blender Control Rig — Tooling Only

Python in `tools/authored_animation/blender/` **configures tools**. It does not manufacture final acting.

## Layers

| Layer | Contents | Export? |
|-------|----------|---------|
| 0 Deform | Canonical 22-bone set + optional twist | Yes |
| 1 FK controls | `CTRL_FK_*` copy-rotation onto deform | No |
| 2 IK controls | `CTRL_IK_Hand_*`, `CTRL_IK_Foot_*`, pole `CTRL_PV_*` | No |
| 3 Mech | `MCH_*` stretch / aim helpers | No |
| 4 Sockets | Empty markers parented to deform | Markers yes, as named empties |
| 5 Secondary | Hair / cape / cloth chains | Optional deform only |

## IK / FK

- Default: FK on arms and legs for pose-blocking.
- IK snap operators exist for plant / contact.
- Switch is a custom property on `CTRL_IK_*` (`ik_fk_blend` 0–1).
- Pipeline-proof exports bake **deform bones only**.

## What automation may key

- Rest / A-pose
- A short `pipeline_proof` pose-block (3–4 keys) labeled `AUTHORED_WIP`
- Socket marker placement

## What automation may not key

- Full Wave A hero performances claimed as authored-complete
- Hundreds of scripted keys labeled `AUTHORED_APPROVED`
- Any `HUMAN_*` gate
