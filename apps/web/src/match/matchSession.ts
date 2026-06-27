import type { CreatedFighter, GameRuleset } from "@anime-aggressors/game-core";
import { getActiveRuleset } from "../storage/rulesetStorage.ts";

export type MatchSetup = {
  ruleset: GameRuleset;
  p1Fighter: CreatedFighter | null;
  p2Fighter: CreatedFighter | null;
  customFlow: boolean;
};

let setup: MatchSetup = {
  ruleset: getActiveRuleset(),
  p1Fighter: null,
  p2Fighter: null,
  customFlow: false,
};

export function getMatchSetup(): MatchSetup {
  return { ...setup, ruleset: { ...setup.ruleset } };
}

export function setMatchRuleset(ruleset: GameRuleset): void {
  setup = { ...setup, ruleset: { ...ruleset } };
}

export function setMatchFighters(p1: CreatedFighter, p2: CreatedFighter): void {
  setup = { ...setup, p1Fighter: p1, p2Fighter: p2 };
}

export function setCustomFlow(enabled: boolean): void {
  setup = { ...setup, customFlow: enabled };
}

export function resetMatchSetup(): void {
  setup = {
    ruleset: getActiveRuleset(),
    p1Fighter: null,
    p2Fighter: null,
    customFlow: false,
  };
}
