import type { CreatedFighter, ImpactDummyDerbyState } from "@anime-aggressors/game-core";
import {
  ELEMENTS,
  SIZE_STATS,
  fpToDisplay,
  distanceDisplayUnits,
} from "@anime-aggressors/game-core";
import { navigateHome, navigateTo } from "../router.ts";

export type DerbyResultsHandlers = {
  onRetry: () => void;
  onChangeFighter: () => void;
  onWatchReplay?: () => void;
};

export function renderDerbyResultsPanel(
  container: HTMLElement,
  state: ImpactDummyDerbyState,
  fighter: CreatedFighter,
  handlers: DerbyResultsHandlers,
): void {
  const dist = distanceDisplayUnits(state.finalDistance);
  container.classList.remove("hidden");
  container.innerHTML = `
    <div class="derby-results-panel">
      <h3>Impact Dummy Derby — Results</h3>
      <p class="derby-grade">${state.grade}</p>
      <ul class="derby-results-stats">
        <li><strong>${fighter.name}</strong> · ${SIZE_STATS[fighter.size].label} · ${ELEMENTS[fighter.color].name}</li>
        <li>Total damage: ${state.dummy.damage}%</li>
        <li>Best combo: ${state.bestCombo}</li>
        <li>Launch speed: ${fpToDisplay(state.finalLaunchSpeed)}</li>
        <li>Launch angle: ${state.finalLaunchAngleDeg}°</li>
        <li>Derby distance: ${dist}</li>
        <li>Score: ${state.score}</li>
        <li>Personal best: ${state.personalBest}</li>
      </ul>
      <div class="derby-results-actions">
        ${handlers.onWatchReplay ? `<button type="button" id="derby-watch" class="btn-secondary">Watch Replay</button>` : ""}
        <button type="button" id="derby-career" class="btn-secondary">View Career</button>
        <button type="button" id="derby-retry" class="btn-primary">Retry</button>
        <button type="button" id="derby-change" class="btn-secondary">Change Fighter</button>
        <button type="button" id="derby-home" class="btn-tertiary">Main Menu</button>
      </div>
    </div>
  `;

  container.querySelector("#derby-watch")?.addEventListener("click", () => handlers.onWatchReplay?.());
  container.querySelector("#derby-career")?.addEventListener("click", () => navigateTo("career"));
  container.querySelector("#derby-retry")?.addEventListener("click", () => handlers.onRetry());
  container.querySelector("#derby-change")?.addEventListener("click", () => handlers.onChangeFighter());
  container.querySelector("#derby-home")?.addEventListener("click", () => navigateHome());
}
