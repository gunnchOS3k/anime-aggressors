import {
  MAIN_MENU_LABS,
  MAIN_MENU_PLAYER,
  MAIN_MENU_PRIMARY,
  MAIN_MENU_SECONDARY,
} from "../ui/mainMenuConfig.ts";
import { renderMainMenuButton } from "../ui/MainMenuButton.ts";
import { renderMainMenuCarousel } from "../ui/MainMenuCarousel.ts";
import { renderLabsPanel, renderMainMenuPanel } from "../ui/MainMenuPanel.ts";
import { renderMainMenuFooter } from "../ui/MainMenuFooter.ts";

export function renderHomeMarkup(): string {
  const godotPrimary = MAIN_MENU_PRIMARY[0]!;
  return `<div class="arena-hub" data-testid="arena-hub">
    <div class="runtime-banner runtime-banner--home" data-testid="runtime-banner" role="status">
      <span class="runtime-banner__label">Primary Runtime: Godot 4 (local)</span>
      <span class="runtime-banner__hint">Open <code>game-godot/</code> in Godot 4 for authoritative offline play. Web paths below are legacy or preview.</span>
    </div>
    <canvas id="menu-scene-canvas" class="arena-hub__canvas" aria-hidden="true"></canvas>
    <div class="arena-hub__veil"></div>
    <div class="arena-hub__content">
      <header class="arena-hub__header">
        <p class="arena-hub__kicker">Local Platform Fighter</p>
        <h1 class="arena-hub__title">ANIME AGGRESSORS</h1>
        <p class="arena-hub__tagline">Godot 4 is the primary runtime · Legacy web battle lives under Labs.</p>
      </header>

      <div class="arena-hub__body">
        <div class="arena-hub__center">
          <div class="arena-hub__cta">
            ${renderMainMenuButton({ item: godotPrimary, state: "default", variant: "primary", tabIndex: 0 })}
          </div>
          ${renderMainMenuCarousel(MAIN_MENU_SECONDARY)}
        </div>
        ${renderMainMenuPanel("Player", MAIN_MENU_PLAYER)}
      </div>

      ${renderLabsPanel(MAIN_MENU_LABS)}
      ${renderMainMenuFooter()}
      <div class="arena-hub__reset">
        <button type="button" id="btn-reset-game-state" class="btn-tertiary" data-testid="reset-game-state">Reset Game State</button>
      </div>
    </div>
  </div>`;
}
