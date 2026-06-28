import type { MainMenuItem } from "./mainMenuConfig.ts";
import { renderMainMenuButton } from "./MainMenuButton.ts";

export function renderMainMenuCarousel(items: MainMenuItem[], focusedId?: string): string {
  const slides = items
    .map((item) => {
      const state = item.id === focusedId ? "focused" : "default";
      return `<div class="menu-carousel__slide" data-carousel-id="${item.id}">
        ${renderMainMenuButton({ item, state, variant: "secondary", tabIndex: -1 })}
      </div>`;
    })
    .join("");

  return `<div class="menu-carousel" role="group" aria-label="Game modes">
    <div class="menu-carousel__track">${slides}</div>
  </div>`;
}

export function carouselIndexForId(items: MainMenuItem[], id: string): number {
  const idx = items.findIndex((i) => i.id === id);
  return idx >= 0 ? idx : 0;
}

export function carouselIdAt(items: MainMenuItem[], index: number): string {
  const wrapped = ((index % items.length) + items.length) % items.length;
  return items[wrapped]!.id;
}
