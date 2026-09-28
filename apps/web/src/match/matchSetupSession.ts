import type { CreatedFighter, GameConfig, GameRuleset } from "@anime-aggressors/game-core";
import {
  gameConfigFromRuleset,
  getDefaultCreatedFighter,
  getStage,
} from "@anime-aggressors/game-core";
import { getActiveRuleset, setActiveRulesetId } from "../storage/rulesetStorage.ts";
import { getProfileForSlot } from "../storage/inputProfileStorage.ts";
import { setCustomFlow, setMatchFighters, setMatchRuleset } from "./matchSession.ts";

const STORAGE_KEY = "anime-aggressors.activeMatchSetup";

export type MatchSetupMode = "stock" | "time" | "stamina" | "flaglineClash" | "party";

export type MatchSetupSession = {
  rulesetId?: string;
  ruleset?: GameRuleset;

  stageId?: string;
  stageName?: string;

  playerCount: 2 | 3 | 4 | 5 | 6 | 7 | 8;

  fighters: {
    playerId: number;
    fighterId?: string;
    fighter?: CreatedFighter;
    teamId?: "solar" | "lunar";
    isBot?: boolean;
    cpuLevel?: 1 | 2 | 3;
  }[];

  inputProfiles: {
    playerId: number;
    profileId?: string;
    profileName?: string;
  }[];

  mode: MatchSetupMode;
};

function isPartySetup(ruleset: GameRuleset): boolean {
  return ruleset.matchType === "party" || ruleset.authorityMode === "HOST_AUTHORITATIVE_PARTY";
}

function buildSeatSlots(playerCount: number): MatchSetupSession["fighters"] {
  const n = Math.min(8, Math.max(2, playerCount));
  return Array.from({ length: n }, (_, playerId) => {
    const fighter = getDefaultCreatedFighter(playerId % 4);
    return { playerId, fighterId: fighter.id, fighter };
  });
}

function buildInputProfiles(playerCount: number): MatchSetupSession["inputProfiles"] {
  const n = Math.min(8, Math.max(2, playerCount));
  return Array.from({ length: n }, (_, playerId) => {
    const slot = ((playerId % 4) + 1) as 1 | 2 | 3 | 4;
    const profile = getProfileForSlot(slot);
    return { playerId, profileId: profile.id, profileName: profile.name };
  });
}

export function createDefaultMatchSetup(): MatchSetupSession {
  const ruleset = getActiveRuleset();
  const playerCount = isPartySetup(ruleset) ? ruleset.playerCount : Math.min(ruleset.playerCount, 2);
  return {
    rulesetId: ruleset.id,
    ruleset: { ...ruleset },
    stageId: ruleset.stageId,
    stageName: getStage(ruleset.stageId).name,
    playerCount: playerCount as MatchSetupSession["playerCount"],
    fighters: buildSeatSlots(playerCount),
    inputProfiles: buildInputProfiles(playerCount),
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
  const needed = isPartySetup(setup.ruleset) ? setup.playerCount : 2;
  for (let i = 0; i < needed; i++) {
    if (!setup.fighters.find((f) => f.playerId === i)?.fighter) return false;
  }
  return true;
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
  const config = gameConfigFromRuleset(ruleset, fighters, 42);
  const bot = setup.fighters.find((f) => f.isBot);
  if (bot) {
    config.cpuOpponents = [
      {
        playerId: bot.playerId,
        difficulty: bot.cpuLevel ?? 1,
        seed: config.seed,
      },
    ];
  }
  return config;
}

export function applySetupToMatchSession(setup: MatchSetupSession): void {
  if (!setup.ruleset) return;
  setCustomFlow(false);
  setMatchRuleset({ ...setup.ruleset, stageId: setup.stageId ?? setup.ruleset.stageId });
  setActiveRulesetId(setup.ruleset.id);
  // Legacy web battle session is still 2-slot; Party Mode uses PartyLink Arena runtime.
  // For party setups we still seed P1/P2 for any legacy bridge, then rely on PartyLink for 3–8.
  const p1 = setup.fighters.find((f) => f.playerId === 0)?.fighter;
  const p2 = setup.fighters.find((f) => f.playerId === 1)?.fighter;
  if (p1 && p2) setMatchFighters(p1, p2);
}

/** Expand fighter seats when Party Mode playerCount changes (2–8). */
export function resizeMatchSetupSeats(
  setup: MatchSetupSession,
  playerCount: 2 | 3 | 4 | 5 | 6 | 7 | 8,
): MatchSetupSession {
  const fighters = buildSeatSlots(playerCount).map((slot) => {
    const existing = setup.fighters.find((f) => f.playerId === slot.playerId);
    return existing?.fighter ? { ...slot, fighter: existing.fighter, fighterId: existing.fighterId } : slot;
  });
  return {
    ...setup,
    playerCount,
    fighters,
    inputProfiles: buildInputProfiles(playerCount),
  };
}
