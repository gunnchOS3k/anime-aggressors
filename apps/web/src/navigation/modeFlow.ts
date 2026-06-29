import { loadMatchSetup, isMatchSetupReady } from "../match/matchSetupSession.ts";
import { APP_ROUTES } from "../routes.ts";
import type { AppRouteMode } from "../routes.ts";
import { guardBattleEntry, guardDerbyEntry } from "./modeEntryGuards.ts";
import { firstRouteForMode, type GameModeId } from "./modeRouteMap.ts";

export type ModeFlowResolution = {
  route: string;
  mode: AppRouteMode;
};

export function resolveModeEntry(modeId: GameModeId, hasDerbyFighter = true): ModeFlowResolution {
  if (modeId === "startMatch") {
    const setup = loadMatchSetup();
    if (!setup.rulesetId) {
      return { route: APP_ROUTES.matchSetupRules, mode: "match-setup-rules" };
    }
    if (!setup.stageId) {
      return { route: APP_ROUTES.matchSetupStage, mode: "match-setup-stage" };
    }
    if (!setup.fighters?.length || setup.fighters.length < 2) {
      return { route: APP_ROUTES.matchSetupFighters, mode: "match-setup-fighters" };
    }
    if (!isMatchSetupReady(setup)) {
      return { route: APP_ROUTES.matchSetupControls, mode: "match-setup-controls" };
    }
    return { route: APP_ROUTES.battle, mode: "battle" };
  }

  if (modeId === "impactDummyDerby") {
    const guard = guardDerbyEntry(hasDerbyFighter);
    if (!guard.ok && guard.redirectRoute && guard.redirectMode) {
      return { route: guard.redirectRoute, mode: guard.redirectMode };
    }
    return { route: firstRouteForMode("impactDummyDerby"), mode: "impact-dummy-derby" };
  }

  return { route: firstRouteForMode(modeId), mode: modeId === "training" ? "training" : modeId === "customGame" ? "custom-game" : "flagline-setup" };
}

export function resolveBattleRoute(): ModeFlowResolution {
  const guard = guardBattleEntry(loadMatchSetup());
  if (!guard.ok && guard.redirectRoute && guard.redirectMode) {
    return { route: guard.redirectRoute, mode: guard.redirectMode };
  }
  return { route: APP_ROUTES.battle, mode: "battle" };
}
