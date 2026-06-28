import { APP_ROUTES } from "../../routes.ts";

export const ARENA_THEME = {
  colors: {
    background: "#090914",
    panel: "#141428",
    panelRaised: "#1c1c36",
    primary: "#ff6a2a",
    secondary: "#39d8ff",
    text: "#f5f7ff",
    muted: "#9aa0c3",
  },
  routes: {
    home: APP_ROUTES.home,
    rules: APP_ROUTES.matchSetupRules,
    stage: APP_ROUTES.matchSetupStage,
    fighters: APP_ROUTES.matchSetupFighters,
    controls: APP_ROUTES.matchSetupControls,
    battle: APP_ROUTES.battle,
  },
} as const;

export type SetupFlowStep = "rules" | "stage" | "fighters" | "controls" | "battle";

export const SETUP_FLOW_STEPS: { id: SetupFlowStep; label: string }[] = [
  { id: "rules", label: "Rules" },
  { id: "stage", label: "Map" },
  { id: "fighters", label: "Fighters" },
  { id: "controls", label: "Controls" },
  { id: "battle", label: "Battle" },
];
