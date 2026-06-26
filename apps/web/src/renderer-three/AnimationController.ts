import type { PlayerState } from "@anime-aggressors/game-core";

/** Maps authoritative action state to visual pose hints (non-authoritative). */
export class AnimationController {
  getPoseScale(player: PlayerState): { x: number; y: number } {
    if (player.actionState === "jumping") return { x: 0.95, y: 1.08 };
    if (player.actionState === "falling" || player.fastFalling) return { x: 1.02, y: 0.94 };
    if (player.actionState === "dodging") return { x: 1.15, y: 0.85 };
    if (player.actionState === "attacking") return { x: 1.05, y: 0.98 };
    return { x: 1, y: 1 };
  }
}
