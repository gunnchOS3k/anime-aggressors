import { APP_ROUTES, type AppRouteMode } from "../routes.ts";

export type MenuItemTier = "primary" | "secondary" | "player" | "labs";

export type MainMenuItem = {
  id: string;
  label: string;
  route: string;
  mode: AppRouteMode;
  tier: MenuItemTier;
};

export const MAIN_MENU_PRIMARY: MainMenuItem[] = [
  {
    id: "btn-godot-combat",
    label: "Play Godot Combat Prototype",
    route: APP_ROUTES.godot,
    mode: "godot",
    tier: "primary",
  },
  {
    id: "btn-play-match",
    label: "Start Match (Legacy Web Prototype)",
    route: APP_ROUTES.matchSetupRules,
    mode: "match-setup-rules",
    tier: "primary",
  },
];

export const MAIN_MENU_SECONDARY: MainMenuItem[] = [
  {
    id: "btn-custom-game",
    label: "Custom Game",
    route: APP_ROUTES.customGame,
    mode: "custom-game",
    tier: "secondary",
  },
  {
    id: "btn-flagline-clash",
    label: "Flagline Clash",
    route: APP_ROUTES.flaglineSetup,
    mode: "flagline-setup",
    tier: "secondary",
  },
  {
    id: "btn-impact-dummy-derby",
    label: "Impact Dummy Derby",
    route: APP_ROUTES.impactDummyDerby,
    mode: "impact-dummy-derby",
    tier: "secondary",
  },
  {
    id: "btn-training",
    label: "Training Mode",
    route: APP_ROUTES.training,
    mode: "training",
    tier: "secondary",
  },
  {
    id: "btn-create-fighter",
    label: "Create Fighter",
    route: APP_ROUTES.createFighter,
    mode: "create-fighter",
    tier: "secondary",
  },
];

export const MAIN_MENU_PLAYER: MainMenuItem[] = [
  {
    id: "btn-career",
    label: "Career",
    route: APP_ROUTES.career,
    mode: "career",
    tier: "player",
  },
  {
    id: "btn-controls",
    label: "Controls",
    route: APP_ROUTES.controls,
    mode: "controls",
    tier: "player",
  },
  {
    id: "btn-replay-vault",
    label: "Replay Vault",
    route: APP_ROUTES.replayVault,
    mode: "career-replays",
    tier: "player",
  },
  {
    id: "btn-saved-games",
    label: "Saved Games",
    route: APP_ROUTES.savedGames,
    mode: "career-saves",
    tier: "player",
  },
];

export const MAIN_MENU_LABS: MainMenuItem[] = [
  {
    id: "btn-controller",
    label: "Controller Test",
    route: APP_ROUTES.controllerTest,
    mode: "controller",
    tier: "labs",
  },
  {
    id: "btn-rollback",
    label: "Rollback Debug",
    route: APP_ROUTES.rollbackDebug,
    mode: "rollback",
    tier: "labs",
  },
  {
    id: "btn-edgeio",
    label: "Edge-IO Lab",
    route: APP_ROUTES.edgeioLab,
    mode: "edgeio",
    tier: "labs",
  },
  {
    id: "btn-prototype",
    label: "Prototype Lab",
    route: APP_ROUTES.prototypeLab,
    mode: "prototype",
    tier: "labs",
  },
  {
    id: "btn-feedback",
    label: "Feedback / Playtest",
    route: APP_ROUTES.feedback,
    mode: "feedback",
    tier: "labs",
  },
];

export const ALL_MAIN_MENU_ITEMS: MainMenuItem[] = [
  ...MAIN_MENU_PRIMARY,
  ...MAIN_MENU_SECONDARY,
  ...MAIN_MENU_PLAYER,
  ...MAIN_MENU_LABS,
];
