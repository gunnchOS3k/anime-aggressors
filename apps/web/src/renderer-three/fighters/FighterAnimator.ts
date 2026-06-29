import type { PlayerState } from "@anime-aggressors/game-core";
import type { LowPolyHumanoidParts } from "./LowPolyHumanoid.ts";
import type { FighterPose } from "./FighterPose.ts";
import { computeFighterLimbPose, strikeSideForClip, clipForPlayer } from "./FighterAnimationController.ts";
import { humanoidToRig } from "./FighterRigParts.ts";
import { applyPoseToRig, getStrikeAnchor } from "./LowPolyFighterRig.ts";
import { clipUsesLimbs } from "./fightingAnimationClips.ts";

export type AnimPose = FighterPose;

export function computeFighterPose(player: PlayerState, frame: number): FighterPose {
  return computeFighterLimbPose(player, frame);
}

export function applyFighterPose(parts: LowPolyHumanoidParts, pose: FighterPose, facing: 1 | -1): void {
  const rig = humanoidToRig(parts);
  applyPoseToRig(rig, pose, facing);
}

export function getFighterStrikeAnchor(parts: LowPolyHumanoidParts, player: PlayerState, frame: number) {
  const clipId = clipForPlayer(player);
  const side = strikeSideForClip(clipId);
  return getStrikeAnchor(humanoidToRig(parts), side);
}

export function attackAnimationUsesLimbs(player: PlayerState): boolean {
  return clipUsesLimbs(clipForPlayer(player));
}
