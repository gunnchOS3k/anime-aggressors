import { ARENA_CLASSES } from "./theme/arenaClasses.ts";

export type ReadyFightOptions = {
  label?: string;
  onComplete: () => void;
};

export function renderReadyFightSequence(label = "READY… FIGHT!"): string {
  return `<div class="ready-fight-sequence ${ARENA_CLASSES.shell}" role="status" aria-live="polite">
    <p class="ready-fight-sequence__label">${label}</p>
    <div class="ready-fight-sequence__pulse"></div>
  </div>`;
}

export function mountReadyFightSequence(
  root: HTMLElement,
  options: ReadyFightOptions,
): void {
  const label = options.label ?? "READY… FIGHT!";
  root.innerHTML = renderReadyFightSequence(label);
  window.setTimeout(() => options.onComplete(), 1800);
}
