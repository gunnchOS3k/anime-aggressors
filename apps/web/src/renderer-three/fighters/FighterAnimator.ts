import type { PlayerState } from "@anime-aggressors/game-core";
import type { LowPolyHumanoidParts } from "./LowPolyHumanoid.ts";

export type AnimPose = {
  torsoRotZ: number;
  torsoScaleY: number;
  headTilt: number;
  armSwingL: number;
  armSwingR: number;
  legSpread: number;
  bob: number;
  auraOpacity: number;
};

export function computeFighterPose(player: PlayerState, frame: number): AnimPose {
  const t = frame * 0.08;
  const idleBob = Math.sin(t) * 0.03;
  const base: AnimPose = {
    torsoRotZ: 0,
    torsoScaleY: 1,
    headTilt: 0,
    armSwingL: 0,
    armSwingR: 0,
    legSpread: 0,
    bob: idleBob,
    auraOpacity: 0.18 + Math.sin(t * 2) * 0.06,
  };

  switch (player.actionState) {
    case "running":
      base.armSwingL = Math.sin(t * 3) * 0.5;
      base.armSwingR = -base.armSwingL;
      base.legSpread = Math.sin(t * 3) * 0.12;
      base.bob = Math.abs(Math.sin(t * 3)) * 0.05;
      break;
    case "jumping":
      base.torsoScaleY = 0.92;
      base.armSwingL = -0.35;
      base.armSwingR = -0.35;
      base.bob = 0.08;
      break;
    case "falling":
      base.torsoScaleY = 1.06;
      base.armSwingL = 0.25;
      base.armSwingR = 0.25;
      break;
    case "attacking":
      base.torsoRotZ = -0.35 * player.facing;
      base.armSwingR = -1.1 * player.facing;
      base.headTilt = -0.15 * player.facing;
      base.auraOpacity = 0.45;
      break;
    case "special":
      base.torsoRotZ = -0.55 * player.facing;
      base.armSwingR = -1.4 * player.facing;
      base.armSwingL = 0.4 * player.facing;
      base.auraOpacity = 0.65;
      break;
    case "shielding":
      base.armSwingL = 0.6;
      base.armSwingR = 0.6;
      base.auraOpacity = 0.5;
      break;
    case "dodging":
      base.torsoRotZ = 0.5 * player.facing;
      base.torsoScaleY = 0.88;
      base.auraOpacity = 0.35;
      break;
    case "hitstun":
      base.torsoRotZ = 0.25 * player.facing;
      base.headTilt = 0.2;
      base.bob = -0.05;
      break;
    case "defeated":
      base.torsoRotZ = 1.2 * player.facing;
      base.bob = -0.4;
      break;
    default:
      break;
  }

  if (!player.onGround && player.actionState !== "jumping" && player.actionState !== "falling") {
    base.bob += 0.02;
  }

  return base;
}

export function applyFighterPose(parts: LowPolyHumanoidParts, pose: AnimPose, facing: number): void {
  parts.torso.rotation.z = pose.torsoRotZ;
  parts.torso.scale.y = pose.torsoScaleY;
  parts.head.rotation.z = pose.headTilt;
  parts.leftArm.rotation.x = pose.armSwingL;
  parts.rightArm.rotation.x = pose.armSwingR;
  parts.leftLeg.position.x = -0.28 - pose.legSpread;
  parts.rightLeg.position.x = 0.28 + pose.legSpread;
  parts.root.position.y = pose.bob;
  (parts.aura.material as import("three").MeshBasicMaterial).opacity = pose.auraOpacity;
  parts.root.rotation.y = facing > 0 ? 0 : Math.PI;
}
