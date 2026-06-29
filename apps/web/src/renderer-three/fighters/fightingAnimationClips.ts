import type { FighterPose } from "./FighterPose.ts";
import { mergePose, emptyPose } from "./FighterPose.ts";

export type AnimationClipId =
  | "idle"
  | "walk"
  | "run"
  | "dash"
  | "groundJump"
  | "doubleJump"
  | "fall"
  | "fastFall"
  | "land"
  | "neutralAttack"
  | "sideAttack"
  | "upAttack"
  | "downAttack"
  | "neutralSpecial"
  | "sideSpecial"
  | "upSpecial"
  | "downSpecial"
  | "auraCharge"
  | "superStartup"
  | "superActive"
  | "hitstunLight"
  | "hitstunHeavy"
  | "tumble"
  | "launch"
  | "shield"
  | "dodge"
  | "grab"
  | "throwForward"
  | "victory"
  | "defeat";

export type AnimationKeyframe = { frame: number; pose: FighterPose };

export type FightingAnimationClip = {
  id: AnimationClipId;
  length: number;
  keyframes: AnimationKeyframe[];
};

function lerpPose(a: FighterPose, b: FighterPose, t: number): FighterPose {
  const mix = (va?: number, vb?: number) =>
    va === undefined && vb === undefined ? undefined : (va ?? 0) + ((vb ?? 0) - (va ?? 0)) * t;
  const part = (pa?: FighterPose["torso"], pb?: FighterPose["torso"]) =>
    pa || pb
      ? {
          rotationX: mix(pa?.rotationX, pb?.rotationX),
          rotationY: mix(pa?.rotationY, pb?.rotationY),
          rotationZ: mix(pa?.rotationZ, pb?.rotationZ),
          x: mix(pa?.x, pb?.x),
          y: mix(pa?.y, pb?.y),
          z: mix(pa?.z, pb?.z),
        }
      : undefined;

  return {
    root: part(a.root, b.root),
    torso: part(a.torso, b.torso),
    head: part(a.head, b.head),
    leftUpperArm: part(a.leftUpperArm, b.leftUpperArm),
    leftForearm: part(a.leftForearm, b.leftForearm),
    rightUpperArm: part(a.rightUpperArm, b.rightUpperArm),
    rightForearm: part(a.rightForearm, b.rightForearm),
    leftHand: part(a.leftHand, b.leftHand),
    rightHand: part(a.rightHand, b.rightHand),
    leftUpperLeg: part(a.leftUpperLeg, b.leftUpperLeg),
    leftLowerLeg: part(a.leftLowerLeg, b.leftLowerLeg),
    rightUpperLeg: part(a.rightUpperLeg, b.rightUpperLeg),
    rightLowerLeg: part(a.rightLowerLeg, b.rightLowerLeg),
    leftFoot: part(a.leftFoot, b.leftFoot),
    rightFoot: part(a.rightFoot, b.rightFoot),
    auraOpacity: mix(a.auraOpacity, b.auraOpacity),
  };
}

export function sampleClip(clip: FightingAnimationClip, frame: number): FighterPose {
  const f = Math.max(0, Math.min(clip.length - 1, frame));
  let prev = clip.keyframes[0]!;
  for (const kf of clip.keyframes) {
    if (kf.frame <= f) prev = kf;
    else {
      const t = (f - prev.frame) / Math.max(1, kf.frame - prev.frame);
      return lerpPose(prev.pose, kf.pose, t);
    }
  }
  return prev.pose;
}

const neutralAttack: FightingAnimationClip = {
  id: "neutralAttack",
  length: 18,
  keyframes: [
    { frame: 0, pose: { rightUpperArm: { rotationX: 0.4 }, leftUpperArm: { rotationX: -0.2 }, torso: { rotationZ: -0.08 } } },
    { frame: 4, pose: { rightUpperArm: { rotationX: -1.1 }, rightForearm: { rotationX: -0.5 }, torso: { rotationZ: -0.25 }, leftUpperArm: { rotationX: 0.35 } } },
    { frame: 7, pose: { rightUpperArm: { rotationX: -1.6 }, rightForearm: { rotationX: -0.2 }, rightHand: { z: 0.35 }, torso: { rotationZ: -0.4 } } },
    { frame: 17, pose: { rightUpperArm: { rotationX: -0.2 }, torso: { rotationZ: 0 } } },
  ],
};

const sideAttack: FightingAnimationClip = {
  id: "sideAttack",
  length: 20,
  keyframes: [
    { frame: 0, pose: { rightUpperLeg: { x: 0.05 }, leftUpperLeg: { x: -0.08 } } },
    { frame: 5, pose: { rightUpperArm: { rotationX: -0.8, rotationZ: -0.5 }, torso: { rotationZ: -0.35 }, rightUpperLeg: { x: 0.18 } } },
    { frame: 9, pose: { rightUpperArm: { rotationX: -1.5, rotationZ: -0.9 }, rightForearm: { rotationX: -0.4 }, torso: { rotationZ: -0.55 }, leftFoot: { x: -0.1 } } },
    { frame: 19, pose: {} },
  ],
};

const upAttack: FightingAnimationClip = {
  id: "upAttack",
  length: 18,
  keyframes: [
    { frame: 0, pose: { leftUpperLeg: { rotationX: 0.25 }, rightUpperLeg: { rotationX: 0.25 } } },
    { frame: 5, pose: { rightUpperArm: { rotationX: -2.0 }, leftUpperArm: { rotationX: -1.7 }, torso: { rotationZ: -0.2, y: 0.08 } } },
    { frame: 10, pose: { rightUpperArm: { rotationX: -2.4 }, rightForearm: { rotationX: -0.3 }, head: { rotationX: -0.15 } } },
    { frame: 17, pose: {} },
  ],
};

const downAttack: FightingAnimationClip = {
  id: "downAttack",
  length: 16,
  keyframes: [
    { frame: 0, pose: { torso: { y: -0.08 }, leftUpperLeg: { rotationX: 0.4 }, rightUpperLeg: { rotationX: 0.4 } } },
    { frame: 6, pose: { rightUpperArm: { rotationX: 0.9 }, leftUpperArm: { rotationX: 0.8 }, rightUpperLeg: { rotationX: -0.6, z: 0.2 } } },
    { frame: 10, pose: { rightFoot: { rotationX: -0.5, z: 0.35 }, leftFoot: { rotationX: -0.4 } } },
    { frame: 15, pose: {} },
  ],
};

const groundJump: FightingAnimationClip = {
  id: "groundJump",
  length: 12,
  keyframes: [
    { frame: 0, pose: { leftUpperLeg: { rotationX: 0.35 }, rightUpperLeg: { rotationX: 0.35 }, root: { y: -0.05 } } },
    { frame: 3, pose: { leftUpperArm: { rotationX: -0.7 }, rightUpperArm: { rotationX: -0.7 }, root: { y: 0.12 }, leftUpperLeg: { rotationX: -0.2 } } },
    { frame: 11, pose: { leftUpperArm: { rotationX: -0.35 }, rightUpperArm: { rotationX: -0.35 } } },
  ],
};

const doubleJump: FightingAnimationClip = {
  id: "doubleJump",
  length: 10,
  keyframes: [
    { frame: 0, pose: { torso: { rotationZ: 0.25 }, leftUpperArm: { rotationX: -1.2 }, rightUpperArm: { rotationX: -1.2 }, root: { y: 0.08 } } },
    { frame: 4, pose: { torso: { rotationZ: -0.15 }, leftUpperLeg: { rotationX: 0.3 }, rightUpperLeg: { rotationX: -0.2 }, root: { y: 0.16 } } },
    { frame: 9, pose: { leftUpperArm: { rotationX: -0.4 }, rightUpperArm: { rotationX: -0.4 } } },
  ],
};

const hitstunHeavy: FightingAnimationClip = {
  id: "hitstunHeavy",
  length: 14,
  keyframes: [
    { frame: 0, pose: { torso: { rotationZ: 0.45 }, head: { rotationZ: 0.2 }, leftUpperArm: { rotationX: 0.8 }, rightUpperArm: { rotationX: 0.5 } } },
    { frame: 13, pose: { torso: { rotationZ: 0.2 }, leftUpperArm: { rotationX: 0.3 } } },
  ],
};

const launch: FightingAnimationClip = {
  id: "launch",
  length: 20,
  keyframes: [
    { frame: 0, pose: { torso: { rotationZ: 0.8 }, leftUpperArm: { rotationX: 1.2 }, rightUpperArm: { rotationX: 0.9 }, leftUpperLeg: { rotationX: -0.5 } } },
    { frame: 19, pose: { torso: { rotationZ: 1.4 }, head: { rotationZ: 0.3 } } },
  ],
};

const auraCharge: FightingAnimationClip = {
  id: "auraCharge",
  length: 24,
  keyframes: [
    { frame: 0, pose: { leftUpperArm: { rotationX: 0.5 }, rightUpperArm: { rotationX: 0.5 }, leftFoot: { x: -0.05 }, rightFoot: { x: 0.05 } } },
    { frame: 12, pose: { leftUpperArm: { rotationX: 0.9, rotationZ: 0.3 }, rightUpperArm: { rotationX: 0.9, rotationZ: -0.3 }, torso: { y: -0.03 }, auraOpacity: 0.65 } },
    { frame: 23, pose: { leftForearm: { rotationX: -0.4 }, rightForearm: { rotationX: -0.4 }, auraOpacity: 0.8 } },
  ],
};

export const FIGHTING_ANIMATION_CLIPS: Record<AnimationClipId, FightingAnimationClip> = {
  idle: { id: "idle", length: 1, keyframes: [{ frame: 0, pose: emptyPose() }] },
  walk: { id: "walk", length: 1, keyframes: [{ frame: 0, pose: { leftUpperArm: { rotationX: 0.4 }, rightUpperArm: { rotationX: -0.4 } } }] },
  run: { id: "run", length: 1, keyframes: [{ frame: 0, pose: { leftUpperArm: { rotationX: 0.65 }, rightUpperArm: { rotationX: -0.65 }, leftUpperLeg: { rotationX: 0.2 } } }] },
  dash: { id: "dash", length: 1, keyframes: [{ frame: 0, pose: { torso: { rotationZ: 0.5 }, rightUpperArm: { rotationX: -0.9 }, leftUpperLeg: { x: -0.1 } } }] },
  groundJump,
  doubleJump,
  fall: { id: "fall", length: 1, keyframes: [{ frame: 0, pose: { leftUpperArm: { rotationX: 0.35 }, rightUpperArm: { rotationX: 0.35 }, torso: { scaleY: 1.05 } } }] },
  fastFall: { id: "fastFall", length: 1, keyframes: [{ frame: 0, pose: { torso: { rotationZ: 0.15 }, leftUpperArm: { rotationX: 0.9 }, rightUpperArm: { rotationX: 0.9 } } }] },
  land: { id: "land", length: 1, keyframes: [{ frame: 0, pose: { leftUpperLeg: { rotationX: 0.25 }, rightUpperLeg: { rotationX: 0.25 }, root: { y: -0.04 } } }] },
  neutralAttack,
  sideAttack,
  upAttack,
  downAttack,
  neutralSpecial: neutralAttack,
  sideSpecial: sideAttack,
  upSpecial: upAttack,
  downSpecial: downAttack,
  auraCharge,
  superStartup: { id: "superStartup", length: 24, keyframes: [{ frame: 0, pose: {} }, { frame: 12, pose: { leftUpperArm: { rotationX: -1.2 }, rightUpperArm: { rotationX: -1.2 }, auraOpacity: 0.9 } }] },
  superActive: { id: "superActive", length: 18, keyframes: [{ frame: 0, pose: { rightUpperArm: { rotationX: -2 }, torso: { rotationZ: -0.5 }, auraOpacity: 1 } }] },
  hitstunLight: hitstunHeavy,
  hitstunHeavy,
  tumble: launch,
  launch,
  shield: { id: "shield", length: 1, keyframes: [{ frame: 0, pose: { leftUpperArm: { rotationX: 0.9 }, rightUpperArm: { rotationX: 0.9 } } }] },
  dodge: { id: "dodge", length: 1, keyframes: [{ frame: 0, pose: { torso: { rotationZ: 0.7 }, rightUpperLeg: { x: 0.15 } } }] },
  grab: { id: "grab", length: 1, keyframes: [{ frame: 0, pose: { rightUpperArm: { rotationX: -0.6 }, leftUpperArm: { rotationX: -0.4 } } }] },
  throwForward: sideAttack,
  victory: { id: "victory", length: 1, keyframes: [{ frame: 0, pose: { rightUpperArm: { rotationX: -2.2 }, leftUpperArm: { rotationX: -0.3 } } }] },
  defeat: { id: "defeat", length: 1, keyframes: [{ frame: 0, pose: { torso: { rotationZ: 1.2 }, root: { y: -0.35 } } }] },
};

export function clipUsesLimbs(clipId: AnimationClipId): boolean {
  const clip = FIGHTING_ANIMATION_CLIPS[clipId];
  return clip.keyframes.some((kf) =>
    !!(kf.pose.leftUpperArm || kf.pose.rightUpperArm || kf.pose.leftUpperLeg || kf.pose.rightFoot),
  );
}
