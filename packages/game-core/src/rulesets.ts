import type { GameConfig } from "./types.js";
import type { CreatedFighter } from "./createdFighter.js";
import { SIM_HZ } from "./constants.js";

export type MatchType = "stock" | "time" | "stamina" | "flaglineClash" | "party";
export type ItemFrequency = "off" | "low" | "medium" | "high";
export type ElementMode = "on" | "visualOnly" | "off";
export type TeamMode = "off" | "2v2" | "3v3" | "4v4" | "2v2v2v2";
/** Party Mode supports 2–8 human seats; competitive presets remain 2/4. */
export type RulesetPlayerCount = 2 | 3 | 4 | 5 | 6 | 7 | 8;

export type GameRuleset = {
  id: string;
  name: string;
  matchType: MatchType;
  playerCount: RulesetPlayerCount;
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
  /** Party Mode allows duplicate fighter selection with palette/outline/badge identity. */
  allowDuplicateFighters?: boolean;
  /** Party Mode uses HOST_AUTHORITATIVE_PARTY; competitive keeps rollback/netplay. */
  authorityMode?: "HOST_AUTHORITATIVE_PARTY" | "DETERMINISTIC_ROLLBACK";
  flagline?: {
    enabled: boolean;
    captureToWin: number;
    captureRatePerSecond: number;
    decayRatePerSecond: number;
    overtimeEnabled: boolean;
    teamWipeWinsRoom: boolean;
    botsEnabled: boolean;
  };
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
  {
    ...DEFAULT_RULESET,
    id: "flagline-clash-2v2",
    name: "Flagline Clash 2v2",
    matchType: "flaglineClash",
    playerCount: 4,
    teamMode: "2v2",
    stocks: 3,
    timerSeconds: 180,
    stageId: "flagline-center-clash",
    flagline: {
      enabled: true,
      captureToWin: 100,
      captureRatePerSecond: 12,
      decayRatePerSecond: 4,
      overtimeEnabled: true,
      teamWipeWinsRoom: false,
      botsEnabled: true,
    },
  },
  {
    ...DEFAULT_RULESET,
    id: "party-ffa-8",
    name: "Party FFA (8P)",
    matchType: "party",
    playerCount: 8,
    teamMode: "off",
    stocks: 3,
    timerSeconds: 180,
    stageId: "party-plaza",
    allowDuplicateFighters: true,
    authorityMode: "HOST_AUTHORITATIVE_PARTY",
  },
  {
    ...DEFAULT_RULESET,
    id: "party-4v4",
    name: "Party 4v4",
    matchType: "party",
    playerCount: 8,
    teamMode: "4v4",
    stocks: 3,
    timerSeconds: 180,
    stageId: "party-plaza",
    allowDuplicateFighters: true,
    authorityMode: "HOST_AUTHORITATIVE_PARTY",
  },
  {
    ...DEFAULT_RULESET,
    id: "party-2v2v2v2",
    name: "Party 2v2v2v2",
    matchType: "party",
    playerCount: 8,
    teamMode: "2v2v2v2",
    stocks: 3,
    timerSeconds: 180,
    stageId: "party-plaza",
    allowDuplicateFighters: true,
    authorityMode: "HOST_AUTHORITATIVE_PARTY",
  },
];

export function cloneRuleset(r: GameRuleset): GameRuleset {
  return { ...r };
}

export function validateRuleset(r: GameRuleset): boolean {
  if (r.stocks < 1 || r.stocks > 99) return false;
  if (r.damageRatio < 0.25 || r.damageRatio > 4) return false;
  if (r.launchRatio < 0.25 || r.launchRatio > 4) return false;
  if (!["stock", "time", "stamina", "flaglineClash", "party"].includes(r.matchType)) return false;
  if (r.playerCount < 2 || r.playerCount > 8) return false;
  return true;
}

export function rulesetToMatchDurationFrames(r: GameRuleset): number {
  if (r.timerSeconds === null) return 99 * 60 * SIM_HZ;
  return r.timerSeconds * SIM_HZ;
}

export function effectivePlayerCount(r: GameRuleset): number {
  if (r.matchType === "flaglineClash") return 4;
  if (r.matchType === "party" || r.authorityMode === "HOST_AUTHORITATIVE_PARTY") {
    return Math.min(Math.max(r.playerCount, 2), 8);
  }
  if (r.playerCount > 2 && r.teamMode !== "off") return Math.min(r.playerCount, 8);
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
