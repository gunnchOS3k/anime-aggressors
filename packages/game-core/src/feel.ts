import { FP_SCALE } from "./constants.js";
import type { MoveFrameData } from "./frameData.js";
import type { PlayerState } from "./types.js";

export const COYOTE_FRAMES = 6;
export const JUMP_BUFFER_FRAMES = 8;
export const FAST_FALL_MULT = 150; // percent of max fall speed

export function scaleKnockback(
  data: MoveFrameData,
  defenderDamage: number,
): { kbX: number; kbY: number } {
  const kb = data.baseKnockback + Math.floor(defenderDamage * data.knockbackGrowth);
  const scaled = (kb * FP_SCALE) / 100;
  return {
    kbX: scaled,
    kbY: -(scaled * 3) / 5,
  };
}

export function tickCoyoteTime(player: PlayerState, wasOnGround: boolean): void {
  if (player.onGround) {
    player.coyoteFrames = COYOTE_FRAMES;
  } else if (wasOnGround && !player.onGround) {
    player.coyoteFrames = COYOTE_FRAMES;
  } else if (player.coyoteFrames > 0) {
    player.coyoteFrames -= 1;
  }
}

export function canCoyoteJump(player: PlayerState): boolean {
  return player.coyoteFrames > 0 && player.jumpsRemaining > 0;
}

export function bufferJump(player: PlayerState, pressed: boolean): void {
  if (pressed) {
    player.jumpBufferFrames = JUMP_BUFFER_FRAMES;
  } else if (player.jumpBufferFrames > 0) {
    player.jumpBufferFrames -= 1;
  }
}

export function consumeJumpBuffer(player: PlayerState): boolean {
  if (player.jumpBufferFrames > 0) {
    player.jumpBufferFrames = 0;
    return true;
  }
  return false;
}

export function isDodgeInvulnerable(player: PlayerState, dodgeStartup: number, dodgeActive: number): boolean {
  if (player.actionState !== "dodging") return false;
  const f = player.actionFrame;
  return f >= dodgeStartup && f < dodgeStartup + dodgeActive;
}
