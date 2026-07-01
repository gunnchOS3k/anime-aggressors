import type { PlayerState } from "./types.js";
import { FP_SCALE, HURTBOX_W } from "./constants.js";
import type { StageLayoutDef } from "./stageLayouts.js";

const LAND_TOLERANCE = 4 * FP_SCALE;

function horizontalOverlap(playerX: number, platLeft: number, platRight: number): boolean {
  const halfW = HURTBOX_W / 2;
  const left = playerX - halfW;
  const right = playerX + halfW;
  return right > platLeft && left < platRight;
}

/**
 * Resolve landing on stage platforms when falling from above.
 * Does not snap players upward through platforms (rising vy skips collision).
 */
export function resolvePlatformLanding(
  player: PlayerState,
  layout: StageLayoutDef,
  previousY: number,
): boolean {
  if (player.vy < 0) {
    return false;
  }

  let landY: number | null = null;

  for (const plat of layout.platforms) {
    const top = plat.y;
    const platLeft = plat.x;
    const platRight = plat.x + plat.width;

    if (!horizontalOverlap(player.x, platLeft, platRight)) continue;

    const crossedFromAbove = previousY <= top + LAND_TOLERANCE && player.y >= top;
    const restingOnTop =
      Math.abs(player.y - top) <= LAND_TOLERANCE && player.vy >= 0;

    if (crossedFromAbove || restingOnTop) {
      if (landY === null || top < landY) {
        landY = top;
      }
    }
  }

  if (landY === null) {
    return false;
  }

  player.y = landY;
  player.vy = 0;
  return true;
}
