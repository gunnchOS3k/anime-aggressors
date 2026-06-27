import type { CreatedFighter, GameConfig, GameRuleset } from "@anime-aggressors/game-core";
import {
  DEFAULT_RULESET,
  gameConfigFromRuleset,
  getDefaultCreatedFighter,
  getStage,
} from "@anime-aggressors/game-core";
import { getActiveRuleset, setActiveRulesetId } from "../storage/rulesetStorage.ts";
import { getProfileForSlot } from "../storage/inputProfileStorage.ts";
import { setCustomFlow, setMatchFighters, setMatchRuleset } from "./matchSession.ts";

const STORAGE_KEY = "anime-aggressors.activeMatchSetup";

export type MatchSetupMode = "stock" | "time" | "stamina" | "flaglineClash";

export type MatchSetupSession = {
  rulesetId?: string;
  ruleset?: GameRuleset;

  stageId?: string;
  stageName?: string;

  playerCount: 2 | 3 | 4;

  fighters: {
    playerId: number;
    fighterId?: string;
    fighter?: CreatedFighter;
    teamId?: "solar" | "lunar";
    isBot?: boolean;
  }[];

  inputProfiles: {
    playerId: number;
    profileId?: string;
    profileName?: string;
  }[];

  mode: MatchSetupMode;
};

export function createDefaultMatchSetup(): MatchSetupSession {
  const ruleset = getActiveRuleset();
  const p1 = getDefaultCreatedFighter(0);
  const p2 = getDefaultCreatedFighter(1);
  return {
    rulesetId: ruleset.id,
    ruleset: { ...ruleset },
    stageId: ruleset.stageId,
    stageName: getStage(ruleset.stageId).name,
    playerCount: ruleset.playerCount,
    fighters: [
      { playerId: 0, fighterId: p1.id, fighter: p1 },
      { playerId: 1, fighterId: p2.id, fighter: p2 },
    ],
    inputProfiles: [
      { playerId: 0, profileId: getProfileForSlot(1).id, profileName: getProfileForSlot(1).name },
      { playerId: 1, profileId: getProfileForSlot(2).id, profileName: getProfileForSlot(2).name },
    ],
    mode: ruleset.matchType,
  };
}

export function loadMatchSetup(): MatchSetupSession {
  if (typeof localStorage === "undefined") return createDefaultMatchSetup();
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return createDefaultMatchSetup();
    const parsed = JSON.parse(raw) as MatchSetupSession;
    if (!parsed.fighters?.length) return createDefaultMatchSetup();
    return parsed;
  } catch {
    return createDefaultMatchSetup();
  }
}

export function saveMatchSetup(setup: MatchSetupSession): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(setup));
}

export function clearMatchSetup(): void {
  localStorage.removeItem(STORAGE_KEY);
}

export function isMatchSetupReady(setup: MatchSetupSession): boolean {
  if (!setup.ruleset || !setup.stageId) return false;
  const p1 = setup.fighters.find((f) => f.playerId === 0)?.fighter;
  const p2 = setup.fighters.find((f) => f.playerId === 1)?.fighter;
  return !!(p1 && p2);
}

export function buildGameConfigFromSetup(setup: MatchSetupSession): GameConfig {
  if (!setup.ruleset) throw new Error("Match setup missing ruleset");
  const fighters = setup.fighters
    .slice()
    .sort((a, b) => a.playerId - b.playerId)
    .map((f) => f.fighter ?? getDefaultCreatedFighter(f.playerId));
  const ruleset: GameRuleset = {
    ...setup.ruleset,
    stageId: setup.stageId ?? setup.ruleset.stageId,
  };
  return gameConfigFromRuleset(ruleset, fighters, 42);
}

export function applySetupToMatchSession(setup: MatchSetupSession): void {
  if (!setup.ruleset) return;
  setCustomFlow(false);
  setMatchRuleset({ ...setup.ruleset, stageId: setup.stageId ?? setup.ruleset.stageId });
  setActiveRulesetId(setup.ruleset.id);
  const p1 = setup.fighters.find((f) => f.playerId === 0)?.fighter;
  const p2 = setup.fighters.find((f) => f.playerId === 1)?.fighter;
  if (p1 && p2) setMatchFighters(p1, p2);
}
