import type { PlayerState } from "../types.js";

export const STALE_QUEUE_SIZE = 5;
export const STALE_PENALTY = 0.9;

export function recordMoveUsed(player: PlayerState, moveId: string): void {
  if (!moveId || moveId === "none") return;
  player.staleMoveQueue.unshift(moveId);
  while (player.staleMoveQueue.length > STALE_QUEUE_SIZE) {
    player.staleMoveQueue.pop();
  }
}

export function staleRepeatCount(player: PlayerState, moveId: string): number {
  return player.staleMoveQueue.filter((id) => id === moveId).length;
}

export function applyStaleMultiplier(player: PlayerState, moveId: string): number {
  const repeats = staleRepeatCount(player, moveId);
  if (repeats <= 0) return 1;
  return Math.pow(STALE_PENALTY, repeats);
}

export function clearStaleQueue(player: PlayerState): void {
  player.staleMoveQueue = [];
}
