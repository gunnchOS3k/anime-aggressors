import type { StageDef } from "@anime-aggressors/game-core";
import {
  getStage,
  getStageLayout,
  listStageLayoutIds,
  listStages,
  type StageLayoutDef,
} from "@anime-aggressors/game-core";

export type { StageLayoutDef, StagePlatform } from "@anime-aggressors/game-core";
export { getStageLayout, listStageLayoutIds, STAGE_LAYOUTS } from "@anime-aggressors/game-core";

export type StageVisualConfig = {
  stageId: string;
  layoutId: string;
  skyGradient: [string, string];
  accentHex: string;
  ambientHex: string;
  propTags: string[];
};

const VISUALS: Record<string, StageVisualConfig> = {
  "skyline-arena": {
    stageId: "skyline-arena",
    layoutId: "skyline-arena",
    skyGradient: ["#0a0a28", "#1a1a44"],
    accentHex: "#ff4466",
    ambientHex: "#334466",
    propTags: ["neon-towers", "rooftop"],
  },
  "training-grid": {
    stageId: "training-grid",
    layoutId: "training-grid",
    skyGradient: ["#101820", "#1a2838"],
    accentHex: "#44ffaa",
    ambientHex: "#445566",
    propTags: ["grid-floor", "markers"],
  },
  "impact-platform": {
    stageId: "impact-platform",
    layoutId: "impact-platform",
    skyGradient: ["#1a2040", "#3a5090"],
    accentHex: "#ffd166",
    ambientHex: "#556688",
    propTags: ["runway", "distance-markers"],
  },
  "flagline-center-clash": {
    stageId: "flagline-center-clash",
    layoutId: "flagline-center-clash",
    skyGradient: ["#1a1a30", "#2a2a50"],
    accentHex: "#aa88ff",
    ambientHex: "#445577",
    propTags: ["flag-core", "symmetrical"],
  },
  "flagline-lunar-outpost": {
    stageId: "flagline-lunar-outpost",
    layoutId: "flagline-lunar-outpost",
    skyGradient: ["#0a1020", "#1a2848"],
    accentHex: "#6688cc",
    ambientHex: "#334455",
    propTags: ["moon-base", "cool"],
  },
  "flagline-solar-outpost": {
    stageId: "flagline-solar-outpost",
    layoutId: "flagline-solar-outpost",
    skyGradient: ["#281808", "#483018"],
    accentHex: "#ffaa44",
    ambientHex: "#665544",
    propTags: ["solar-pylons", "warm"],
  },
  "flagline-lunar-base": {
    stageId: "flagline-lunar-base",
    layoutId: "flagline-lunar-base",
    skyGradient: ["#080818", "#181830"],
    accentHex: "#5566aa",
    ambientHex: "#222233",
    propTags: ["fortress", "heavy"],
  },
  "flagline-solar-base": {
    stageId: "flagline-solar-base",
    layoutId: "flagline-solar-base",
    skyGradient: ["#302010", "#504020"],
    accentHex: "#ffcc55",
    ambientHex: "#776644",
    propTags: ["solar-fortress", "heroic"],
  },
};

export function getStageVisualConfig(stageId: string): StageVisualConfig {
  return VISUALS[stageId] ?? VISUALS["skyline-arena"]!;
}

export function stageLayoutMatchesVisual(stageId: string): boolean {
  const visual = getStageVisualConfig(stageId);
  const layout = getStageLayout(stageId);
  return visual.layoutId === layout.id;
}

export function getStageWithLayout(stageId: string): { stage: StageDef; layout: StageLayoutDef } {
  return { stage: getStage(stageId), layout: getStageLayout(stageId) };
}

export function listPlayableStages(): StageDef[] {
  return listStages().filter((s: StageDef) => listStageLayoutIds().includes(s.id));
}
