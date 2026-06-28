import type { MainMenuItem } from "./mainMenuConfig.ts";
import { renderMainMenuButton } from "./MainMenuButton.ts";

export function renderMainMenuPanel(title: string, items: MainMenuItem[], focusedId?: string): string {
  const buttons = items
    .map((item) => {
      const state = item.id === focusedId ? "focused" : "default";
      return renderMainMenuButton({ item, state, variant: "player", tabIndex: -1 });
    })
    .join("");

  return `<aside class="menu-panel" aria-label="${title}">
    <h2 class="menu-panel__title">${title}</h2>
    <div class="menu-panel__items">${buttons}</div>
  </aside>`;
}

export function renderLabsPanel(items: MainMenuItem[], focusedId?: string): string {
  const links = items
    .map((item) => {
      const state = item.id === focusedId ? "focused" : "default";
      return renderMainMenuButton({ item, state, variant: "labs", tabIndex: -1 });
    })
    .join("");

  return `<section class="menu-labs" aria-label="Labs and Debug">
    <h2 class="menu-labs__title">Labs &amp; Debug</h2>
    <div class="menu-labs__items">${links}</div>
  </section>`;
}
