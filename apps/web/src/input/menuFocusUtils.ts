import type { MainMenuItem } from "../ui/mainMenuConfig.ts";

/** Gamepad-friendly axis debounce helper for tests and future polling. */
export function menuFocusStep(currentId: string, items: MainMenuItem[], direction: 1 | -1): string {
  const idx = items.findIndex((i) => i.id === currentId);
  const next = idx < 0 ? 0 : ((idx + direction) % items.length + items.length) % items.length;
  return items[next]!.id;
}
