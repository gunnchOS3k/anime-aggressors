import type * as THREE from "three";
import type { LowPolyHumanoidParts } from "./LowPolyHumanoid.ts";

export type FighterRigParts = LowPolyHumanoidParts & {
  hips: THREE.Group;
  leftUpperArm: THREE.Object3D;
  rightUpperArm: THREE.Object3D;
  leftForearm: THREE.Object3D;
  rightForearm: THREE.Object3D;
  leftHand: THREE.Object3D;
  rightHand: THREE.Object3D;
  leftUpperLeg: THREE.Object3D;
  rightUpperLeg: THREE.Object3D;
  leftLowerLeg: THREE.Object3D;
  rightLowerLeg: THREE.Object3D;
  leftFoot: THREE.Object3D;
  rightFoot: THREE.Object3D;
  auraEmitter: THREE.Object3D;
};

export function humanoidToRig(parts: LowPolyHumanoidParts): FighterRigParts {
  const findExtra = (name: string) => parts.extras.find((e) => e.name === name || e.uuid === name);
  const handL = parts.extras.find((e) => e.position.x < 0 && e.position.y < 1.2) ?? parts.leftArm;
  const handR = parts.extras.find((e) => e.position.x > 0 && e.position.y < 1.2) ?? parts.rightArm;
  const footL = parts.extras.find((e) => e.position.x < 0 && e.position.y < 0.2) ?? parts.leftLeg;
  const footR = parts.extras.find((e) => e.position.x > 0 && e.position.y < 0.2) ?? parts.rightLeg;

  return {
    ...parts,
    hips: parts.root,
    leftUpperArm: parts.leftArm,
    rightUpperArm: parts.rightArm,
    leftForearm: handL,
    rightForearm: handR,
    leftHand: handL,
    rightHand: handR,
    leftUpperLeg: parts.leftLeg,
    rightUpperLeg: parts.rightLeg,
    leftLowerLeg: footL,
    rightLowerLeg: footR,
    leftFoot: footL,
    rightFoot: footR,
    auraEmitter: parts.aura,
  };
}

export function listLimbPartNames(): string[] {
  return [
    "root",
    "hips",
    "torso",
    "head",
    "leftUpperArm",
    "leftForearm",
    "rightUpperArm",
    "rightForearm",
    "leftHand",
    "rightHand",
    "leftUpperLeg",
    "leftLowerLeg",
    "rightUpperLeg",
    "rightLowerLeg",
    "leftFoot",
    "rightFoot",
  ];
}
