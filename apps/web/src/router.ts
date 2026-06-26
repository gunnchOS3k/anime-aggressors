import { APP_ROUTES, hashToMode, modeToHash, type AppRouteMode } from "./routes.js";

export type RouteHandler = (mode: AppRouteMode) => void | Promise<void>;

export function installHashRouter(onRoute: RouteHandler): () => void {
  const handle = () => {
    const mode = hashToMode(window.location.hash);
    void onRoute(mode);
  };

  window.addEventListener("hashchange", handle);
  handle();
  return () => window.removeEventListener("hashchange", handle);
}

export function navigateTo(mode: AppRouteMode): void {
  const target = modeToHash(mode);
  if (window.location.hash !== target) {
    window.location.hash = target;
  } else {
    window.dispatchEvent(new HashChangeEvent("hashchange"));
  }
}

export function navigateHome(): void {
  navigateTo("home");
}

export function bindRouteButtons(): void {
  const map: [string, AppRouteMode][] = [
    ["btn-play-match", "match"],
    ["btn-create-fighter", "create-fighter"],
    ["btn-training", "training"],
    ["btn-controller", "controller"],
    ["btn-rollback", "rollback"],
    ["btn-edgeio", "edgeio"],
    ["btn-prototype", "prototype"],
    ["btn-impact-dummy-derby", "impact-dummy-derby"],
    ["btn-feedback", "feedback"],
  ];

  for (const [id, mode] of map) {
    document.getElementById(id)?.addEventListener("click", (e) => {
      e.preventDefault();
      navigateTo(mode);
    });
  }
}

export { APP_ROUTES };
