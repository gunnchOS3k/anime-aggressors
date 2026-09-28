# Rig control map

Deform bones: Root, Hips, Spine, Chest, Neck, Head, Shoulder/UpperArm/LowerArm/Hand L+R, UpperLeg/LowerLeg/Foot/Toes L+R.

Controls (non-export): `CTRL_FK_*`, `CTRL_IK_Hand/Foot_*`, `CTRL_PV_Elbow_*`.

| Operator | Function |
|---|---|
| select_rig | isolate AA_Deform |
| reset_pose | clear transforms |
| mirror_pose | L↔R |
| copy_pose / paste_pose | selected bones |
| set_ik_fk | 0 = FK, 1 = IK |
| snap_fk_to_ik / snap_ik_to_fk | space matching |
| foot_roll | IK foot X rotation |
| scale_cheat | hand/foot scale |
| torso_squash | Spine/Chest scale |
| shoulder_overshoot | extra Z |
| create_named_action | new action + range |
| add_contact_marker | `AA_CONTACT` |
| add_gameplay_markers | active window + contact |
| set_stepped_preview | constant interpolation |
| export_pose_thumbnail | OpenGL still |

No proprietary add-on dependency.
