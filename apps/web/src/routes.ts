/** Hash routes for GitHub Pages — no path-based SPA routing required. */
export const APP_ROUTES = {
  home: "#/",
  play: "#/play",
  matchSetupRules: "#/match-setup/rules",
  matchSetupStage: "#/match-setup/stage",
  matchSetupFighters: "#/match-setup/fighters",
  matchSetupControls: "#/match-setup/controls",
  battle: "#/battle",

  createFighter: "#/create-fighter",
  customGame: "#/custom-game",
  rulesets: "#/rulesets",
  stageSelect: "#/stage-select",
  fighterSelect: "#/fighter-select",
  controlsCheck: "#/controls-check",
  controls: "#/controls",
  controlsRemap: "#/controls/remap",
  training: "#/training",
  moves: "#/moves",
  combos: "#/combos",
  controllerTest: "#/controller-test",
  rollbackDebug: "#/rollback-debug",
  edgeioLab: "#/edgeio-lab",
  prototypeLab: "#/prototype-lab",
  impactDummyDerby: "#/impact-dummy-derby",
  impactDummyDerbySelectFighter: "#/impact-dummy-derby/select-fighter",
  impactDummyDerbyFighterSelect: "#/impact-dummy-derby/select-fighter",
  flaglineClash: "#/flagline-clash",
  flaglineSetup: "#/flagline-setup",
  flaglineTeams: "#/flagline-teams",
  feedback: "#/feedback",
  career: "#/career",
  careerFighters: "#/career/fighters",
  matchHistory: "#/career/history",
  careerHistory: "#/career/history",
  replayVault: "#/career/replays",
  careerReplays: "#/career/replays",
  savedGames: "#/career/saves",
  careerSaves: "#/career/saves",
  careerMilestones: "#/career/milestones",
  saves: "#/saves",
  replay: "#/replay",
} as const;

export type AppRouteMode =
  | "home"
  | "match-setup-rules"
  | "match-setup-stage"
  | "match-setup-fighters"
  | "match-setup-controls"
  | "battle"
  | "create-fighter"
  | "custom-game"
  | "rulesets"
  | "stage-select"
  | "fighter-select"
  | "controls-check"
  | "controls"
  | "controls-remap"
  | "match"
  | "training"
  | "moves"
  | "combos"
  | "controller"
  | "rollback"
  | "edgeio"
  | "prototype"
  | "impact-dummy-derby"
  | "impact-dummy-derby-fighter-select"
  | "flagline-clash"
  | "flagline-setup"
  | "flagline-teams"
  | "feedback"
  | "career"
  | "career-fighters"
  | "career-history"
  | "career-replays"
  | "career-saves"
  | "career-milestones"
  | "saves"
  | "replay";

const HASH_TO_MODE: Record<string, AppRouteMode> = {
  [APP_ROUTES.home]: "home",
  [APP_ROUTES.matchSetupRules]: "match-setup-rules",
  [APP_ROUTES.matchSetupStage]: "match-setup-stage",
  [APP_ROUTES.matchSetupFighters]: "match-setup-fighters",
  [APP_ROUTES.matchSetupControls]: "match-setup-controls",
  [APP_ROUTES.battle]: "battle",
  [APP_ROUTES.createFighter]: "create-fighter",
  [APP_ROUTES.customGame]: "custom-game",
  [APP_ROUTES.rulesets]: "rulesets",
  [APP_ROUTES.stageSelect]: "stage-select",
  [APP_ROUTES.fighterSelect]: "fighter-select",
  [APP_ROUTES.controlsCheck]: "controls-check",
  [APP_ROUTES.controls]: "controls",
  [APP_ROUTES.controlsRemap]: "controls-remap",
  [APP_ROUTES.play]: "match",
  [APP_ROUTES.training]: "training",
  [APP_ROUTES.moves]: "moves",
  [APP_ROUTES.combos]: "combos",
  [APP_ROUTES.controllerTest]: "controller",
  [APP_ROUTES.rollbackDebug]: "rollback",
  [APP_ROUTES.edgeioLab]: "edgeio",
  [APP_ROUTES.prototypeLab]: "prototype",
  [APP_ROUTES.impactDummyDerby]: "impact-dummy-derby",
  [APP_ROUTES.impactDummyDerbyFighterSelect]: "impact-dummy-derby-fighter-select",
  [APP_ROUTES.flaglineClash]: "flagline-clash",
  [APP_ROUTES.flaglineSetup]: "flagline-setup",
  [APP_ROUTES.flaglineTeams]: "flagline-teams",
  [APP_ROUTES.feedback]: "feedback",
  [APP_ROUTES.career]: "career",
  [APP_ROUTES.careerFighters]: "career-fighters",
  [APP_ROUTES.careerHistory]: "career-history",
  [APP_ROUTES.careerReplays]: "career-replays",
  [APP_ROUTES.careerSaves]: "career-saves",
  [APP_ROUTES.careerMilestones]: "career-milestones",
  [APP_ROUTES.saves]: "career-saves",
  [APP_ROUTES.replay]: "replay",
};

export const ROUTE_TO_MODE = HASH_TO_MODE;

export const MODE_TO_ROUTE: Record<AppRouteMode, string> = {
  home: APP_ROUTES.home,
  "match-setup-rules": APP_ROUTES.matchSetupRules,
  "match-setup-stage": APP_ROUTES.matchSetupStage,
  "match-setup-fighters": APP_ROUTES.matchSetupFighters,
  "match-setup-controls": APP_ROUTES.matchSetupControls,
  battle: APP_ROUTES.battle,
  "create-fighter": APP_ROUTES.createFighter,
  "custom-game": APP_ROUTES.customGame,
  rulesets: APP_ROUTES.rulesets,
  "stage-select": APP_ROUTES.stageSelect,
  "fighter-select": APP_ROUTES.fighterSelect,
  "controls-check": APP_ROUTES.controlsCheck,
  controls: APP_ROUTES.controls,
  "controls-remap": APP_ROUTES.controlsRemap,
  match: APP_ROUTES.play,
  training: APP_ROUTES.training,
  moves: APP_ROUTES.moves,
  combos: APP_ROUTES.combos,
  controller: APP_ROUTES.controllerTest,
  rollback: APP_ROUTES.rollbackDebug,
  edgeio: APP_ROUTES.edgeioLab,
  prototype: APP_ROUTES.prototypeLab,
  "impact-dummy-derby": APP_ROUTES.impactDummyDerby,
  "impact-dummy-derby-fighter-select": APP_ROUTES.impactDummyDerbyFighterSelect,
  "flagline-clash": APP_ROUTES.flaglineClash,
  "flagline-setup": APP_ROUTES.flaglineSetup,
  "flagline-teams": APP_ROUTES.flaglineTeams,
  feedback: APP_ROUTES.feedback,
  career: APP_ROUTES.career,
  "career-fighters": APP_ROUTES.careerFighters,
  "career-history": APP_ROUTES.careerHistory,
  "career-replays": APP_ROUTES.careerReplays,
  "career-saves": APP_ROUTES.careerSaves,
  "career-milestones": APP_ROUTES.careerMilestones,
  saves: APP_ROUTES.saves,
  replay: APP_ROUTES.replay,
};

export function assertHashRoute(route: string): void {
  if (!route.startsWith("#/")) {
    throw new Error(`Invalid app route: ${route}. Anime Aggressors uses hash routes on GitHub Pages.`);
  }
}

/** Set hash from a `#/...` route constant. */
export function navigateToHash(route: string): void {
  assertHashRoute(route);
  const hash = route.startsWith("#") ? route.slice(1) : route;
  if (window.location.hash.split("?")[0] !== `#${hash}`) {
    window.location.hash = hash;
  } else {
    window.dispatchEvent(new HashChangeEvent("hashchange"));
  }
}

/** Hash-route navigation — required for GitHub Pages project-site hosting. */
export function navigateTo(route: string): void {
  navigateToHash(route);
}

export function hashToMode(hash: string): AppRouteMode {
  const normalized = hash.split("?")[0] || APP_ROUTES.home;
  return HASH_TO_MODE[normalized] ?? "home";
}

export function modeToHash(mode: AppRouteMode): string {
  return MODE_TO_ROUTE[mode];
}

export function assertPagesBaseInHtml(html: string, base = "/anime-aggressors/"): boolean {
  return html.includes(base);
}

export function allAppRoutesStartWithHash(): boolean {
  return Object.values(APP_ROUTES).every((r) => r.startsWith("#/"));
}

export const CAREER_ROUTE_HASHES = [
  APP_ROUTES.career,
  APP_ROUTES.careerFighters,
  APP_ROUTES.careerHistory,
  APP_ROUTES.careerReplays,
  APP_ROUTES.careerSaves,
  APP_ROUTES.careerMilestones,
  APP_ROUTES.saves,
  APP_ROUTES.replay,
] as const;
