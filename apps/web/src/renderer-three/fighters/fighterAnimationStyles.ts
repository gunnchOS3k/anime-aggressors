import type { FighterPose } from "./FighterPose.ts";
import { mergePose } from "./FighterPose.ts";

export type FighterAnimationStyleId =
  | "ember-vale"
  | "rook-ironside"
  | "juno-spark"
  | "kaia-windrow"
  | "nix-calder"
  | "orion-vell"
  | "vesper-nyx"
  | "default";

export type StyleModifiers = {
  armSwingScale: number;
  legKickScale: number;
  torsoTwistScale: number;
  dashLean: number;
  jumpArmLift: number;
  auraPulse: number;
};

const STYLES: Record<FighterAnimationStyleId, StyleModifiers> = {
  "ember-vale": { armSwingScale: 1.15, legKickScale: 0.95, torsoTwistScale: 1.1, dashLean: 1.1, jumpArmLift: 1.0, auraPulse: 1.2 },
  "rook-ironside": { armSwingScale: 1.35, legKickScale: 1.2, torsoTwistScale: 0.85, dashLean: 0.8, jumpArmLift: 0.75, auraPulse: 0.9 },
  "juno-spark": { armSwingScale: 1.25, legKickScale: 1.15, torsoTwistScale: 1.2, dashLean: 1.25, jumpArmLift: 1.15, auraPulse: 1.3 },
  "kaia-windrow": { armSwingScale: 1.05, legKickScale: 1.0, torsoTwistScale: 1.15, dashLean: 1.05, jumpArmLift: 1.1, auraPulse: 1.0 },
  "nix-calder": { armSwingScale: 0.95, legKickScale: 1.05, torsoTwistScale: 0.75, dashLean: 0.7, jumpArmLift: 0.8, auraPulse: 0.85 },
  "orion-vell": { armSwingScale: 1.0, legKickScale: 0.9, torsoTwistScale: 0.9, dashLean: 0.85, jumpArmLift: 0.95, auraPulse: 1.1 },
  "vesper-nyx": { armSwingScale: 1.1, legKickScale: 1.05, torsoTwistScale: 1.25, dashLean: 1.15, jumpArmLift: 1.05, auraPulse: 1.15 },
  default: { armSwingScale: 1, legKickScale: 1, torsoTwistScale: 1, dashLean: 1, jumpArmLift: 1, auraPulse: 1 },
};

export function styleIdFromCharacter(characterId: string): FighterAnimationStyleId {
  const id = characterId.replace(/^created:/, "");
  if (id in STYLES) return id as FighterAnimationStyleId;
  return "default";
}

export function applyStyleToPose(pose: FighterPose, styleId: FighterAnimationStyleId): FighterPose {
  const s = STYLES[styleId] ?? STYLES.default;
  const scaleRot = (part?: FighterPose["leftUpperArm"], arm = false, leg = false) =>
    part
      ? {
          ...part,
          rotationX: part.rotationX !== undefined ? part.rotationX * (arm ? s.armSwingScale : leg ? s.legKickScale : 1) : undefined,
          rotationZ: part.rotationZ !== undefined ? part.rotationZ * s.torsoTwistScale : undefined,
        }
      : undefined;

  return mergePose(pose, {
    torso: pose.torso?.rotationZ !== undefined ? { rotationZ: (pose.torso.rotationZ ?? 0) * s.torsoTwistScale } : pose.torso,
    leftUpperArm: scaleRot(pose.leftUpperArm, true, false),
    rightUpperArm: scaleRot(pose.rightUpperArm, true, false),
    leftUpperLeg: scaleRot(pose.leftUpperLeg, false, true),
    rightUpperLeg: scaleRot(pose.rightUpperLeg, false, true),
    rightFoot: scaleRot(pose.rightFoot, false, true),
    auraOpacity: pose.auraOpacity !== undefined ? Math.min(1, pose.auraOpacity * s.auraPulse) : undefined,
  });
}

export function listStyledFighterIds(): FighterAnimationStyleId[] {
  return Object.keys(STYLES).filter((k) => k !== "default") as FighterAnimationStyleId[];
}
