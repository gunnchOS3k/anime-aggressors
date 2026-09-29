import type * as THREE from "three";
import type { LowPolyHumanoidParts } from "./LowPolyHumanoid.ts";

export type FighterRigParts = LowPolyHumanoidParts & {
  hips: THREE.Object3D;
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

function findNamed(root: THREE.Object3D, name: string): THREE.Object3D | null {
  let found: THREE.Object3D | null = null;
  root.traverse((o) => {
    if (!found && o.name === name) found = o;
  });
  return found;
}

export function humanoidToRig(parts: LowPolyHumanoidParts): FighterRigParts {
  const root = parts.root;
  const hips = findNamed(root, "Hips") ?? parts.root;
  const leftForearm = findNamed(root, "LowerArm_L") ?? parts.leftArm;
  const rightForearm = findNamed(root, "LowerArm_R") ?? parts.rightArm;
  const leftHand = findNamed(root, "Hand_L") ?? leftForearm;
  const rightHand = findNamed(root, "Hand_R") ?? rightForearm;
  const leftLowerLeg = findNamed(root, "LowerLeg_L") ?? parts.leftLeg;
  const rightLowerLeg = findNamed(root, "LowerLeg_R") ?? parts.rightLeg;
  const leftFoot = findNamed(root, "Foot_L") ?? leftLowerLeg;
  const rightFoot = findNamed(root, "Foot_R") ?? rightLowerLeg;

  return {
    ...parts,
    hips,
    leftUpperArm: findNamed(root, "UpperArm_L") ?? parts.leftArm,
    rightUpperArm: findNamed(root, "UpperArm_R") ?? parts.rightArm,
    leftForearm,
    rightForearm,
    leftHand,
    rightHand,
    leftUpperLeg: findNamed(root, "UpperLeg_L") ?? parts.leftLeg,
    rightUpperLeg: findNamed(root, "UpperLeg_R") ?? parts.rightLeg,
    leftLowerLeg,
    rightLowerLeg,
    leftFoot,
    rightFoot,
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
