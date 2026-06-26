/**
 * Singleton keyboard input manager — listeners attached once at module load.
 * Player 1 default mapping (arrows + Z/X/C/V/B).
 */

import type { InputFrame } from "./inputFrame.js";
import { emptyInputFrame } from "./inputFrame.js";

const keys = new Set<string>();
let initialized = false;

const PREVENT_DEFAULT_CODES = new Set([
  "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Space",
]);

function initKeyboard(): void {
  if (initialized) return;
  initialized = true;

  document.addEventListener("keydown", (e) => {
    keys.add(e.code);
    if (PREVENT_DEFAULT_CODES.has(e.code)) {
      e.preventDefault();
    }
  });

  document.addEventListener("keyup", (e) => {
    keys.delete(e.code);
  });

  window.addEventListener("blur", () => {
    keys.clear();
  });
}

export function ensureKeyboard(): void {
  initKeyboard();
}

export function pollKeyboardP1(frame: number, playerId = 0): InputFrame {
  ensureKeyboard();
  const base = emptyInputFrame(frame, playerId);

  return {
    ...base,
    left: keys.has("ArrowLeft"),
    right: keys.has("ArrowRight"),
    up: keys.has("ArrowUp"),
    down: keys.has("ArrowDown"),
    jump: keys.has("ArrowUp") || keys.has("Space"),
    attack: keys.has("KeyZ"),
    special: keys.has("KeyX"),
    shield: keys.has("KeyC"),
    dodge: keys.has("KeyV"),
    grab: keys.has("KeyB"),
  };
}

/** Player 2 keyboard fallback: WASD + number row. */
export function pollKeyboardP2(frame: number, playerId = 1): InputFrame {
  ensureKeyboard();
  const base = emptyInputFrame(frame, playerId);

  return {
    ...base,
    left: keys.has("KeyA"),
    right: keys.has("KeyD"),
    up: keys.has("KeyW"),
    down: keys.has("KeyS"),
    jump: keys.has("KeyW"),
    attack: keys.has("Digit1"),
    special: keys.has("Digit2"),
    shield: keys.has("Digit3"),
    dodge: keys.has("Digit4"),
    grab: keys.has("Digit5"),
  };
}

export function isKeyDown(code: string): boolean {
  ensureKeyboard();
  return keys.has(code);
}

export function getPressedKeyCodes(): ReadonlySet<string> {
  ensureKeyboard();
  return keys;
}
