import * as THREE from "three";
import type { TransformSpec, FighterPose } from "./FighterPose.ts";
import type { FighterRigParts } from "./FighterRigParts.ts";

function applyTransform(target: THREE.Object3D, spec?: TransformSpec, facing = 1): void {
  if (!spec) return;
  if (spec.x !== undefined) target.position.x = spec.x * facing;
  if (spec.y !== undefined) target.position.y = spec.y;
  if (spec.z !== undefined) target.position.z = spec.z;
  if (spec.rotationX !== undefined) target.rotation.x = spec.rotationX;
  if (spec.rotationY !== undefined) target.rotation.y = spec.rotationY * facing;
  if (spec.rotationZ !== undefined) target.rotation.z = spec.rotationZ * facing;
  if (spec.scaleX !== undefined) target.scale.x = spec.scaleX;
  if (spec.scaleY !== undefined) target.scale.y = spec.scaleY;
  if (spec.scaleZ !== undefined) target.scale.z = spec.scaleZ;
}

export function applyPoseToRig(parts: FighterRigParts, pose: FighterPose, facing: 1 | -1): void {
  const expanded: FighterPose = { ...pose };
  if (pose.torsoRotZ !== undefined) {
    expanded.torso = { ...pose.torso, rotationZ: pose.torsoRotZ };
  }
  if (pose.torsoScaleY !== undefined) {
    expanded.torso = { ...expanded.torso, scaleY: pose.torsoScaleY };
  }
  if (pose.headTilt !== undefined) {
    expanded.head = { ...pose.head, rotationZ: pose.headTilt };
  }
  if (pose.armSwingL !== undefined) {
    expanded.leftUpperArm = { ...pose.leftUpperArm, rotationX: pose.armSwingL };
  }
  if (pose.armSwingR !== undefined) {
    expanded.rightUpperArm = { ...pose.rightUpperArm, rotationX: pose.armSwingR };
  }
  if (pose.legSpread !== undefined) {
    expanded.leftUpperLeg = { ...pose.leftUpperLeg, x: -pose.legSpread };
    expanded.rightUpperLeg = { ...pose.rightUpperLeg, x: pose.legSpread };
  }
  if (pose.bob !== undefined) {
    expanded.root = { ...pose.root, y: (pose.root?.y ?? 0) + pose.bob };
  }

  parts.root.rotation.y = facing > 0 ? 0 : Math.PI;
  applyTransform(parts.root, expanded.root, facing);
  applyTransform(parts.hips, expanded.hips, facing);
  applyTransform(parts.torso, expanded.torso, facing);
  applyTransform(parts.head, expanded.head, facing);
  applyTransform(parts.leftUpperArm, expanded.leftUpperArm, facing);
  applyTransform(parts.leftForearm, expanded.leftForearm, facing);
  applyTransform(parts.rightUpperArm, expanded.rightUpperArm, facing);
  applyTransform(parts.rightForearm, expanded.rightForearm, facing);
  applyTransform(parts.leftHand, expanded.leftHand, facing);
  applyTransform(parts.rightHand, expanded.rightHand, facing);
  applyTransform(parts.leftUpperLeg, expanded.leftUpperLeg, facing);
  applyTransform(parts.leftLowerLeg, expanded.leftLowerLeg, facing);
  applyTransform(parts.rightUpperLeg, expanded.rightUpperLeg, facing);
  applyTransform(parts.rightLowerLeg, expanded.rightLowerLeg, facing);
  applyTransform(parts.leftFoot, expanded.leftFoot, facing);
  applyTransform(parts.rightFoot, expanded.rightFoot, facing);

  if (expanded.auraOpacity !== undefined) {
    const mat = parts.aura.material as THREE.MeshBasicMaterial;
    mat.opacity = expanded.auraOpacity;
  }
}

export function getStrikeAnchor(parts: FighterRigParts, side: "left" | "right" | "foot"): THREE.Vector3 {
  const anchor = new THREE.Vector3();
  const obj =
    side === "left"
      ? parts.leftHand
      : side === "right"
        ? parts.rightHand
        : parts.rightFoot;
  obj.getWorldPosition(anchor);
  return anchor;
}
