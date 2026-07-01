/** Canonical keyboard reference for help UI, overlays, and tests. */

export const P1_CONTROL_LINES = [
  "Move: A / D",
  "Jump: W / Space",
  "Fast fall: S",
  "Attack: J · Special: K · Shield: L",
  "Dodge: Left Shift · Grab: U · Aura: F",
] as const;

export const P2_CONTROL_LINES = [
  "Move: ← / →",
  "Jump: ↑ / Numpad0",
  "Fast fall: ↓",
  "Attack: Numpad1 · Special: Numpad2 · Shield: Numpad3",
  "Dodge: Numpad4 · Grab: Numpad5 · Aura: /",
] as const;

export const BATTLE_SHORTCUT_LINES = [
  "H — controls overlay",
  "F1 debug · F2 hitboxes · F3 pause · R rematch",
] as const;

export function renderControlsOverlayHtml(): string {
  return `<div class="pf-controls-overlay" data-testid="battle-controls-overlay" hidden>
    <div class="pf-controls-overlay__panel">
      <h3>Controls</h3>
      <div class="pf-controls-overlay__cols">
        <div>
          <strong>P1</strong>
          <ul>${P1_CONTROL_LINES.map((l) => `<li>${l}</li>`).join("")}</ul>
        </div>
        <div>
          <strong>P2</strong>
          <ul>${P2_CONTROL_LINES.map((l) => `<li>${l}</li>`).join("")}</ul>
        </div>
      </div>
      <p class="pf-controls-overlay__hint">${BATTLE_SHORTCUT_LINES.join(" · ")}</p>
    </div>
  </div>`;
}
