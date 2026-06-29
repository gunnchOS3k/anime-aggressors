import type { GameState } from "@anime-aggressors/game-core";
import { STAGE_HEIGHT, STAGE_WIDTH } from "@anime-aggressors/game-core";

function fpToWorld(value: number): number {
  return value / 256;
}

export const CAMERA_DEFAULTS = {
  minZoom: 0.75,
  maxZoom: 1.45,
  defaultZoom: 1.0,
  horizontalPadding: 5.0,
  verticalPadding: 3.0,
  zoomSmooth: 0.08,
  positionSmooth: 0.12,
} as const;

export type CameraFrameTarget = {
  centerX: number;
  centerY: number;
  minX: number;
  maxX: number;
  minY: number;
  maxY: number;
  requiredWidth: number;
  requiredHeight: number;
};

export type StageCameraBounds = {
  minX: number;
  maxX: number;
  minY: number;
  maxY: number;
};

export function getStageCameraBounds(): StageCameraBounds {
  const cx = fpToWorld(STAGE_WIDTH / 2);
  const cy = fpToWorld(STAGE_HEIGHT * 0.55);
  const halfW = fpToWorld(STAGE_WIDTH) * 0.48;
  const halfH = fpToWorld(STAGE_HEIGHT) * 0.42;
  return {
    minX: cx - halfW,
    maxX: cx + halfW,
    minY: cy - halfH * 0.5,
    maxY: cy + halfH,
  };
}

export function computeCameraFrameTarget(state: GameState): CameraFrameTarget {
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

  const padX = CAMERA_DEFAULTS.horizontalPadding * 16;
  const padY = CAMERA_DEFAULTS.verticalPadding * 16;
  minX -= padX;
  maxX += padX;
  minY -= padY;
  maxY += padY;

  const stage = getStageCameraBounds();
  minX = Math.max(stage.minX, minX);
  maxX = Math.min(stage.maxX, maxX);
  minY = Math.max(stage.minY, minY);
  maxY = Math.min(stage.maxY, maxY);

  const requiredWidth = Math.max(120, maxX - minX);
  const requiredHeight = Math.max(80, maxY - minY);
  const centerX = (minX + maxX) / 2;
  const centerY = (minY + maxY) / 2;

  return { centerX, centerY, minX, maxX, minY, maxY, requiredWidth, requiredHeight };
}

export function computeZoomFactor(target: CameraFrameTarget, aspect: number): number {
  const baseHalfW = 340;
  const neededW = target.requiredWidth / 1.35;
  const neededH = target.requiredHeight / 1.05;
  const fromW = baseHalfW / Math.max(neededW, 80);
  const fromH = (baseHalfW / aspect) / Math.max(neededH, 60);
  const raw = Math.min(fromW, fromH);
  return Math.min(CAMERA_DEFAULTS.maxZoom, Math.max(CAMERA_DEFAULTS.minZoom, raw));
}
