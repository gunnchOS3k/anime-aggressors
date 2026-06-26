/** Hash routes for GitHub Pages — no path-based SPA routing required. */
export const APP_ROUTES = {
  home: "#/",
  play: "#/play",
  training: "#/training",
  controllerTest: "#/controller-test",
  rollbackDebug: "#/rollback-debug",
  edgeioLab: "#/edgeio-lab",
  prototypeLab: "#/prototype-lab",
  impactDummyDerby: "#/impact-dummy-derby",
} as const;

export type AppRouteMode =
  | "home"
  | "match"
  | "training"
  | "controller"
  | "rollback"
  | "edgeio"
  | "prototype"
  | "impact-dummy-derby";

export const ROUTE_TO_MODE: Record<string, AppRouteMode> = {
  [APP_ROUTES.home]: "home",
  [APP_ROUTES.play]: "match",
  [APP_ROUTES.training]: "training",
  [APP_ROUTES.controllerTest]: "controller",
  [APP_ROUTES.rollbackDebug]: "rollback",
  [APP_ROUTES.edgeioLab]: "edgeio",
  [APP_ROUTES.prototypeLab]: "prototype",
  [APP_ROUTES.impactDummyDerby]: "impact-dummy-derby",
};

export const MODE_TO_ROUTE: Record<AppRouteMode, string> = {
  home: APP_ROUTES.home,
  match: APP_ROUTES.play,
  training: APP_ROUTES.training,
  controller: APP_ROUTES.controllerTest,
  rollback: APP_ROUTES.rollbackDebug,
  edgeio: APP_ROUTES.edgeioLab,
  prototype: APP_ROUTES.prototypeLab,
  "impact-dummy-derby": APP_ROUTES.impactDummyDerby,
};

export function hashToMode(hash: string): AppRouteMode {
  const normalized = hash || APP_ROUTES.home;
  return ROUTE_TO_MODE[normalized] ?? "home";
}

export function modeToHash(mode: AppRouteMode): string {
  return MODE_TO_ROUTE[mode];
}

export function assertPagesBaseInHtml(html: string, base = "/anime-aggressors/"): boolean {
  return html.includes(base);
}
