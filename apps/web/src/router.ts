import { APP_ROUTES, hashToMode, modeToHash, navigateToHash, type AppRouteMode } from "./routes.js";
import { setCustomFlow } from "./match/matchSession.js";
import { startQuickMatch } from "./match/quickMatch.ts";

export type RouteHandler = (mode: AppRouteMode) => void | Promise<void>;

const ROUTE_PARAMS_KEY = "aa-route-params";

export function setRouteParams(params: Record<string, unknown>): void {
  sessionStorage.setItem(ROUTE_PARAMS_KEY, JSON.stringify(params));
}

export function getRouteParams<T extends Record<string, unknown>>(): T {
  try {
    const raw = sessionStorage.getItem(ROUTE_PARAMS_KEY);
    return raw ? (JSON.parse(raw) as T) : ({} as T);
  } catch {
    return {} as T;
  }
}

export function clearRouteParams(): void {
  sessionStorage.removeItem(ROUTE_PARAMS_KEY);
}

export function installHashRouter(onRoute: RouteHandler): () => void {
  const handle = () => {
    const mode = hashToMode(window.location.hash);
    void onRoute(mode);
  };

  window.addEventListener("hashchange", handle);
  handle();
  return () => window.removeEventListener("hashchange", handle);
}

export function navigateTo(mode: AppRouteMode, params?: Record<string, unknown>): void {
  if (params) setRouteParams(params);
  navigateToHash(modeToHash(mode));
}

export function navigateHome(): void {
  clearRouteParams();
  navigateTo("home");
}

export function bindRouteButtons(): void {
  const map: [string, AppRouteMode][] = [
    ["btn-quick-match", "battle"],
    ["btn-play-match", "match-setup-rules"],
    ["btn-fighter-select", "fighter-select"],
    ["btn-stage-select", "stage-select"],
    ["btn-custom-game", "custom-game"],
    ["btn-controls", "controls"],
    ["btn-about", "about"],
    ["btn-training", "training"],
    ["btn-create-fighter", "create-fighter"],
    ["btn-controller", "controller"],
    ["btn-rollback", "rollback"],
    ["btn-edgeio", "edgeio"],
    ["btn-prototype", "prototype"],
    ["btn-godot-combat", "godot"],
    ["btn-impact-dummy-derby", "impact-dummy-derby"],
    ["btn-flagline-clash", "flagline-setup"],
    ["btn-feedback", "feedback"],
    ["btn-career", "career"],
    ["btn-match-history", "career-history"],
    ["btn-replay-vault", "career-replays"],
    ["btn-saved-games", "career-saves"],
    ["btn-fighter-stats", "career-fighters"],
  ];

  for (const [id, mode] of map) {
    document.getElementById(id)?.addEventListener("click", (e) => {
      e.preventDefault();
      if (id === "btn-quick-match") {
        startQuickMatch();
        return;
      }
      if (id === "btn-play-match") setCustomFlow(false);
      navigateTo(mode);
    });
  }
}

export { APP_ROUTES };
