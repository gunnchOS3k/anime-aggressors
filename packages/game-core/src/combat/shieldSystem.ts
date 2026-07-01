import type { PlayerState } from "../types.js";
import { SHIELD_MAX } from "../constants.js";
import { getCombatMoveData } from "../moves/combatMoveData.js";
import { isMoveComplete } from "../moves.js";
import { combatMoveToFrameData } from "../moves/combatMoveData.js";

export const SHIELD_REGEN_PER_FRAME = 0.15;
export const SHIELD_BREAK_STUN_FRAMES = 40;
export const SHIELD_RELEASE_DELAY_FRAMES = 3;

export function tickShieldRegen(player: PlayerState): void {
  if (player.actionState === "shielding") return;
  if (player.shieldStunFrames > 0) return;
  if (player.actionState === "shieldBreak") return;
  if (player.shieldHealth < SHIELD_MAX) {
    player.shieldHealth = Math.min(SHIELD_MAX, player.shieldHealth + SHIELD_REGEN_PER_FRAME);
  }
}

export function releaseShield(player: PlayerState): void {
  if (player.actionState !== "shielding") return;
  player.actionState = "idle";
  player.shieldReleaseFrames = SHIELD_RELEASE_DELAY_FRAMES;
}

export function tickShieldRelease(player: PlayerState): void {
  if (player.shieldReleaseFrames > 0) player.shieldReleaseFrames -= 1;
}

export function applyShieldHit(
  defender: PlayerState,
  shieldDamage: number,
  shieldStunFrames: number,
  pushbackX: number,
): void {
  defender.shieldHealth -= shieldDamage;
  defender.vx += pushbackX;
  if (defender.shieldHealth <= 0) {
    defender.shieldHealth = 0;
    defender.actionState = "shieldBreak";
    defender.shieldStunFrames = SHIELD_BREAK_STUN_FRAMES;
    return;
  }
  defender.actionState = "shieldStun";
  defender.shieldStunFrames = shieldStunFrames;
}

export function tickShieldStun(player: PlayerState): void {
  if (player.shieldStunFrames > 0) {
    player.shieldStunFrames -= 1;
    if (player.shieldStunFrames <= 0 && player.actionState === "shieldStun") {
      player.actionState = "idle";
    }
  }
  if (player.actionState === "shieldBreak") {
    player.shieldStunFrames -= 1;
    if (player.shieldStunFrames <= 0) {
      player.actionState = "idle";
      player.shieldHealth = SHIELD_MAX * 0.5;
    }
  }
}

export function isShielding(player: PlayerState): boolean {
  return player.actionState === "shielding";
}

export function isInShieldStun(player: PlayerState): boolean {
  return player.shieldStunFrames > 0 || player.actionState === "shieldBreak";
}

export function canActDuringCombat(player: PlayerState): boolean {
  if (player.actionState === "defeated") return false;
  if (player.actionState === "hitstun") return false;
  if (player.actionState === "grabbed") return false;
  if (isInShieldStun(player)) return false;
  if (player.actionState === "throwing") return false;
  const move = getCombatMoveData(player.currentMoveId);
  if (move && (player.actionState === "attacking" || player.actionState === "special")) {
    const frameData = combatMoveToFrameData(move);
    if (!isMoveComplete(frameData, player.actionFrame)) return false;
  }
  if (player.actionState === "grabbing") {
    const grab = getCombatMoveData("grab");
    if (grab && !isMoveComplete(combatMoveToFrameData(grab), player.actionFrame)) return false;
  }
  return true;
}
