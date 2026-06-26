import type { StageBounds } from "./types.js";
import {
  BLAST_BOTTOM,
  BLAST_LEFT,
  BLAST_RIGHT,
  BLAST_TOP,
  FLOOR_Y,
  FP_SCALE,
  STAGE_HEIGHT,
  STAGE_WIDTH,
} from "./constants.js";

export type StageDef = {
  id: string;
  name: string;
  bounds: StageBounds;
  spawnPoints: { x: number; y: number }[];
  placeholder?: boolean;
};

const SKYLINE_ARENA: StageDef = {
  id: "skyline-arena",
  name: "Skyline Arena",
  bounds: {
    left: BLAST_LEFT,
    right: BLAST_RIGHT,
    top: BLAST_TOP,
    bottom: BLAST_BOTTOM,
    floorY: FLOOR_Y,
  },
  spawnPoints: [
    { x: STAGE_WIDTH / 3, y: FLOOR_Y - 64 * FP_SCALE },
    { x: (STAGE_WIDTH * 2) / 3, y: FLOOR_Y - 64 * FP_SCALE },
    { x: STAGE_WIDTH / 4, y: FLOOR_Y - 64 * FP_SCALE },
    { x: (STAGE_WIDTH * 3) / 4, y: FLOOR_Y - 64 * FP_SCALE },
  ],
};

const TRAINING_GRID: StageDef = {
  id: "training-grid",
  name: "Training Grid",
  placeholder: true,
  bounds: { ...SKYLINE_ARENA.bounds },
  spawnPoints: [...SKYLINE_ARENA.spawnPoints],
};

const IMPACT_PLATFORM: StageDef = {
  id: "impact-platform",
  name: "Impact Platform",
  placeholder: true,
  bounds: {
    left: BLAST_LEFT + 200 * FP_SCALE,
    right: BLAST_RIGHT - 200 * FP_SCALE,
    top: BLAST_TOP,
    bottom: BLAST_BOTTOM,
    floorY: FLOOR_Y,
  },
  spawnPoints: [
    { x: STAGE_WIDTH / 3, y: FLOOR_Y - 64 * FP_SCALE },
    { x: (STAGE_WIDTH * 2) / 3, y: FLOOR_Y - 64 * FP_SCALE },
    { x: STAGE_WIDTH / 4, y: FLOOR_Y - 64 * FP_SCALE },
    { x: (STAGE_WIDTH * 3) / 4, y: FLOOR_Y - 64 * FP_SCALE },
  ],
};

const STAGES: Record<string, StageDef> = {
  "skyline-arena": SKYLINE_ARENA,
  "training-grid": TRAINING_GRID,
  "impact-platform": IMPACT_PLATFORM,
};

export function getStage(id: string): StageDef {
  return STAGES[id] ?? SKYLINE_ARENA;
}

export function listStages(): StageDef[] {
  return Object.values(STAGES);
}

export { STAGE_WIDTH, STAGE_HEIGHT, FLOOR_Y };
