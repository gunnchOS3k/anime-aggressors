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
  const quickMatch = MAIN_MENU_PRIMARY.find((m) => m.id === "btn-quick-match") ?? MAIN_MENU_PRIMARY[0]!;
  const customSetup = MAIN_MENU_PRIMARY.find((m) => m.id === "btn-play-match");
  const secondaryCta = customSetup
    ? `<div class="arena-hub__cta arena-hub__cta--secondary">${renderMainMenuButton({ item: customSetup, state: "default", variant: "secondary", tabIndex: 0 })}</div>`
    : "";
  return `<div class="arena-hub" data-testid="arena-hub">
    <canvas id="menu-scene-canvas" class="arena-hub__canvas" aria-hidden="true"></canvas>
    <div class="arena-hub__veil"></div>
    <div class="arena-hub__content">
      <header class="arena-hub__header">
        <p class="arena-hub__kicker">Public Web Demo · 2.5D Platform Fighter</p>
        <h1 class="arena-hub__title">ANIME AGGRESSORS</h1>
        <p class="arena-hub__tagline">Play Demo → battle → rematch. Seven fighters, three stages, training &amp; local 2P.</p>
      </header>

      <div class="arena-hub__body">
        <div class="arena-hub__center">
          <div class="arena-hub__cta">
            ${renderMainMenuButton({ item: quickMatch, state: "default", variant: "primary", tabIndex: 0 })}
          </div>
          ${secondaryCta}
          ${renderMainMenuCarousel(MAIN_MENU_SECONDARY)}
        </div>
        ${renderMainMenuPanel("Player", MAIN_MENU_PLAYER)}
      </div>

      ${renderLabsPanel(MAIN_MENU_LABS)}
      ${renderMainMenuFooter()}
    </div>
  </div>`;
}
