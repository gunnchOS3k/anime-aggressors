import type { MainMenuItem } from "./mainMenuConfig.ts";

export type MainMenuButtonState = "default" | "hover" | "focused" | "pressed" | "disabled";

export type MainMenuButtonOptions = {
  item: MainMenuItem;
  state?: MainMenuButtonState;
  variant?: "primary" | "secondary" | "player" | "labs";
  tabIndex?: number;
};

export function renderMainMenuButton({
  item,
  state = "default",
  variant = "secondary",
  tabIndex = -1,
}: MainMenuButtonOptions): string {
  const disabled = state === "disabled";
  const classes = [
    "menu-btn",
    `menu-btn--${variant}`,
    `menu-btn--${state}`,
    item.tier === "primary" ? "menu-btn--hero" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return `<button
    type="button"
    id="${item.id}"
    class="${classes}"
    data-menu-route="${item.route}"
    data-menu-mode="${item.mode}"
    data-menu-tier="${item.tier}"
    tabindex="${tabIndex}"
    ${disabled ? "disabled" : ""}
    aria-label="${item.label}"
  >${item.label}</button>`;
}
