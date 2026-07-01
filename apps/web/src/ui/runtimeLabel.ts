import type { AppRouteMode } from "../routes.ts";

export type RuntimeKind = "godot-primary" | "legacy-web" | "labs" | "home";

const LABS_MODES = new Set<AppRouteMode>([
  "create-fighter",
  "prototype",
  "impact-dummy-derby",
  "impact-dummy-derby-fighter-select",
  "flagline-clash",
  "flagline-setup",
  "flagline-teams",
  "controller",
  "rollback",
  "edgeio",
  "feedback",
]);

const LEGACY_WEB_MODES = new Set<AppRouteMode>([
  "battle",
  "match",
  "training",
  "fighter-select",
  "stage-select",
  "match-setup-rules",
  "match-setup-stage",
  "match-setup-fighters",
  "match-setup-controls",
  "custom-game",
  "rulesets",
  "controls-check",
  "controls",
  "controls-remap",
  "moves",
  "combos",
  "career",
  "career-fighters",
  "career-history",
  "career-replays",
  "career-saves",
  "career-milestones",
  "replay",
  "about",
]);

export function runtimeKindForMode(mode: AppRouteMode): RuntimeKind {
  if (mode === "home") return "home";
  if (mode === "godot") return "godot-primary";
  if (LABS_MODES.has(mode)) return "labs";
  if (LEGACY_WEB_MODES.has(mode)) return "legacy-web";
  return "legacy-web";
}

export function runtimeLabelForKind(kind: RuntimeKind): string {
  switch (kind) {
    case "godot-primary":
      return "Godot Runtime";
    case "legacy-web":
      return "Legacy Web Runtime — reference only";
    case "labs":
      return "Experimental / Labs";
    default:
      return "Primary Runtime: Godot 4 (local)";
  }
}

export function runtimeHintForKind(kind: RuntimeKind): string {
  switch (kind) {
    case "godot-primary":
      return "Primary gameplay path. Local editor: game-godot/. Web embed may lag behind editor build.";
    case "legacy-web":
      return "Legacy Web Runtime — reference only, not final gameplay.";
    case "labs":
      return "Experimental tools — not production balance or UX.";
    default:
      return "Open game-godot/ in Godot 4 for authoritative local play.";
  }
}

export function renderRuntimeBanner(kind: RuntimeKind): string {
  const label = runtimeLabelForKind(kind);
  return `<div class="runtime-banner runtime-banner--${kind}" data-testid="runtime-banner" role="status">
    <span class="runtime-banner__label">${label}</span>
    <span class="runtime-banner__hint">${runtimeHintForKind(kind)}</span>
  </div>`;
}

export function attachRuntimeBanner(root: HTMLElement, mode: AppRouteMode): void {
  const kind = runtimeKindForMode(mode);
  const wrap = document.createElement("div");
  wrap.innerHTML = renderRuntimeBanner(kind);
  const banner = wrap.firstElementChild;
  if (banner) root.prepend(banner);
}
