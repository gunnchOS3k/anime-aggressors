import type { PlayerState } from "@anime-aggressors/game-core";
import { getMoveById } from "@anime-aggressors/game-core";
import type { AnimPose } from "./FighterAnimator.ts";
import { slotToAnimationState } from "./FighterAnimationClips.ts";

function basePose(player: PlayerState, frame: number): AnimPose {
  const t = frame * 0.08;
  const idleBob = Math.sin(t) * 0.03;
  return {
    torsoRotZ: 0,
    torsoScaleY: 1,
    headTilt: 0,
    armSwingL: 0,
    armSwingR: 0,
    legSpread: 0,
    bob: idleBob,
    auraOpacity: 0.18 + Math.sin(t * 2) * 0.06,
  };
}

function isDashMove(moveId: string): boolean {
  const move = getMoveById(moveId);
  return move?.slot === "sideSpecial" || moveId === "side_special" || moveId === "dodge";
}

function isGrabMove(moveId: string): boolean {
  const move = getMoveById(moveId);
  return move?.slot === "grab" || move?.category === "throw";
}

function isSuperMove(moveId: string): boolean {
  const move = getMoveById(moveId);
  return move?.slot === "super" || moveId === "super";
}

function isLaunchState(player: PlayerState): boolean {
  return (
    player.hitstunFrames > 0 &&
    !player.onGround &&
    player.vy < -2 * 256
  );
}

export function computeProceduralPose(player: PlayerState, frame: number): AnimPose {
  const t = frame * 0.08;
  const base = basePose(player, frame);
  const move = getMoveById(player.currentMoveId);
  const animSlot = move ? slotToAnimationState(move.slot) : undefined;

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
      if (animSlot === "upAttack") {
        base.torsoRotZ = -0.6 * player.facing;
        base.armSwingR = -1.5 * player.facing;
        base.bob = 0.12;
      } else if (animSlot === "downAttack") {
        base.torsoRotZ = 0.25 * player.facing;
        base.armSwingR = -0.8 * player.facing;
        base.bob = -0.06;
      }
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
    case "auraCharging": {
      const lvl = player.aura.level;
      base.armSwingL = 0.45 + lvl * 0.08;
      base.armSwingR = 0.45 + lvl * 0.08;
      base.torsoScaleY = 0.96;
      base.bob = Math.sin(t * 4) * 0.04;
      base.auraOpacity = 0.35 + lvl * 0.18;
      base.torsoRotZ = -0.08 * player.facing;
      break;
    }
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

  if (isDashMove(player.currentMoveId) || player.actionState === "dodging") {
    base.torsoRotZ = 0.65 * player.facing;
    base.torsoScaleY = 0.86;
    base.armSwingL = 0.2 * player.facing;
    base.armSwingR = -0.9 * player.facing;
    base.legSpread = 0.18;
    base.bob = Math.sin(t * 6) * 0.04;
    base.auraOpacity = 0.55;
  }

  if (isSuperMove(player.currentMoveId) || player.actionState === "special" && animSlot === "superActive") {
    const phase = player.actionFrame;
    if (phase < 12) {
      base.torsoRotZ = -0.2 * player.facing;
      base.armSwingR = -0.5 * player.facing;
      base.auraOpacity = 0.35 + phase * 0.03;
    } else if (phase < 32) {
      base.torsoRotZ = -0.75 * player.facing;
      base.armSwingR = -1.8 * player.facing;
      base.armSwingL = 0.9 * player.facing;
      base.auraOpacity = 0.85;
      base.bob = 0.1;
    } else {
      base.torsoRotZ = -0.3 * player.facing;
      base.armSwingR = -0.4 * player.facing;
      base.auraOpacity = 0.5;
    }
  }

  if (isGrabMove(player.currentMoveId)) {
    base.armSwingL = 0.8;
    base.armSwingR = 0.8;
    base.torsoRotZ = -0.15 * player.facing;
    base.headTilt = 0.1 * player.facing;
    base.auraOpacity = 0.4;
  }

  if (isLaunchState(player)) {
    base.torsoRotZ = 0.4 * player.facing;
    base.torsoScaleY = 1.1;
    base.armSwingL = 0.5;
    base.armSwingR = 0.5;
    base.headTilt = 0.25;
    base.bob = 0.15;
    base.auraOpacity = 0.3;
  }

  if (!player.onGround && player.actionState !== "jumping" && player.actionState !== "falling") {
    base.bob += 0.02;
  }

  if (player.fastFalling && player.actionState === "falling") {
    base.torsoScaleY = 1.12;
    base.armSwingL = 0.45;
    base.armSwingR = 0.45;
    base.bob = 0.06;
  }

  return base;
}
