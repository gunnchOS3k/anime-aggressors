import type { GameState, PlayerState } from "@anime-aggressors/game-core";

export type ThreeRendererOptions = {
  width?: number;
  height?: number;
  smoothCamera?: boolean;
  pixelRatio?: number;
};

export type RenderOptions = {
  showHitboxes?: boolean;
  showHurtboxes?: boolean;
  showBlastZones?: boolean;
  debug?: boolean;
  hitstopFreeze?: boolean;
};

export type RenderEventType =
  | "hit"
  | "shield"
  | "jump"
  | "land"
  | "dodge"
  | "ko";

export type RenderEvent = {
  type: RenderEventType;
  playerId: number;
  frame: number;
};

export type RenderablePlayer = {
  id: number;
  x: number;
  y: number;
  facing: number;
  damage: number;
  stocks: number;
  actionState: string;
  characterId: string;
};

export type RenderableStage = {
  id: string;
  name: string;
};

export type RenderDebugState = {
  frame: number;
  hash?: string;
  rollbackCount?: number;
};

export type RenderableGameState = {
  frame: number;
  players: RenderablePlayer[];
  stage: RenderableStage;
  debug?: RenderDebugState;
  events?: RenderEvent[];
};

/** Convert fixed-point game units to Three.js world units. */
export function fpToWorld(value: number): number {
  return value / 256;
}

export function mapPlayerToRenderable(p: PlayerState): RenderablePlayer {
  return {
    id: p.id,
    x: fpToWorld(p.x),
    y: fpToWorld(p.y),
    facing: p.facing,
    damage: p.damage,
    stocks: p.stocks,
    actionState: p.actionState,
    characterId: p.characterId,
  };
}

export function mapGameStateToRenderable(state: GameState): RenderableGameState {
  return {
    frame: state.frame,
    players: state.players.map(mapPlayerToRenderable),
    stage: { id: state.config.stageId, name: "Skyline Arena" },
  };
}

/** Pure mapping — must not mutate authoritative state. */
export function mapGameStateReadOnly(state: GameState): RenderableGameState {
  const before = JSON.stringify(state);
  const mapped = mapGameStateToRenderable(state);
  const after = JSON.stringify(state);
  if (before !== after) {
    throw new Error("Renderer mapping mutated GameState");
  }
  return mapped;
}
