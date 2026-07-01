import { APP_ROUTES } from "../routes.ts";
import type { AppRouteMode } from "../routes.ts";
import { loadMatchSetup, isMatchSetupReady } from "../match/matchSetupSession.ts";
import { loadDerbySetup, isDerbySetupReady } from "../modes/impactDummyDerbySetup.ts";
import { guardBattleEntry } from "./modeEntryGuards.ts";
import { firstRouteForMode, type GameModeId } from "./modeRouteMap.ts";

export type ModeFlowResolution = {
  route: string;
  mode: AppRouteMode;
};

export function resolveModeEntry(modeId: GameModeId): ModeFlowResolution {
  if (modeId === "startMatch") {
    const setup = loadMatchSetup();
    if (!setup.fighters?.length || setup.fighters.length < 2 || !setup.fighters[0]?.fighter) {
      return { route: APP_ROUTES.fighterSelect, mode: "fighter-select" };
    }
    if (!setup.stageId) {
      return { route: APP_ROUTES.stageSelect, mode: "stage-select" };
    }
    if (!isMatchSetupReady(setup)) {
      return { route: APP_ROUTES.matchSetupControls, mode: "match-setup-controls" };
    }
    return { route: APP_ROUTES.battle, mode: "battle" };
  }

  if (modeId === "impactDummyDerby") {
    const derby = loadDerbySetup();
    if (!isDerbySetupReady(derby)) {
      return { route: APP_ROUTES.impactDummyDerbyFighterSelect, mode: "impact-dummy-derby-fighter-select" };
    }
    return { route: APP_ROUTES.impactDummyDerby, mode: "impact-dummy-derby" };
  }

  if (modeId === "training") {
    const setup = loadMatchSetup();
    if (!setup.fighters?.length) {
      return { route: APP_ROUTES.matchSetupFighters, mode: "match-setup-fighters" };
    }
    return { route: firstRouteForMode("training"), mode: "training" };
  }

  return { route: firstRouteForMode(modeId), mode: modeId === "customGame" ? "custom-game" : "flagline-setup" };
}

export function resolveBattleRoute(): ModeFlowResolution {
  const guard = guardBattleEntry(loadMatchSetup());
  if (!guard.ok && guard.redirectRoute && guard.redirectMode) {
    return { route: guard.redirectRoute, mode: guard.redirectMode };
  }
  return { route: APP_ROUTES.battle, mode: "battle" };
}

export function resolveDerbyRoute(): ModeFlowResolution {
  const derby = loadDerbySetup();
  if (!isDerbySetupReady(derby)) {
    return { route: APP_ROUTES.impactDummyDerbyFighterSelect, mode: "impact-dummy-derby-fighter-select" };
  }
  return { route: APP_ROUTES.impactDummyDerby, mode: "impact-dummy-derby" };
}
