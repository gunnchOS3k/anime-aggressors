import type { InputFrame, PlayerState } from "../types.js";
import { FP_SCALE } from "../constants.js";
import { getCombatMoveData } from "../moves/combatMoveData.js";
import { combatMoveToFrameData } from "../moves/combatMoveData.js";
import { isInActive } from "../frameData.js";
import { isMoveComplete } from "../moves.js";
import { computeDashSpeed } from "../movement/applyMovement.js";

export const DODGE_COOLDOWN_FRAMES = 24;

export function startDodgeAction(
  player: PlayerState,
  moveId: string,
  input: InputFrame,
): void {
  const move = getCombatMoveData(moveId);
  if (!move) return;

  player.currentMoveId = moveId;
  player.actionFrame = 0;
  player.dodgeCooldownFrames = DODGE_COOLDOWN_FRAMES;

  if (moveId === "roll") {
    player.actionState = "rolling";
    const dir = input.left ? -1 : input.right ? 1 : player.facing;
    player.vx = dir * computeDashSpeed(player) * 1.2;
    player.invulnFrames = move.startup + move.active;
    return;
  }

  if (moveId === "air_dodge") {
    player.actionState = "airDodging";
    player.invulnFrames = move.startup + move.active;
    if (input.left) player.vx = -computeDashSpeed(player);
    else if (input.right) player.vx = computeDashSpeed(player);
    if (input.up) player.vy = -computeDashSpeed(player) * 0.8;
    else if (input.down) player.vy = computeDashSpeed(player) * 0.5;
    return;
  }

  player.actionState = "dodging";
  player.vx = 0;
  player.invulnFrames = move.startup + move.active;
}

export function tickDodgeCooldown(player: PlayerState): void {
  if (player.dodgeCooldownFrames > 0) player.dodgeCooldownFrames -= 1;
}

export function canDodge(player: PlayerState): boolean {
  return player.dodgeCooldownFrames <= 0;
}

export function isDodgeInvulnerable(player: PlayerState): boolean {
  if (player.invulnFrames <= 0) return false;
  const move = getCombatMoveData(player.currentMoveId);
  if (!move) return player.actionState === "dodging" || player.actionState === "rolling" || player.actionState === "airDodging";
  const frameData = combatMoveToFrameData(move);
  return isInActive(frameData, player.actionFrame) || player.actionFrame <= move.startup;
}

export function tickDodgeAction(player: PlayerState): void {
  const move = getCombatMoveData(player.currentMoveId);
  if (!move) return;
  const frameData = combatMoveToFrameData(move);
  if (!isMoveComplete(frameData, player.actionFrame)) return;

  if (
    player.actionState === "dodging" ||
    player.actionState === "rolling" ||
    player.actionState === "airDodging"
  ) {
    player.actionState = player.onGround ? "idle" : "falling";
    player.currentMoveId = "none";
  }
}

export function dodgeActiveOffset(player: PlayerState): number {
  if (player.actionState !== "rolling") return 0;
  const move = getCombatMoveData("roll");
  if (!move) return 0;
  const frameData = combatMoveToFrameData(move);
  if (!isInActive(frameData, player.actionFrame)) return 0;
  return player.facing * 4 * FP_SCALE;
}
