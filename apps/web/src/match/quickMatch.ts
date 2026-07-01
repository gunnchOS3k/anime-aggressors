import {
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  getStage,
  listStages,
  type GameRuleset,
} from "@anime-aggressors/game-core";
import {
  createDefaultMatchSetup,
  saveMatchSetup,
  applySetupToMatchSession,
  isMatchSetupReady,
  clearMatchSetup,
  type MatchSetupSession,
} from "./matchSetupSession.ts";
import { APP_ROUTES, navigateToHash } from "../routes.ts";

/** Stock Quick Match defaults — skyline arena, 2 players, 3 stocks, no items. */
export function createQuickMatchSetup(): MatchSetupSession {
  const ruleset: GameRuleset = {
    ...DEFAULT_RULESET,
    id: DEFAULT_RULESET.id,
    stageId: "skyline-arena",
    playerCount: 2,
    stocks: 3,
    matchType: "stock",
    itemFrequency: "off",
    timerSeconds: 180,
  };
  const p1 = getDefaultCreatedFighter(0);
  const p2 = getDefaultCreatedFighter(1);
  return {
    rulesetId: ruleset.id,
    ruleset,
    stageId: "skyline-arena",
    stageName: getStage("skyline-arena").name,
    playerCount: 2,
    mode: "stock",
    fighters: [
      { playerId: 0, fighterId: p1.id, fighter: p1 },
      { playerId: 1, fighterId: p2.id, fighter: p2 },
    ],
    inputProfiles: createDefaultMatchSetup().inputProfiles,
  };
}

export function isQuickMatchSetupValid(setup: MatchSetupSession): boolean {
  if (!setup.ruleset || setup.ruleset.matchType !== "stock") return false;
  if (setup.stageId !== "skyline-arena") return false;
  if (setup.playerCount !== 2) return false;
  if (setup.ruleset.stocks !== 3) return false;
  if (setup.ruleset.itemFrequency !== "off") return false;
  const p1 = setup.fighters.find((f) => f.playerId === 0)?.fighter;
  const p2 = setup.fighters.find((f) => f.playerId === 1)?.fighter;
  return !!(p1 && p2);
}

/** Apply Quick Match defaults and persist — safe from corrupt localStorage. */
export function applyQuickMatchDefaults(): MatchSetupSession {
  const setup = createQuickMatchSetup();
  saveMatchSetup(setup);
  applySetupToMatchSession(setup);
  return setup;
}

/** Load setup for battle; fall back to Quick Match defaults when incomplete or corrupt. */
export function ensureBattleReadySetup(): MatchSetupSession {
  let setup: MatchSetupSession;
  try {
    if (typeof localStorage === "undefined") {
      return applyQuickMatchDefaults();
    }
    const raw = localStorage.getItem("anime-aggressors.activeMatchSetup");
    if (!raw) return applyQuickMatchDefaults();
    setup = JSON.parse(raw) as MatchSetupSession;
  } catch {
    return applyQuickMatchDefaults();
  }

  if (!setup.ruleset || !setup.stageId || !setup.fighters?.length) {
    return applyQuickMatchDefaults();
  }
  const stageIds = new Set(listStages().map((s) => s.id));
  if (!stageIds.has(setup.stageId)) {
    return applyQuickMatchDefaults();
  }
  const p1 = setup.fighters.find((f) => f.playerId === 0)?.fighter;
  const p2 = setup.fighters.find((f) => f.playerId === 1)?.fighter;
  if (!p1?.id || !p2?.id) {
    return applyQuickMatchDefaults();
  }
  if (!isMatchSetupReady(setup)) {
    return applyQuickMatchDefaults();
  }
  applySetupToMatchSession(setup);
  return setup;
}

export function startQuickMatch(): void {
  applyQuickMatchDefaults();
  navigateToHash(APP_ROUTES.battle);
}

/** Clear persisted match setup and in-memory session — recover from corrupt state. */
export function resetGameState(): void {
  clearMatchSetup();
  applyQuickMatchDefaults();
}
