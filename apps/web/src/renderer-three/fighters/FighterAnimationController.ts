import type { PlayerState, DerbyPlayerState, CreatedFighter } from "@anime-aggressors/game-core";
import { getMoveById, createDefaultAuraState } from "@anime-aggressors/game-core";
import type { FighterPose } from "./FighterPose.ts";
import { emptyPose, mergePose } from "./FighterPose.ts";
import { FIGHTING_ANIMATION_CLIPS, sampleClip, type AnimationClipId } from "./fightingAnimationClips.ts";
import { applyStyleToPose, styleIdFromCharacter } from "./fighterAnimationStyles.ts";
import { slotToAnimationState } from "./FighterAnimationClips.ts";
import { applyIdleFlavorToPose } from "./idleAnimations.ts";

export function clipForPlayer(player: PlayerState): AnimationClipId {
  if (player.actionState === "auraCharging") return "auraCharge";
  if (player.actionState === "shielding") return "shield";
  if (player.actionState === "dodging") return "dash";
  if (player.actionState === "defeated") return "defeat";
  if (player.hitstunFrames > 0 && !player.onGround && player.vy < -2 * 256) return "launch";
  if (player.hitstunFrames > 0) return player.hitstunFrames > 18 ? "hitstunHeavy" : "hitstunLight";
  if (player.actionState === "jumping" && player.jumpsUsed >= 2) return "doubleJump";
  if (player.actionState === "jumping") return "groundJump";
  if (player.actionState === "falling" && player.fastFalling) return "fastFall";
  if (player.actionState === "falling") return "fall";
  if (player.actionState === "running") return "run";
  if (player.actionState === "attacking" || player.actionState === "special") {
    const move = getMoveById(player.currentMoveId);
    const slot = move?.slot;
    if (slot === "super") return player.actionFrame < 12 ? "superStartup" : "superActive";
    if (slot === "neutralAttack") return "neutralAttack";
    if (slot === "sideAttack") return "sideAttack";
    if (slot === "upAttack") return "upAttack";
    if (slot === "downAttack") return "downAttack";
    if (slot === "neutralSpecial") return "neutralSpecial";
    if (slot === "sideSpecial") return "sideSpecial";
    if (slot === "upSpecial") return "upSpecial";
    if (slot === "downSpecial") return "downSpecial";
    if (player.currentMoveId.includes("up")) return "upAttack";
    if (player.currentMoveId.includes("down")) return "downAttack";
    if (player.currentMoveId.includes("forward") || player.currentMoveId.includes("side")) return "sideAttack";
    if (!player.onGround) return "neutralAttack";
    return "neutralAttack";
  }
  return "idle";
}

export function derbyPlayerToAnimationState(player: DerbyPlayerState, fighter: CreatedFighter): PlayerState {
  const jumpsUsed = Math.max(0, 2 - player.jumpsRemaining);
  return {
    id: 0,
    characterId: `created:${fighter.id}`,
    fighterName: fighter.name,
    fighterSize: fighter.size,
    fighterColor: fighter.color,
    elementEffect: fighter.element,
    burnFramesRemaining: 0,
    slowFramesRemaining: 0,
    slowMultiplierFp: 100,
    airDriftBonusFrames: 0,
    x: player.x,
    y: player.y,
    vx: player.vx,
    vy: player.vy,
    facing: player.facing,
    damage: 0,
    stocks: 3,
    staminaHp: 0,
    maxStaminaHp: 0,
    score: 0,
    teamId: 0,
    actionState: player.actionState,
    actionFrame: player.actionFrame,
    hitstunFrames: 0,
    shieldHealth: player.shieldHealth,
    jumpsRemaining: player.jumpsRemaining,
    jumpsUsed,
    jumpHoldFrames: 0,
    wasJumpHeld: false,
    onGround: player.onGround,
    invulnFrames: 0,
    coyoteFrames: 0,
    jumpBufferFrames: 0,
    fastFalling: player.fastFalling,
    currentMoveId:
      player.actionState === "attacking"
        ? "neutral_attack"
        : player.actionState === "special"
          ? "neutral_special"
          : "none",
    hitVictimsThisMove: [],
    currentPlatformId: "",
    dropThroughFrames: 0,
    ignoredPlatformId: "",
    aura: createDefaultAuraState(),
  };
}

export function computeFighterLimbPose(player: PlayerState, frame: number): FighterPose {
  const clipId = clipForPlayer(player);
  const clip = FIGHTING_ANIMATION_CLIPS[clipId];
  const localFrame = player.actionState === "attacking" || player.actionState === "special" ? player.actionFrame : frame % clip.length;
  let pose = sampleClip(clip, localFrame);
  if (clipId === "idle") {
    pose = applyIdleFlavorToPose(pose, player.characterId, frame);
  }
  const styleId = styleIdFromCharacter(player.characterId);
  pose = applyStyleToPose(pose, styleId);
  const bob = Math.sin(frame * 0.08) * 0.03;
  return mergePose(pose, { root: { y: bob } });
}

export function strikeSideForClip(clipId: AnimationClipId): "left" | "right" | "foot" {
  if (clipId === "downAttack") return "foot";
  if (clipId === "sideAttack") return "right";
  return "right";
}

export { slotToAnimationState };
