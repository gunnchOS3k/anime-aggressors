/** Hash routes for GitHub Pages — no path-based SPA routing required. */
export const APP_ROUTES = {
  home: "#/",
  createFighter: "#/create-fighter",
  customGame: "#/custom-game",
  rulesets: "#/rulesets",
  fighterSelect: "#/fighter-select",
  controlsCheck: "#/controls-check",
  controls: "#/controls",
  controlsRemap: "#/controls/remap",
  play: "#/play",
  training: "#/training",
  controllerTest: "#/controller-test",
  rollbackDebug: "#/rollback-debug",
  edgeioLab: "#/edgeio-lab",
  prototypeLab: "#/prototype-lab",
  impactDummyDerby: "#/impact-dummy-derby",
  flaglineClash: "#/flagline-clash",
  flaglineSetup: "#/flagline-setup",
  flaglineTeams: "#/flagline-teams",
  feedback: "#/feedback",
  career: "#/career",
  careerFighters: "#/career/fighters",
  careerHistory: "#/career/history",
  careerReplays: "#/career/replays",
  careerSaves: "#/career/saves",
  careerMilestones: "#/career/milestones",
  saves: "#/saves",
  replay: "#/replay",
} as const;

export type AppRouteMode =
  | "home"
  | "create-fighter"
  | "custom-game"
  | "rulesets"
  | "fighter-select"
  | "controls-check"
  | "controls"
  | "controls-remap"
  | "match"
  | "training"
  | "controller"
  | "rollback"
  | "edgeio"
  | "prototype"
  | "impact-dummy-derby"
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
  [APP_ROUTES.createFighter]: "create-fighter",
  [APP_ROUTES.customGame]: "custom-game",
  [APP_ROUTES.rulesets]: "rulesets",
  [APP_ROUTES.fighterSelect]: "fighter-select",
  [APP_ROUTES.controlsCheck]: "controls-check",
  [APP_ROUTES.controls]: "controls",
  [APP_ROUTES.controlsRemap]: "controls-remap",
  [APP_ROUTES.play]: "match",
  [APP_ROUTES.training]: "training",
  [APP_ROUTES.controllerTest]: "controller",
  [APP_ROUTES.rollbackDebug]: "rollback",
  [APP_ROUTES.edgeioLab]: "edgeio",
  [APP_ROUTES.prototypeLab]: "prototype",
  [APP_ROUTES.impactDummyDerby]: "impact-dummy-derby",
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
  "create-fighter": APP_ROUTES.createFighter,
  "custom-game": APP_ROUTES.customGame,
  rulesets: APP_ROUTES.rulesets,
  "fighter-select": APP_ROUTES.fighterSelect,
  "controls-check": APP_ROUTES.controlsCheck,
  controls: APP_ROUTES.controls,
  "controls-remap": APP_ROUTES.controlsRemap,
  match: APP_ROUTES.play,
  training: APP_ROUTES.training,
  controller: APP_ROUTES.controllerTest,
  rollback: APP_ROUTES.rollbackDebug,
  edgeio: APP_ROUTES.edgeioLab,
  prototype: APP_ROUTES.prototypeLab,
  "impact-dummy-derby": APP_ROUTES.impactDummyDerby,
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
