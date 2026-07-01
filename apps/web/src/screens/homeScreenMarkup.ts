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
  const startGame = MAIN_MENU_PRIMARY.find((m) => m.id === "btn-start-game") ?? MAIN_MENU_PRIMARY[0]!;
  const quickPlay = MAIN_MENU_PRIMARY.find((m) => m.id === "btn-quick-match");
  const customSetup = MAIN_MENU_PRIMARY.find((m) => m.id === "btn-play-match");
  const secondaryCta = quickPlay
    ? `<div class="arena-hub__cta arena-hub__cta--secondary">${renderMainMenuButton({ item: quickPlay, state: "default", variant: "secondary", tabIndex: 0 })}</div>`
    : "";
  const tertiaryCta = customSetup
    ? `<div class="arena-hub__cta arena-hub__cta--tertiary">${renderMainMenuButton({ item: customSetup, state: "default", variant: "secondary", tabIndex: 0 })}</div>`
    : "";
  return `<div class="arena-hub" data-testid="arena-hub">
    <canvas id="menu-scene-canvas" class="arena-hub__canvas" aria-hidden="true"></canvas>
    <div class="arena-hub__veil"></div>
    <div class="arena-hub__content">
      <header class="arena-hub__header">
        <p class="arena-hub__kicker">Local Platform Fighter</p>
        <h1 class="arena-hub__title">ANIME AGGRESSORS</h1>
        <p class="arena-hub__tagline">Start Game for full setup · Quick Play jumps straight to battle · Labs are experimental.</p>
      </header>

      <div class="arena-hub__body">
        <div class="arena-hub__center">
          <div class="arena-hub__cta">
            ${renderMainMenuButton({ item: startGame, state: "default", variant: "primary", tabIndex: 0 })}
          </div>
          ${secondaryCta}
          ${tertiaryCta}
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
