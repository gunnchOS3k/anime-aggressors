import { loadMatchSetup, isMatchSetupReady } from "../match/matchSetupSession.ts";
import { loadDerbySetup, isDerbySetupReady } from "../modes/impactDummyDerbySetup.ts";
import { APP_ROUTES } from "../routes.ts";
import type { AppRouteMode } from "../routes.ts";
import type { ModeIntent } from "./ModeIntent.ts";
import type { RequiredSelection } from "./RequiredSelections.ts";

export type StartFlowGuardResult = {
  ok: boolean;
  missing?: RequiredSelection;
  redirectRoute?: string;
  redirectMode?: AppRouteMode;
};

const ROUTE_BY_SELECTION: Partial<Record<RequiredSelection, { redirectRoute: string; redirectMode: AppRouteMode }>> = {
  rules: { redirectRoute: APP_ROUTES.matchSetupRules, redirectMode: "match-setup-rules" },
  stage: { redirectRoute: APP_ROUTES.matchSetupStage, redirectMode: "match-setup-stage" },
  fighters: { redirectRoute: APP_ROUTES.matchSetupFighters, redirectMode: "match-setup-fighters" },
  controls: { redirectRoute: APP_ROUTES.matchSetupControls, redirectMode: "match-setup-controls" },
  derbyFighter: {
    redirectRoute: APP_ROUTES.impactDummyDerbyFighterSelect,
    redirectMode: "impact-dummy-derby-fighter-select",
  },
};

function missingSelection(selection: RequiredSelection): StartFlowGuardResult {
  return { ok: false, missing: selection, ...ROUTE_BY_SELECTION[selection]! };
}

export function guardModeStart(mode: ModeIntent): StartFlowGuardResult {
  if (mode === "impactDummyDerby") {
    const setup = loadDerbySetup();
    if (!isDerbySetupReady(setup)) {
      return missingSelection("derbyFighter");
    }
    return { ok: true };
  }

  if (mode === "startMatch" || mode === "customGame") {
    const setup = loadMatchSetup();
    if (!setup.rulesetId) {
      return missingSelection("rules");
    }
    if (!setup.stageId) {
      return missingSelection("stage");
    }
    if (!setup.fighters?.length || setup.fighters.length < 2) {
      return missingSelection("fighters");
    }
    if (!isMatchSetupReady(setup)) {
      return missingSelection("controls");
    }
    return { ok: true };
  }

  if (mode === "training") {
    const setup = loadMatchSetup();
    if (!setup.fighters?.length) {
      return missingSelection("fighters");
    }
    return { ok: true };
  }

  return { ok: true };
}
