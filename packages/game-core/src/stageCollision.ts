import type { PlayerState } from "./types.js";
import { FP_SCALE, HURTBOX_W } from "./constants.js";
import type { StageLayoutDef, StagePlatform } from "./stageLayouts.js";

const LAND_TOLERANCE = 4 * FP_SCALE;

/** Frames to ignore a platform after Down+Jump drop-through. */
export const DROP_THROUGH_IGNORE_FRAMES = 24;

export type StageCollisionResult = {
  landed: boolean;
  platformId: string;
};

function horizontalOverlap(playerX: number, platLeft: number, platRight: number): boolean {
  const halfW = HURTBOX_W / 2;
  const left = playerX - halfW;
  const right = playerX + halfW;
  return right > platLeft && left < platRight;
}

export function isPassThroughPlatform(layout: StageLayoutDef, platformId: string): boolean {
  return platformId !== "" && platformId !== layout.mainPlatformId;
}

export function tickDropThrough(player: PlayerState): void {
  if (player.dropThroughFrames > 0) {
    player.dropThroughFrames -= 1;
    if (player.dropThroughFrames === 0) {
      player.ignoredPlatformId = "";
    }
  }
}

/** Start dropping through a non-main platform (Down + Jump). */
export function beginDropThrough(player: PlayerState, platformId: string): void {
  player.dropThroughFrames = DROP_THROUGH_IGNORE_FRAMES;
  player.ignoredPlatformId = platformId;
  player.onGround = false;
  player.currentPlatformId = "";
  player.vy = Math.max(player.vy, (3 * FP_SCALE) / 60);
}

function ignoredPlatformId(player: PlayerState): string {
  return player.dropThroughFrames > 0 ? player.ignoredPlatformId : "";
}

function platformCandidates(
  layout: StageLayoutDef,
  ignoreId: string,
): StagePlatform[] {
  return layout.platforms.filter((p) => !ignoreId || p.id !== ignoreId);
}

/**
 * Resolve landing and platform support after horizontal/vertical integration.
 * Rising players never snap onto platforms from below.
 */
export function resolveStageCollision(
  player: PlayerState,
  layout: StageLayoutDef,
  floorY: number,
  previousY: number,
): StageCollisionResult {
  const ignoreId = ignoredPlatformId(player);

  if (player.vy < 0) {
    return { landed: false, platformId: "" };
  }

  let best: { id: string; y: number } | null = null;

  for (const plat of platformCandidates(layout, ignoreId)) {
    const platLeft = plat.x;
    const platRight = plat.x + plat.width;
    if (!horizontalOverlap(player.x, platLeft, platRight)) continue;

    const top = plat.y;
    const crossedFromAbove = previousY <= top + LAND_TOLERANCE && player.y >= top;
    const restingOnTop =
      Math.abs(player.y - top) <= LAND_TOLERANCE && player.vy >= 0;

    if (crossedFromAbove || restingOnTop) {
      if (!best || top < best.y) {
        best = { id: plat.id, y: top };
      }
    }
  }

  if (best) {
    player.y = best.y;
    player.vy = 0;
    return { landed: true, platformId: best.id };
  }

  const main = layout.platforms.find((p) => p.id === layout.mainPlatformId);
  if (main && player.y >= floorY && horizontalOverlap(player.x, main.x, main.x + main.width)) {
    player.y = floorY;
    player.vy = 0;
    return { landed: true, platformId: main.id };
  }

  return { landed: false, platformId: "" };
}

/** @deprecated Use resolveStageCollision */
export function resolvePlatformLanding(
  player: PlayerState,
  layout: StageLayoutDef,
  previousY: number,
): boolean {
  const floorY = layout.platforms.find((p) => p.id === layout.mainPlatformId)?.y ?? player.y;
  const result = resolveStageCollision(player, layout, floorY, previousY);
  return result.landed;
}
