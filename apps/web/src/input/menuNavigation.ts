import type { MainMenuItem } from "../ui/mainMenuConfig.ts";
import { navigateTo } from "../router.ts";
import { setCustomFlow } from "../match/matchSession.ts";
import { startQuickMatch } from "../match/quickMatch.ts";
import { applyFocusRing, clearFocusRings, pulsePrimaryButton } from "../ui/focusRing.ts";
import { carouselIdAt, carouselIndexForId } from "../ui/MainMenuCarousel.ts";
import { menuFocusStep } from "./menuFocusUtils.ts";

export type MenuNavZone = "primary" | "carousel" | "player" | "labs";

export type MenuNavigationController = {
  focusIndex: number;
  focusZone: MenuNavZone;
  focusItemId: string;
  moveFocus: (dx: number, dy: number) => void;
  confirm: () => void;
  back: () => void;
  dispose: () => void;
};

export type MenuNavigationOptions = {
  root: HTMLElement;
  primary: MainMenuItem[];
  carousel: MainMenuItem[];
  player: MainMenuItem[];
  labs: MainMenuItem[];
  onNavigate?: (item: MainMenuItem) => void;
};

function zoneItems(zone: MenuNavZone, opts: MenuNavigationOptions): MainMenuItem[] {
  switch (zone) {
    case "primary":
      return opts.primary;
    case "carousel":
      return opts.carousel;
    case "player":
      return opts.player;
    case "labs":
      return opts.labs;
  }
}

function itemById(opts: MenuNavigationOptions, id: string): MainMenuItem | undefined {
  return [...opts.primary, ...opts.carousel, ...opts.player, ...opts.labs].find((i) => i.id === id);
}

function activateItem(item: MainMenuItem, onNavigate?: (item: MainMenuItem) => void): void {
  if (item.id === "btn-quick-match") {
    onNavigate?.(item);
    startQuickMatch();
    return;
  }
  if (item.id === "btn-play-match") setCustomFlow(false);
  onNavigate?.(item);
  navigateTo(item.mode);
}

export function createMenuNavigation(opts: MenuNavigationOptions): MenuNavigationController {
  const zones: MenuNavZone[] = ["primary", "carousel", "player", "labs"];
  let focusZone: MenuNavZone = "primary";
  let focusIndex = 0;
  let focusItemId = opts.primary[0]?.id ?? opts.carousel[0]?.id ?? "";
  let pulseFrame = 0;
  let pulseRaf = 0;

  const getEl = (id: string) => opts.root.querySelector<HTMLElement>(`#${id}`);

  const applyFocus = () => {
    clearFocusRings(opts.root);
    const el = getEl(focusItemId);
    applyFocusRing(el, true);
    el?.scrollIntoView({ block: "nearest", behavior: "smooth" });
    opts.root.querySelectorAll(".menu-carousel__slide").forEach((slide) => {
      slide.classList.toggle("menu-carousel__slide--active", slide.getAttribute("data-carousel-id") === focusItemId);
    });
  };

  const syncFromZone = () => {
    const items = zoneItems(focusZone, opts);
    if (items.length === 0) return;
    focusIndex = Math.max(0, Math.min(focusIndex, items.length - 1));
    focusItemId = items[focusIndex]!.id;
    applyFocus();
  };

  const onClick = (e: Event) => {
    const target = (e.target as HTMLElement).closest<HTMLElement>("[data-menu-mode]");
    if (!target) return;
    const id = target.id;
    const item = itemById(opts, id);
    if (!item) return;
    focusItemId = id;
    if (item.tier === "primary") focusZone = "primary";
    else if (item.tier === "secondary") focusZone = "carousel";
    else if (item.tier === "player") focusZone = "player";
    else focusZone = "labs";
    applyFocus();
    activateItem(item, opts.onNavigate);
  };

  opts.root.addEventListener("click", onClick);

  for (const btn of opts.root.querySelectorAll<HTMLElement>("[data-menu-mode]")) {
    btn.addEventListener("mouseenter", () => {
      const id = btn.id;
      const item = itemById(opts, id);
      if (!item) return;
      focusItemId = id;
      if (item.tier === "primary") focusZone = "primary";
      else if (item.tier === "secondary") focusZone = "carousel";
      else if (item.tier === "player") focusZone = "player";
      else focusZone = "labs";
      clearFocusRings(opts.root);
      btn.classList.add("menu-btn--hover");
    });
    btn.addEventListener("mouseleave", () => btn.classList.remove("menu-btn--hover"));
  }

  const onKeyDown = (e: KeyboardEvent) => {
    if (e.key === "ArrowDown" || e.key === "s" || e.key === "S") {
      e.preventDefault();
      moveFocus(0, 1);
    } else if (e.key === "ArrowUp" || e.key === "w" || e.key === "W") {
      e.preventDefault();
      moveFocus(0, -1);
    } else if (e.key === "ArrowRight" || e.key === "d" || e.key === "D") {
      e.preventDefault();
      moveFocus(1, 0);
    } else if (e.key === "ArrowLeft" || e.key === "a" || e.key === "A") {
      e.preventDefault();
      moveFocus(-1, 0);
    } else if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      confirm();
    } else if (e.key === "Escape") {
      e.preventDefault();
      back();
    }
  };

  window.addEventListener("keydown", onKeyDown);

  const pulse = () => {
    pulseFrame += 1;
    pulsePrimaryButton(getEl(opts.primary[0]?.id ?? ""), pulseFrame);
    pulseRaf = requestAnimationFrame(pulse);
  };
  pulseRaf = requestAnimationFrame(pulse);

  applyFocus();

  function moveFocus(dx: number, dy: number): void {
    if (focusZone === "carousel" && dx !== 0) {
      const idx = carouselIndexForId(opts.carousel, focusItemId);
      focusItemId = carouselIdAt(opts.carousel, idx + dx);
      applyFocus();
      return;
    }

    if (dy !== 0) {
      const zi = zones.indexOf(focusZone);
      const next = zones[zi + dy];
      if (next) {
        focusZone = next;
        focusIndex = 0;
        syncFromZone();
      }
      return;
    }

    if (dx !== 0 && focusZone !== "carousel") {
      const items = zoneItems(focusZone, opts);
      focusIndex = ((focusIndex + dx) % items.length + items.length) % items.length;
      syncFromZone();
    }
  }

  function confirm(): void {
    const item = itemById(opts, focusItemId);
    if (item) activateItem(item, opts.onNavigate);
  }

  function back(): void {
    /* Home screen has no parent route; noop */
  }

  function dispose(): void {
    window.removeEventListener("keydown", onKeyDown);
    opts.root.removeEventListener("click", onClick);
    if (pulseRaf) cancelAnimationFrame(pulseRaf);
    clearFocusRings(opts.root);
  }

  return {
    get focusIndex() {
      return focusIndex;
    },
    get focusZone() {
      return focusZone;
    },
    get focusItemId() {
      return focusItemId;
    },
    moveFocus,
    confirm,
    back,
    dispose,
  };
}

export { menuFocusStep } from "./menuFocusUtils.ts";
