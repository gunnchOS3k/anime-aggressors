import type { PlayerState } from "@anime-aggressors/game-core";
import type { LowPolyHumanoidParts } from "./LowPolyHumanoid.ts";
import { computeProceduralPose } from "./ProceduralPoseSystem.ts";

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
  return computeProceduralPose(player, frame);
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
