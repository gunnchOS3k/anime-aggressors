import type { ComboRoute } from "@anime-aggressors/game-core";
import { MOVE_SLOT_INPUT_HINT } from "@anime-aggressors/game-core";

export type ComboRouteCardOptions = {
  route: ComboRoute;
  moveNames: Record<string, string>;
};

function formatRouteSteps(route: ComboRoute, moveNames: Record<string, string>): string {
  return route.route
    .map((slot) => {
      const input = MOVE_SLOT_INPUT_HINT[slot] ?? slot;
      const name = moveNames[slot] ?? slot;
      return `<li><span class="combo-step-input">${input}</span> <span class="combo-step-name">${name}</span></li>`;
    })
    .join("");
}

export function renderComboRouteCard({ route, moveNames }: ComboRouteCardOptions): string {
  return `
    <article class="combo-route-card difficulty-${route.difficulty}" data-route-id="${route.id}">
      <header class="combo-route-header">
        <h4>${route.name}</h4>
        <span class="combo-difficulty-badge">${route.difficulty}</span>
      </header>
      <p class="combo-description">${route.description}</p>
      <ol class="combo-steps">${formatRouteSteps(route, moveNames)}</ol>
      <p class="combo-hint"><strong>Tip:</strong> ${route.teachingHint}</p>
    </article>`;
}

export function groupRoutesByDifficulty(
  routes: ComboRoute[],
): Record<ComboRoute["difficulty"], ComboRoute[]> {
  return {
    beginner: routes.filter((r) => r.difficulty === "beginner"),
    intermediate: routes.filter((r) => r.difficulty === "intermediate"),
    advanced: routes.filter((r) => r.difficulty === "advanced"),
  };
}
