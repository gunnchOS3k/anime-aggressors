import { FP_SCALE, FLOOR_Y, STAGE_WIDTH } from "./constants.js";
import type { StageDef } from "./stages.js";
import { getStageLayout } from "./stageLayouts.js";

export type SpawnPoint = { x: number; y: number; playerId?: number };

/** Display-space spawn helpers (fixed-point game units). */
export function defaultBattleSpawns(): SpawnPoint[] {
  return [
    { x: STAGE_WIDTH / 3, y: FLOOR_Y - 64 * FP_SCALE, playerId: 0 },
    { x: (STAGE_WIDTH * 2) / 3, y: FLOOR_Y - 64 * FP_SCALE, playerId: 1 },
  ];
}

export function validateSpawnPoints(stage: StageDef): string[] {
  const warnings: string[] = [];
  const layout = getStageLayout(stage.layoutId ?? stage.id);
  const main = layout.platforms.find((p) => p.id === layout.mainPlatformId) ?? layout.platforms[0];
  if (!main) {
    warnings.push("stage has no platforms");
    return warnings;
  }

  for (let i = 0; i < stage.spawnPoints.length; i++) {
    const sp = stage.spawnPoints[i]!;
    if (sp.y >= main.y) {
      warnings.push(`spawn ${i} y=${sp.y} not above main platform y=${main.y}`);
    }
    if (sp.x < main.x || sp.x > main.x + main.width) {
      warnings.push(`spawn ${i} x=${sp.x} outside main platform [${main.x}, ${main.x + main.width}]`);
    }
    if (sp.y < FLOOR_Y - 200 * FP_SCALE) {
      warnings.push(`spawn ${i} too far below floor`);
    }
  }

  return warnings;
}

export function spawnDisplayX(playerIndex: number): number {
  return defaultBattleSpawns()[playerIndex]?.x ?? STAGE_WIDTH / 2;
}
