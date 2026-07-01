import { FP_SCALE, STAGE_WIDTH, FLOOR_Y } from "./constants.js";

export type StagePlatform = {
  id: string;
  x: number;
  y: number;
  width: number;
  height: number;
};

export type StageLedge = {
  id: string;
  platformId: string;
  x: number;
  y: number;
  side: "left" | "right";
};

export type StageLayoutDef = {
  id: string;
  name: string;
  vibe: string;
  hazardsEnabled: boolean;
  supportedModes: string[];
  platforms: StagePlatform[];
  mainPlatformId: string;
  ledges: StageLedge[];
};

const W = STAGE_WIDTH;
const FLOOR = FLOOR_Y;

function mainFloor(id = "main"): StagePlatform {
  return { id, x: W * 0.15, y: FLOOR, width: W * 0.7, height: 24 * FP_SCALE };
}

function sidePlat(left: boolean, yOffset = 180 * FP_SCALE): StagePlatform {
  return {
    id: left ? "side-left" : "side-right",
    x: left ? W * 0.12 : W * 0.72,
    y: FLOOR - yOffset,
    width: W * 0.16,
    height: 16 * FP_SCALE,
  };
}

function centerHigh(): StagePlatform {
  return { id: "center-high", x: W * 0.42, y: FLOOR - 260 * FP_SCALE, width: W * 0.16, height: 16 * FP_SCALE };
}

function ledgesForMain(main: StagePlatform): StageLedge[] {
  return [
    { id: "main-ledge-left", platformId: main.id, x: main.x, y: main.y, side: "left" },
    { id: "main-ledge-right", platformId: main.id, x: main.x + main.width, y: main.y, side: "right" },
  ];
}

function layoutWithLedges(
  partial: Omit<StageLayoutDef, "ledges"> & { ledges?: StageLedge[] },
): StageLayoutDef {
  const main = partial.platforms.find((p) => p.id === partial.mainPlatformId);
  const ledges = partial.ledges ?? (main ? ledgesForMain(main) : []);
  return { ...partial, ledges };
}

export const STAGE_LAYOUTS: Record<string, StageLayoutDef> = {
  "skyline-arena": layoutWithLedges({
    id: "skyline-arena",
    name: "Skyline Arena",
    vibe: "Neon rooftop duel with floating side platforms.",
    hazardsEnabled: false,
    supportedModes: ["stock", "time", "stamina", "flaglineClash"],
    platforms: [mainFloor(), sidePlat(true), sidePlat(false), centerHigh()],
    mainPlatformId: "main",
  }),
  "training-grid": layoutWithLedges({
    id: "training-grid",
    name: "Training Grid",
    vibe: "Clean sim arena with measurement markers.",
    hazardsEnabled: false,
    supportedModes: ["stock", "time", "stamina", "training"],
    platforms: [mainFloor(), sidePlat(true, 140 * FP_SCALE), sidePlat(false, 140 * FP_SCALE)],
    mainPlatformId: "main",
  }),
  "impact-platform": layoutWithLedges({
    id: "impact-platform",
    name: "Impact Platform",
    vibe: "Long runway for launch-distance derby.",
    hazardsEnabled: false,
    supportedModes: ["impactDummyDerby", "stock"],
    platforms: [
      { id: "runway", x: W * 0.05, y: FLOOR, width: W * 0.9, height: 20 * FP_SCALE },
    ],
    mainPlatformId: "runway",
  }),
  "flagline-center-clash": layoutWithLedges({
    id: "flagline-center-clash",
    name: "Center Clash",
    vibe: "Neutral conflict zone with flag core centerpiece.",
    hazardsEnabled: false,
    supportedModes: ["flaglineClash", "stock"],
    platforms: [mainFloor(), sidePlat(true), sidePlat(false)],
    mainPlatformId: "main",
  }),
  "flagline-lunar-outpost": layoutWithLedges({
    id: "flagline-lunar-outpost",
    name: "Lunar Outpost",
    vibe: "Cool moon-base outpost with angled platforms.",
    hazardsEnabled: false,
    supportedModes: ["flaglineClash"],
    platforms: [
      mainFloor(),
      { id: "lunar-left", x: W * 0.1, y: FLOOR - 150 * FP_SCALE, width: W * 0.2, height: 16 * FP_SCALE },
      { id: "lunar-right", x: W * 0.7, y: FLOOR - 200 * FP_SCALE, width: W * 0.18, height: 16 * FP_SCALE },
    ],
    mainPlatformId: "main",
  }),
  "flagline-solar-outpost": layoutWithLedges({
    id: "flagline-solar-outpost",
    name: "Solar Outpost",
    vibe: "Warm energy facility with solar pylons.",
    hazardsEnabled: false,
    supportedModes: ["flaglineClash"],
    platforms: [mainFloor(), sidePlat(true, 160 * FP_SCALE), sidePlat(false, 160 * FP_SCALE)],
    mainPlatformId: "main",
  }),
  "flagline-lunar-base": layoutWithLedges({
    id: "flagline-lunar-base",
    name: "Lunar Base",
    vibe: "Enemy stronghold with heavy back structures.",
    hazardsEnabled: true,
    supportedModes: ["flaglineClash"],
    platforms: [
      mainFloor(),
      { id: "back-wall", x: W * 0.05, y: FLOOR - 120 * FP_SCALE, width: W * 0.15, height: 80 * FP_SCALE },
      sidePlat(true, 200 * FP_SCALE),
    ],
    mainPlatformId: "main",
  }),
  "flagline-solar-base": layoutWithLedges({
    id: "flagline-solar-base",
    name: "Solar Base",
    vibe: "Bright fortress with heroic warm lighting.",
    hazardsEnabled: false,
    supportedModes: ["flaglineClash"],
    platforms: [
      mainFloor(),
      { id: "solar-tower", x: W * 0.78, y: FLOOR - 140 * FP_SCALE, width: W * 0.12, height: 100 * FP_SCALE },
      sidePlat(false, 180 * FP_SCALE),
    ],
    mainPlatformId: "main",
  }),
};

export function getStageLayout(stageId: string): StageLayoutDef {
  return STAGE_LAYOUTS[stageId] ?? STAGE_LAYOUTS["skyline-arena"]!;
}

export function listStageLayoutIds(): string[] {
  return Object.keys(STAGE_LAYOUTS);
}
