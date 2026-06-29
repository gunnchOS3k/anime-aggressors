export type TransformSpec = {
  x?: number;
  y?: number;
  z?: number;
  rotationX?: number;
  rotationY?: number;
  rotationZ?: number;
  scaleX?: number;
  scaleY?: number;
  scaleZ?: number;
};

export type FighterPose = {
  root?: TransformSpec;
  hips?: TransformSpec;
  torso?: TransformSpec;
  head?: TransformSpec;
  leftUpperArm?: TransformSpec;
  leftForearm?: TransformSpec;
  rightUpperArm?: TransformSpec;
  rightForearm?: TransformSpec;
  leftHand?: TransformSpec;
  rightHand?: TransformSpec;
  leftUpperLeg?: TransformSpec;
  leftLowerLeg?: TransformSpec;
  rightUpperLeg?: TransformSpec;
  rightLowerLeg?: TransformSpec;
  leftFoot?: TransformSpec;
  rightFoot?: TransformSpec;
  accentParts?: Record<string, TransformSpec>;
  auraOpacity?: number;
  /** Legacy procedural fields mapped to limbs in applyPoseToRig. */
  torsoRotZ?: number;
  torsoScaleY?: number;
  headTilt?: number;
  armSwingL?: number;
  armSwingR?: number;
  legSpread?: number;
  bob?: number;
};

export function emptyPose(): FighterPose {
  return { auraOpacity: 0.2 };
}

export function mergePose(base: FighterPose, partial: FighterPose): FighterPose {
  return {
    ...base,
    ...partial,
    accentParts: { ...base.accentParts, ...partial.accentParts },
  };
}
