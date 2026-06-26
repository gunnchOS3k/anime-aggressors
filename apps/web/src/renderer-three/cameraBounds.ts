import type { GameState } from "@anime-aggressors/game-core";

function fpToWorld(value: number): number {
  return value / 256;
}

export type CameraBounds = {
  minX: number;
  maxX: number;
  minY: number;
  maxY: number;
};

export function computeCameraBounds(state: GameState): CameraBounds {
  const alive = state.players.filter((p) => p.actionState !== "defeated");
  const list = alive.length > 0 ? alive : state.players;

  let minX = Infinity;
  let maxX = -Infinity;
  let minY = Infinity;
  let maxY = -Infinity;

  for (const p of list) {
    const x = fpToWorld(p.x);
    const y = fpToWorld(p.y);
    minX = Math.min(minX, x);
    maxX = Math.max(maxX, x);
    minY = Math.min(minY, y);
    maxY = Math.max(maxY, y);
  }

  const padX = 6;
  const padY = 4;
  return {
    minX: minX - padX,
    maxX: maxX + padX,
    minY: minY - padY,
    maxY: maxY + padY,
  };
}
