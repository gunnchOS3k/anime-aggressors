import type { InputFrame, PlayerState } from "../types.js";
import { getCharacterForPlayer } from "../characters.js";
import { MOVEMENT_BASE, movementTuningForSize, scaledMovementValue } from "./movementTuning.js";
import { getPlayerSizeStats } from "../fighterCreation.js";

export const JUMP_TUNING = {
  coyoteFrames: 5,
  jumpBufferFrames: 6,
  maxAirJumps: 1,
  shortHopReleaseFrames: 6,
  shortHopVelocityMultiplier: 0.72,
} as const;

export function getMaxJumpsForPlayer(player: PlayerState): number {
  return getCharacterForPlayer(player).maxJumps;
}

export function getMaxAirJumpsForPlayer(player: PlayerState): number {
  return Math.max(0, getMaxJumpsForPlayer(player) - 1);
}

export function computeJumpVelocity(player: PlayerState, shortHop = false): number {
  const tuning = movementTuningForSize(player.fighterSize ?? "medium");
  const stats = getPlayerSizeStats(player);
  let base = scaledMovementValue(MOVEMENT_BASE.jumpVelocity, tuning.jumpVelocity);
  base = Math.floor(base * stats.jumpMultiplier);
  if (shortHop) {
    base = Math.floor(base * JUMP_TUNING.shortHopVelocityMultiplier);
  }
  return base;
}

export function computeDoubleJumpVelocity(player: PlayerState): number {
  return Math.floor(computeJumpVelocity(player) * 0.94);
}

export function bufferJumpInput(player: PlayerState, pressed: boolean): void {
  if (pressed) {
    player.jumpBufferFrames = JUMP_TUNING.jumpBufferFrames;
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

export function tickCoyoteTime(player: PlayerState, wasOnGround: boolean): void {
  if (player.onGround) {
    player.coyoteFrames = JUMP_TUNING.coyoteFrames;
  } else if (wasOnGround && !player.onGround) {
    player.coyoteFrames = JUMP_TUNING.coyoteFrames;
  } else if (player.coyoteFrames > 0) {
    player.coyoteFrames -= 1;
  }
}

export function canCoyoteJump(player: PlayerState): boolean {
  return player.coyoteFrames > 0 && player.jumpsUsed === 0;
}

export type JumpResult = "ground" | "air" | "coyote" | null;

export function tryJump(player: PlayerState, input: InputFrame, jumpJustPressed: boolean): JumpResult {
  const wantsJump = jumpJustPressed || consumeJumpBuffer(player);
  if (!wantsJump) return null;

  if (player.onGround || canCoyoteJump(player)) {
    const coyote = !player.onGround;
    if (coyote) player.coyoteFrames = 0;
    player.jumpsUsed = 1;
    player.jumpsRemaining = Math.max(0, getMaxJumpsForPlayer(player) - player.jumpsUsed);
    player.vy = computeJumpVelocity(player, false);
    player.onGround = false;
    player.actionState = "jumping";
    player.actionFrame = 0;
    player.fastFalling = false;
    player.jumpHoldFrames = JUMP_TUNING.shortHopReleaseFrames;
    return coyote ? "coyote" : "ground";
  }

  const maxAir = getMaxAirJumpsForPlayer(player);
  if (!player.onGround && player.jumpsUsed === 1 && maxAir >= 1) {
    player.jumpsUsed = 2;
    player.jumpsRemaining = Math.max(0, getMaxJumpsForPlayer(player) - player.jumpsUsed);
    player.vy = computeDoubleJumpVelocity(player);
    player.actionState = "jumping";
    player.actionFrame = 0;
    player.fastFalling = false;
    player.jumpHoldFrames = JUMP_TUNING.shortHopReleaseFrames;
    return "air";
  }

  return null;
}

export function tickJumpHold(player: PlayerState, jumpHeld: boolean): void {
  if (!jumpHeld && player.jumpHoldFrames > 0 && player.vy < 0) {
    player.vy = Math.floor(player.vy * JUMP_TUNING.shortHopVelocityMultiplier);
    player.jumpHoldFrames = 0;
  } else if (player.jumpHoldFrames > 0) {
    player.jumpHoldFrames -= 1;
  }
  player.wasJumpHeld = jumpHeld;
}

export function resetJumpStateOnLand(player: PlayerState): void {
  player.jumpsUsed = 0;
  player.jumpsRemaining = getMaxJumpsForPlayer(player);
  player.jumpHoldFrames = 0;
  player.coyoteFrames = JUMP_TUNING.coyoteFrames;
}

export function fastFallSpeed(maxFall: number, player: PlayerState): number {
  const tuning = movementTuningForSize(player.fighterSize ?? "medium");
  const mult = (MOVEMENT_BASE.fastFallMult * tuning.fastFall) / 100;
  return Math.floor(maxFall * mult);
}
