import {
  RULESET_PRESETS,
  getDefaultCreatedFighter,
  type CreatedFighter,
  type GameRuleset,
} from "@anime-aggressors/game-core";
import { setCustomFlow, setMatchFighters, setMatchRuleset } from "./matchSession.ts";

export function getTrainingRuleset(): GameRuleset {
  return { ...(RULESET_PRESETS.find((r) => r.id === "training-rules") ?? RULESET_PRESETS[0]!) };
}

export function createTrainingFighters(): { p1: CreatedFighter; p2: CreatedFighter } {
  return {
    p1: getDefaultCreatedFighter(0),
    p2: getDefaultCreatedFighter(1),
  };
}

export function applyTrainingLaunchSetup(): { p1: CreatedFighter; p2: CreatedFighter; ruleset: GameRuleset } {
  const ruleset = getTrainingRuleset();
  const { p1, p2 } = createTrainingFighters();
  setMatchRuleset(ruleset);
  setMatchFighters(p1, p2);
  setCustomFlow(true);
  return { p1, p2, ruleset };
}
