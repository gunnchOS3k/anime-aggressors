import type { GameAction } from "./actions.ts";
import type { InputBinding, InputDeviceType } from "./inputBindings.ts";

export type InputProfile = {
  id: string;
  name: string;
  playerSlot: 1 | 2 | 3 | 4;
  deviceType: InputDeviceType;
  bindings: Partial<Record<GameAction, InputBinding>>;
  stickSensitivity: number;
  deadzone: number;
  tapJumpEnabled: boolean;
  rumbleEnabled: boolean;
  createdAt: string;
  updatedAt: string;
};

const now = () => new Date().toISOString();

export const KEYBOARD_P1_BINDINGS: InputProfile["bindings"] = {
  moveLeft: { device: "keyboard", code: "ArrowLeft" },
  moveRight: { device: "keyboard", code: "ArrowRight" },
  moveUp: { device: "keyboard", code: "ArrowUp" },
  moveDown: { device: "keyboard", code: "ArrowDown" },
  jump: { device: "keyboard", code: "Space" },
  attack: { device: "keyboard", code: "KeyZ" },
  special: { device: "keyboard", code: "KeyX" },
  shield: { device: "keyboard", code: "KeyC" },
  dodge: { device: "keyboard", code: "KeyV" },
  grab: { device: "keyboard", code: "KeyB" },
};

export const KEYBOARD_P2_BINDINGS: InputProfile["bindings"] = {
  moveLeft: { device: "keyboard", code: "KeyA" },
  moveRight: { device: "keyboard", code: "KeyD" },
  moveUp: { device: "keyboard", code: "KeyW" },
  moveDown: { device: "keyboard", code: "KeyS" },
  jump: { device: "keyboard", code: "KeyW" },
  attack: { device: "keyboard", code: "Digit1" },
  special: { device: "keyboard", code: "Digit2" },
  shield: { device: "keyboard", code: "Digit3" },
  dodge: { device: "keyboard", code: "Digit4" },
  grab: { device: "keyboard", code: "Digit5" },
};

export const GAMEPAD_STANDARD_BINDINGS: InputProfile["bindings"] = {
  moveLeft: { device: "gamepad", kind: "axis", index: 0, direction: "negative" },
  moveRight: { device: "gamepad", kind: "axis", index: 0, direction: "positive" },
  moveUp: { device: "gamepad", kind: "axis", index: 1, direction: "negative" },
  moveDown: { device: "gamepad", kind: "axis", index: 1, direction: "positive" },
  jump: { device: "gamepad", kind: "button", index: 0 },
  attack: { device: "gamepad", kind: "button", index: 2 },
  special: { device: "gamepad", kind: "button", index: 1 },
  shield: { device: "gamepad", kind: "button", index: 4 },
  dodge: { device: "gamepad", kind: "button", index: 5 },
  grab: { device: "gamepad", kind: "button", index: 3 },
};

export const GAMEPAD_PLATFORM_BINDINGS: InputProfile["bindings"] = {
  ...GAMEPAD_STANDARD_BINDINGS,
  attack: { device: "gamepad", kind: "button", index: 1 },
  special: { device: "gamepad", kind: "button", index: 0 },
  jump: { device: "gamepad", kind: "button", index: 2 },
};

export const EDGE_IO_BINDINGS: InputProfile["bindings"] = {
  moveLeft: { device: "edgeio", gesture: "swipeL" },
  moveRight: { device: "edgeio", gesture: "swipeR" },
  moveUp: { device: "edgeio", gesture: "swipeU" },
  moveDown: { device: "edgeio", gesture: "swipeD" },
  attack: { device: "edgeio", gesture: "tap" },
  special: { device: "edgeio", gesture: "doubleTap" },
  shield: { device: "edgeio", gesture: "block" },
  dodge: { device: "edgeio", gesture: "thrust" },
  grab: { device: "edgeio", gesture: "shake" },
  jump: { device: "edgeio", gesture: "swipeU" },
};

function baseProfile(
  id: string,
  name: string,
  playerSlot: 1 | 2 | 3 | 4,
  deviceType: InputDeviceType,
  bindings: InputProfile["bindings"],
): InputProfile {
  return {
    id,
    name,
    playerSlot,
    deviceType,
    bindings: { ...bindings },
    stickSensitivity: 1,
    deadzone: 0.25,
    tapJumpEnabled: true,
    rumbleEnabled: true,
    createdAt: now(),
    updatedAt: now(),
  };
}

export const DEFAULT_PROFILES: InputProfile[] = [
  baseProfile("keyboard-p1", "Keyboard P1", 1, "keyboard", KEYBOARD_P1_BINDINGS),
  baseProfile("keyboard-p2", "Keyboard P2", 2, "keyboard", KEYBOARD_P2_BINDINGS),
  baseProfile("gamepad-standard", "Gamepad Standard", 1, "gamepad", GAMEPAD_STANDARD_BINDINGS),
  baseProfile("gamepad-platform", "Gamepad Platform Fighter", 1, "gamepad", GAMEPAD_PLATFORM_BINDINGS),
  baseProfile("edgeio-experimental", "Edge-IO Experimental", 1, "edgeio", EDGE_IO_BINDINGS),
];

export function cloneProfile(profile: InputProfile): InputProfile {
  return {
    ...profile,
    bindings: { ...profile.bindings },
  };
}

export function getDefaultProfileForSlot(slot: 1 | 2 | 3 | 4): InputProfile {
  if (slot === 1) return cloneProfile(DEFAULT_PROFILES[0]);
  if (slot === 2) return cloneProfile(DEFAULT_PROFILES[1]);
  return cloneProfile({ ...DEFAULT_PROFILES[0], id: `keyboard-p${slot}`, name: `Keyboard P${slot}`, playerSlot: slot });
}

export function createProfileId(): string {
  return `profile-${Date.now().toString(36)}`;
}
