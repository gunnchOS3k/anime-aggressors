import { isDerbySetupReady, loadDerbySetup, type ImpactDummyDerbySetup } from "../modes/impactDummyDerbySetup.ts";
import type { MatchSetupSession } from "../match/matchSetupSession.ts";
import { APP_ROUTES } from "../routes.ts";
import type { AppRouteMode } from "../routes.ts";

export type ModeEntryGuardResult = {
  ok: boolean;
  redirectRoute?: string;
  redirectMode?: AppRouteMode;
  reason?: string;
};

export function guardBattleEntry(setup: MatchSetupSession | null): ModeEntryGuardResult {
  if (!setup?.fighters || setup.fighters.length < 2 || !setup.fighters[0]?.fighter) {
    return { ok: false, redirectRoute: APP_ROUTES.fighterSelect, redirectMode: "fighter-select", reason: "missing fighters" };
  }
  if (!setup.stageId) {
    return { ok: false, redirectRoute: APP_ROUTES.stageSelect, redirectMode: "stage-select", reason: "missing stage" };
  }
  if (!setup.rulesetId || !setup.ruleset) {
    return { ok: false, redirectRoute: APP_ROUTES.matchSetupRules, redirectMode: "match-setup-rules", reason: "missing rules" };
  }
  return { ok: true };
}

export function guardDerbyEntry(setup?: ImpactDummyDerbySetup | null): ModeEntryGuardResult {
  const derby = setup ?? loadDerbySetup();
  if (!derby || !isDerbySetupReady(derby)) {
    return {
      ok: false,
      redirectRoute: APP_ROUTES.impactDummyDerbyFighterSelect,
      redirectMode: "impact-dummy-derby-fighter-select",
      reason: "pick fighter",
    };
  }
  return { ok: true };
}
