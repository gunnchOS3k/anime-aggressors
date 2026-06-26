/**
 * Gamepad polling → InputFrame mapping.
 */

import type { InputFrame } from "./inputFrame.js";
import { emptyInputFrame } from "./inputFrame.js";
import { pollKeyboardP1, pollKeyboardP2 } from "./keyboard.js";

const DEADZONE = 0.25;

function axis(value: number): number {
  return Math.abs(value) < DEADZONE ? 0 : value;
}

function pressed(buttons: readonly GamepadButton[], index: number): boolean {
  return buttons[index]?.pressed ?? false;
}

export function gamepadToState(gamepad: Gamepad): { buttons: boolean[]; axes: number[] } {
  return {
    buttons: gamepad.buttons.map((b) => b.pressed),
    axes: [...gamepad.axes],
  };
}

export function pollGamepad(gamepad: Gamepad, frame: number, playerId: number): InputFrame {
  const base = emptyInputFrame(frame, playerId);
  const lx = axis(gamepad.axes[0] ?? 0);
  const ly = axis(gamepad.axes[1] ?? 0);

  const dpadLeft = pressed(gamepad.buttons, 14);
  const dpadRight = pressed(gamepad.buttons, 15);
  const dpadUp = pressed(gamepad.buttons, 12);
  const dpadDown = pressed(gamepad.buttons, 13);

  return {
    ...base,
    left: lx < -DEADZONE || dpadLeft,
    right: lx > DEADZONE || dpadRight,
    up: ly < -DEADZONE || dpadUp,
    down: ly > DEADZONE || dpadDown,
    jump: pressed(gamepad.buttons, 0),
    attack: pressed(gamepad.buttons, 2),
    special: pressed(gamepad.buttons, 1),
    shield: pressed(gamepad.buttons, 4) || pressed(gamepad.buttons, 6),
    dodge: pressed(gamepad.buttons, 5) || pressed(gamepad.buttons, 7),
    grab: pressed(gamepad.buttons, 3),
  };
}

export function getConnectedGamepads(): (Gamepad | null)[] {
  const pads = navigator.getGamepads?.() ?? [];
  return [pads[0] ?? null, pads[1] ?? null, pads[2] ?? null, pads[3] ?? null];
}

export function getGamepadInfo(): { connected: number; names: string[] } {
  const pads = getConnectedGamepads().filter(Boolean) as Gamepad[];
  return {
    connected: pads.length,
    names: pads.map((p) => p.id),
  };
}

/** @deprecated Training-lab minigames — legacy Pad shape */
export type Pad = {
  axes: [number, number, number, number];
  buttons: boolean[];
  id: string;
  connected: boolean;
};

export type Players = { p1: Pad | null; p2: Pad | null };

function inputFrameToPad(input: InputFrame): Pad {
  return {
    id: "mapped",
    axes: [
      input.left ? -1 : input.right ? 1 : 0,
      input.up ? -1 : input.down ? 1 : 0,
      0,
      0,
    ],
    buttons: [
      input.attack,
      input.special,
      input.shield,
      input.jump,
      input.dodge,
      input.grab,
      false,
      false,
    ],
    connected: true,
  };
}

/** Legacy rAF gamepad loop for prototype minigames. */
export function trackGamepads(onFrame: (pads: Players, dt: number) => void): void {
  let last = performance.now();

  function loop(now: number): void {
    const dt = (now - last) / 1000;
    last = now;
    const pads = getConnectedGamepads();
    const p1Pad = pads[0] ? pollGamepad(pads[0], 0, 0) : pollKeyboardP1(0, 0);
    const p2Pad = pads[1] ? pollGamepad(pads[1], 0, 1) : pollKeyboardP2(0, 1);

    onFrame(
      { p1: inputFrameToPad(p1Pad), p2: inputFrameToPad(p2Pad) },
      dt,
    );
    requestAnimationFrame(loop);
  }

  requestAnimationFrame(loop);
}

/** @deprecated Use pollKeyboardP1 instead */
export function createKeyboardFallback(): Pad {
  return inputFrameToPad(pollKeyboardP1(0, 0));
}
