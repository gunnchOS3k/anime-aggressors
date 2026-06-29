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
  if (!setup?.rulesetId || !setup.ruleset) {
    return { ok: false, redirectRoute: APP_ROUTES.matchSetupRules, redirectMode: "match-setup-rules", reason: "missing rules" };
  }
  if (!setup.stageId) {
    return { ok: false, redirectRoute: APP_ROUTES.matchSetupStage, redirectMode: "match-setup-stage", reason: "missing stage" };
  }
  if (!setup.fighters || setup.fighters.length < 2) {
    return { ok: false, redirectRoute: APP_ROUTES.matchSetupFighters, redirectMode: "match-setup-fighters", reason: "missing fighters" };
  }
  return { ok: true };
}

export function guardDerbyEntry(hasFighter: boolean): ModeEntryGuardResult {
  if (!hasFighter) {
    return { ok: false, redirectRoute: APP_ROUTES.createFighter, redirectMode: "create-fighter", reason: "pick fighter" };
  }
  return { ok: true };
}
