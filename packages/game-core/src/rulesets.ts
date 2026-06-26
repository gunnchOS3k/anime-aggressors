import type { GameConfig } from "./types.js";
import type { CreatedFighter } from "./createdFighter.js";
import { SIM_HZ } from "./constants.js";

export type MatchType = "stock" | "time" | "stamina";
export type ItemFrequency = "off" | "low" | "medium" | "high";
export type ElementMode = "on" | "visualOnly" | "off";
export type TeamMode = "off" | "2v2";

export type GameRuleset = {
  id: string;
  name: string;
  matchType: MatchType;
  playerCount: 2 | 3 | 4;
  stocks: number;
  timerSeconds: number | null;
  staminaHp: number;
  stageId: string;
  hazardsEnabled: boolean;
  itemFrequency: ItemFrequency;
  damageRatio: number;
  launchRatio: number;
  elementMode: ElementMode;
  teamMode: TeamMode;
  createdFighters: "allowed" | "defaultsOnly";
  createdAt: string;
  updatedAt: string;
};

const now = () => new Date().toISOString();

export const DEFAULT_RULESET: GameRuleset = {
  id: "default-stock-3",
  name: "Stock Battle",
  matchType: "stock",
  playerCount: 2,
  stocks: 3,
  timerSeconds: 180,
  staminaHp: 100,
  stageId: "skyline-arena",
  hazardsEnabled: false,
  itemFrequency: "off",
  damageRatio: 1,
  launchRatio: 1,
  elementMode: "on",
  teamMode: "off",
  createdFighters: "allowed",
  createdAt: now(),
  updatedAt: now(),
};

export const RULESET_PRESETS: GameRuleset[] = [
  DEFAULT_RULESET,
  {
    ...DEFAULT_RULESET,
    id: "friendly-3-stock",
    name: "Friendly 3 Stock",
    stocks: 3,
    timerSeconds: null,
    damageRatio: 0.75,
    launchRatio: 0.75,
  },
  {
    ...DEFAULT_RULESET,
    id: "quick-2-minute",
    name: "Quick 2 Minute",
    matchType: "time",
    timerSeconds: 120,
    stocks: 1,
  },
  {
    ...DEFAULT_RULESET,
    id: "stamina-100",
    name: "Stamina 100",
    matchType: "stamina",
    staminaHp: 100,
    stocks: 1,
    timerSeconds: 180,
  },
  {
    ...DEFAULT_RULESET,
    id: "training-rules",
    name: "Training Rules",
    matchType: "stock",
    stocks: 99,
    timerSeconds: null,
    damageRatio: 0.5,
    launchRatio: 0.5,
    elementMode: "visualOnly",
    stageId: "training-grid",
  },
  {
    ...DEFAULT_RULESET,
    id: "chaos-items",
    name: "Chaos Items",
    itemFrequency: "high",
    damageRatio: 1.25,
    launchRatio: 1.25,
    hazardsEnabled: true,
  },
  {
    ...DEFAULT_RULESET,
    id: "competitive-1v1",
    name: "Competitive 1v1",
    stocks: 3,
    timerSeconds: 480,
    itemFrequency: "off",
    hazardsEnabled: false,
    elementMode: "on",
    damageRatio: 1,
    launchRatio: 1,
  },
];

export function cloneRuleset(r: GameRuleset): GameRuleset {
  return { ...r };
}

export function validateRuleset(r: GameRuleset): boolean {
  if (r.stocks < 1 || r.stocks > 99) return false;
  if (r.damageRatio < 0.25 || r.damageRatio > 4) return false;
  if (r.launchRatio < 0.25 || r.launchRatio > 4) return false;
  if (!["stock", "time", "stamina"].includes(r.matchType)) return false;
  return true;
}

export function rulesetToMatchDurationFrames(r: GameRuleset): number {
  if (r.timerSeconds === null) return 99 * 60 * SIM_HZ;
  return r.timerSeconds * SIM_HZ;
}

export function effectivePlayerCount(r: GameRuleset): number {
  return Math.min(r.playerCount, 2) as 2;
}

export function gameConfigFromRuleset(
  ruleset: GameRuleset,
  fighterProfiles: CreatedFighter[],
  seed: number,
): GameConfig {
  const count = effectivePlayerCount(ruleset);
  return {
    playerCount: count,
    stocks: ruleset.matchType === "stamina" ? 1 : ruleset.stocks,
    matchDurationFrames: rulesetToMatchDurationFrames(ruleset),
    stageId: ruleset.stageId,
    characterIds: fighterProfiles.slice(0, count).map((f) => `created:${f.id}`),
    fighterProfiles: fighterProfiles.slice(0, count),
    ruleset: cloneRuleset(ruleset),
    seed,
  };
}

export function elementGameplayEnabled(mode: ElementMode): boolean {
  return mode === "on";
}

export function elementVisualsEnabled(mode: ElementMode): boolean {
  return mode !== "off";
}
