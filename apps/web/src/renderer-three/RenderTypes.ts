import type { GameState, PlayerState } from "@anime-aggressors/game-core";
import { FP_SCALE, STAGE_HEIGHT, STAGE_WIDTH } from "@anime-aggressors/game-core";

export type ThreeRendererOptions = {
  width?: number;
  height?: number;
  smoothCamera?: boolean;
  pixelRatio?: number;
  debug?: boolean;
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

/** Display units — matches 2D canvas renderer (stage width 2400). */
export const STAGE_DISPLAY_WIDTH = STAGE_WIDTH / FP_SCALE;
export const STAGE_DISPLAY_HEIGHT = STAGE_HEIGHT / FP_SCALE;

/** Low-poly humanoid base height before display scale (~2 units). */
export const CHARACTER_BASE_HEIGHT = 2.2;

/** Scale humanoid meshes to ~64 display units tall (matches 2D fighter rects). */
export const CHARACTER_DISPLAY_SCALE = 30;

/** Convert fixed-point game units to Three.js display coordinates. */
export function fpToWorld(value: number): number {
  return value / FP_SCALE;
}

export function characterWorldScale(sizeScale = 1): number {
  return CHARACTER_DISPLAY_SCALE * sizeScale;
}

export function stageCenterDisplay(): { x: number; y: number } {
  return { x: STAGE_DISPLAY_WIDTH / 2, y: fpToWorld(STAGE_HEIGHT) / 2 };
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
