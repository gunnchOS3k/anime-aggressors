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
import { getStageLayout } from "./stageLayouts.js";


function partySpawnPoints(): { x: number; y: number }[] {
  // Explicit 8-seat layout for large-party stages (do not invent seats on tiny stages).
  const xs = [1 / 9, 2 / 9, 3 / 9, 4 / 9, 5 / 9, 6 / 9, 7 / 9, 8 / 9];
  return xs.map((t) => ({ x: STAGE_WIDTH * t, y: FLOOR_Y }));
}

export type StageDef = {
  id: string;
  name: string;
  bounds: StageBounds;
  spawnPoints: { x: number; y: number }[];
  layoutId: string;
  vibe?: string;
  hazardsEnabled?: boolean;
};

const SKYLINE_ARENA: StageDef = {
  id: "skyline-arena",
  name: "Skyline Arena",
  layoutId: "skyline-arena",
  vibe: "Neon rooftop duel",
  bounds: {
    left: BLAST_LEFT,
    right: BLAST_RIGHT,
    top: BLAST_TOP,
    bottom: BLAST_BOTTOM,
    floorY: FLOOR_Y,
  },
  spawnPoints: [
    { x: STAGE_WIDTH / 3, y: FLOOR_Y },
    { x: (STAGE_WIDTH * 2) / 3, y: FLOOR_Y },
    { x: STAGE_WIDTH / 4, y: FLOOR_Y },
    { x: (STAGE_WIDTH * 3) / 4, y: FLOOR_Y },
  ],
};

const TRAINING_GRID: StageDef = {
  id: "training-grid",
  name: "Training Grid",
  layoutId: "training-grid",
  vibe: "Clean sim arena",
  bounds: { ...SKYLINE_ARENA.bounds },
  spawnPoints: [...SKYLINE_ARENA.spawnPoints],
};

const IMPACT_PLATFORM: StageDef = {
  id: "impact-platform",
  name: "Impact Platform",
  layoutId: "impact-platform",
  vibe: "Launch runway arena",
  bounds: {
    left: BLAST_LEFT + 200 * FP_SCALE,
    right: BLAST_RIGHT - 200 * FP_SCALE,
    top: BLAST_TOP,
    bottom: BLAST_BOTTOM,
    floorY: FLOOR_Y,
  },
  spawnPoints: [
    { x: STAGE_WIDTH / 3, y: FLOOR_Y },
    { x: (STAGE_WIDTH * 2) / 3, y: FLOOR_Y },
    { x: STAGE_WIDTH / 4, y: FLOOR_Y },
    { x: (STAGE_WIDTH * 3) / 4, y: FLOOR_Y },
  ],
};

const FLAGLINE_BASE: StageDef = {
  id: "flagline-lunar-base",
  name: "Lunar Base",
  layoutId: "flagline-lunar-base",
  vibe: "Enemy stronghold",
  hazardsEnabled: true,
  bounds: { left: BLAST_LEFT, right: BLAST_RIGHT, top: BLAST_TOP, bottom: BLAST_BOTTOM, floorY: FLOOR_Y },
  spawnPoints: [
    { x: STAGE_WIDTH / 4, y: FLOOR_Y },
    { x: STAGE_WIDTH / 3, y: FLOOR_Y },
    { x: (STAGE_WIDTH * 3) / 4, y: FLOOR_Y },
    { x: (STAGE_WIDTH * 2) / 3, y: FLOOR_Y },
  ],
};

const FLAGLINE_STAGES: StageDef[] = [
  FLAGLINE_BASE,
  { ...FLAGLINE_BASE, id: "flagline-lunar-outpost", name: "Lunar Outpost", layoutId: "flagline-lunar-outpost", vibe: "Moon outpost", hazardsEnabled: false },
  { ...FLAGLINE_BASE, id: "flagline-center-clash", name: "Center Clash", layoutId: "flagline-center-clash", vibe: "Neutral flag core", hazardsEnabled: false },
  { ...FLAGLINE_BASE, id: "flagline-solar-outpost", name: "Solar Outpost", layoutId: "flagline-solar-outpost", vibe: "Solar facility", hazardsEnabled: false },
  { ...FLAGLINE_BASE, id: "flagline-solar-base", name: "Solar Base", layoutId: "flagline-solar-base", vibe: "Solar fortress", hazardsEnabled: false },
];

const NEON_ROOFTOPS: StageDef = {
  id: "neon-rooftops",
  name: "Neon Rooftops",
  layoutId: "neon-rooftops",
  vibe: "Casual city rooftop duel",
  bounds: { ...SKYLINE_ARENA.bounds },
  spawnPoints: [...SKYLINE_ARENA.spawnPoints],
};

const PARTY_PLAZA: StageDef = {
  id: "party-plaza",
  name: "Party Plaza",
  layoutId: "skyline-arena",
  vibe: "Validated 8-player party stage with explicit spawn lanes",
  bounds: { ...SKYLINE_ARENA.bounds },
  spawnPoints: partySpawnPoints(),
};

const STAGES: Record<string, StageDef> = {
  "skyline-arena": SKYLINE_ARENA,
  "training-grid": TRAINING_GRID,
  "neon-rooftops": NEON_ROOFTOPS,
  "impact-platform": IMPACT_PLATFORM,
  "party-plaza": PARTY_PLAZA,
  ...Object.fromEntries(FLAGLINE_STAGES.map((s) => [s.id, s])),
};

export function getStage(id: string): StageDef {
  return STAGES[id] ?? SKYLINE_ARENA;
}

export function listStages(): StageDef[] {
  return Object.values(STAGES);
}

export function stageHasLayout(stageId: string): boolean {
  const stage = getStage(stageId);
  const layout = getStageLayout(stage.layoutId);
  return layout.id === stage.layoutId;
}

export { STAGE_WIDTH, STAGE_HEIGHT, FLOOR_Y };
