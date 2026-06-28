export const FOCUS_RING_CLASS = "menu-focus-ring";

export function applyFocusRing(el: HTMLElement | null, active: boolean): void {
  if (!el) return;
  el.classList.toggle(FOCUS_RING_CLASS, active);
  el.classList.toggle("menu-btn--focused", active);
  el.classList.remove("menu-btn--hover");
}

export function clearFocusRings(container: HTMLElement): void {
  container.querySelectorAll(`.${FOCUS_RING_CLASS}, .menu-btn--focused`).forEach((node) => {
    node.classList.remove(FOCUS_RING_CLASS, "menu-btn--focused", "menu-btn--hover");
  });
}

export function pulsePrimaryButton(el: HTMLElement | null, frame: number): void {
  if (!el) return;
  const pulse = 1 + Math.sin(frame * 0.06) * 0.025;
  el.style.transform = `scale(${pulse})`;
}
