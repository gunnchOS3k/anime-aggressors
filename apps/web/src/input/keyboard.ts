/**
 * Legacy keyboard fallbacks — prefer profile-based input via deviceAssignment.
 * P1: WASD + Space/J/K/L. P2: arrows + numpad.
 */

import type { InputFrame } from "./inputFrame.js";
import { emptyInputFrame } from "./inputFrame.js";

const keys = new Set<string>();
let initialized = false;

const PREVENT_DEFAULT_CODES = new Set([
  "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Space",
  "KeyW", "KeyA", "KeyS", "KeyD",
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
    left: keys.has("KeyA"),
    right: keys.has("KeyD"),
    up: keys.has("KeyW"),
    down: keys.has("KeyS"),
    jump: keys.has("KeyW") || keys.has("Space"),
    attack: keys.has("KeyJ"),
    special: keys.has("KeyK"),
    shield: keys.has("KeyL"),
    dodge: keys.has("ShiftLeft"),
    grab: keys.has("KeyU"),
    auraCharge: keys.has("KeyF"),
  };
}

/** Player 2 keyboard fallback: arrows + numpad. */
export function pollKeyboardP2(frame: number, playerId = 1): InputFrame {
  ensureKeyboard();
  const base = emptyInputFrame(frame, playerId);

  return {
    ...base,
    left: keys.has("ArrowLeft"),
    right: keys.has("ArrowRight"),
    up: keys.has("ArrowUp"),
    down: keys.has("ArrowDown"),
    jump: keys.has("ArrowUp") || keys.has("Numpad0"),
    attack: keys.has("Numpad1"),
    special: keys.has("Numpad2"),
    shield: keys.has("Numpad3"),
    dodge: keys.has("Numpad4"),
    grab: keys.has("Numpad5"),
    auraCharge: keys.has("Slash"),
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
