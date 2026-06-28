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
  title: string;
  skyGradient: [string, string];
  accentHex: string;
  ambientHex: string;
  propTags: string[];
  hazards: boolean;
  competitive: boolean;
};

const VISUALS: Record<string, StageVisualConfig> = {
  "skyline-arena": {
    stageId: "skyline-arena",
    layoutId: "skyline-arena",
    title: "Skyline Arena",
    skyGradient: ["#0a0a28", "#1a1a44"],
    accentHex: "#ff4466",
    ambientHex: "#334466",
    propTags: ["neon-towers", "rooftop", "foreground-rail"],
    hazards: false,
    competitive: true,
  },
  "training-grid": {
    stageId: "training-grid",
    layoutId: "training-grid",
    title: "Training Grid",
    skyGradient: ["#101820", "#1a2838"],
    accentHex: "#44ffaa",
    ambientHex: "#445566",
    propTags: ["grid-floor", "hologram-walls", "measurement-lines"],
    hazards: false,
    competitive: true,
  },
  "impact-platform": {
    stageId: "impact-platform",
    layoutId: "impact-platform",
    title: "Impact Platform",
    skyGradient: ["#1a2040", "#3a5090"],
    accentHex: "#ffd166",
    ambientHex: "#556688",
    propTags: ["runway", "distance-markers", "launch-stadium"],
    hazards: false,
    competitive: true,
  },
  "flagline-center-clash": {
    stageId: "flagline-center-clash",
    layoutId: "flagline-center-clash",
    title: "Center Clash",
    skyGradient: ["#1a1a30", "#2a2a50"],
    accentHex: "#aa88ff",
    ambientHex: "#445577",
    propTags: ["flag-core", "neutral-structures", "arena-walls"],
    hazards: false,
    competitive: true,
  },
  "flagline-lunar-outpost": {
    stageId: "flagline-lunar-outpost",
    layoutId: "flagline-lunar-outpost",
    title: "Lunar Outpost",
    skyGradient: ["#0a1020", "#1a2848"],
    accentHex: "#6688cc",
    ambientHex: "#334455",
    propTags: ["moon-base", "industrial-panels", "cool-depth"],
    hazards: false,
    competitive: true,
  },
  "flagline-solar-outpost": {
    stageId: "flagline-solar-outpost",
    layoutId: "flagline-solar-outpost",
    title: "Solar Outpost",
    skyGradient: ["#281808", "#483018"],
    accentHex: "#ffaa44",
    ambientHex: "#665544",
    propTags: ["solar-pylons", "warm-facility", "foreground-beams"],
    hazards: false,
    competitive: true,
  },
  "flagline-lunar-base": {
    stageId: "flagline-lunar-base",
    layoutId: "flagline-lunar-base",
    title: "Lunar Base",
    skyGradient: ["#080818", "#181830"],
    accentHex: "#5566aa",
    ambientHex: "#222233",
    propTags: ["fortress", "heavy-walls", "moon-stronghold"],
    hazards: false,
    competitive: true,
  },
  "flagline-solar-base": {
    stageId: "flagline-solar-base",
    layoutId: "flagline-solar-base",
    title: "Solar Base",
    skyGradient: ["#302010", "#504020"],
    accentHex: "#ffcc55",
    ambientHex: "#776644",
    propTags: ["solar-fortress", "heroic-beams", "midground-towers"],
    hazards: false,
    competitive: true,
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
