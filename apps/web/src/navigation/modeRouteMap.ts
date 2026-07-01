import { APP_ROUTES } from "../routes.ts";
import type { AppRouteMode } from "../routes.ts";

export type GameModeId =
  | "startMatch"
  | "customGame"
  | "flaglineClash"
  | "impactDummyDerby"
  | "training";

export type ModeFlowStep = {
  route: string;
  mode: AppRouteMode;
  label: string;
};

export const MODE_ROUTE_MAP: Record<GameModeId, ModeFlowStep[]> = {
  startMatch: [
    { route: APP_ROUTES.fighterSelect, mode: "fighter-select", label: "Fighters" },
    { route: APP_ROUTES.stageSelect, mode: "stage-select", label: "Stage" },
    { route: APP_ROUTES.matchSetupControls, mode: "match-setup-controls", label: "Ready" },
    { route: APP_ROUTES.battle, mode: "battle", label: "Battle" },
  ],
  customGame: [
    { route: APP_ROUTES.customGame, mode: "custom-game", label: "Custom Rules" },
    { route: APP_ROUTES.fighterSelect, mode: "fighter-select", label: "Fighters" },
    { route: APP_ROUTES.controlsCheck, mode: "controls-check", label: "Controls" },
    { route: APP_ROUTES.battle, mode: "battle", label: "Battle" },
  ],
  flaglineClash: [
    { route: APP_ROUTES.flaglineSetup, mode: "flagline-setup", label: "Setup" },
    { route: APP_ROUTES.flaglineTeams, mode: "flagline-teams", label: "Teams" },
    { route: APP_ROUTES.flaglineClash, mode: "flagline-clash", label: "Battle" },
  ],
  impactDummyDerby: [
    { route: APP_ROUTES.impactDummyDerbyFighterSelect, mode: "impact-dummy-derby-fighter-select", label: "Fighter" },
    { route: APP_ROUTES.impactDummyDerby, mode: "impact-dummy-derby", label: "Derby" },
  ],
  training: [
    { route: APP_ROUTES.training, mode: "training", label: "Training" },
  ],
};

export function firstRouteForMode(modeId: GameModeId): string {
  return MODE_ROUTE_MAP[modeId][0]?.route ?? APP_ROUTES.home;
}
