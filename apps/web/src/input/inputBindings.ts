import type { GameAction } from "./actions.ts";

export type InputDeviceType = "keyboard" | "gamepad" | "edgeio";

export type KeyboardBinding = {
  device: "keyboard";
  code: string;
};

export type GamepadBinding = {
  device: "gamepad";
  kind: "button" | "axis";
  index: number;
  direction?: "positive" | "negative";
  threshold?: number;
};

export type EdgeIOBinding = {
  device: "edgeio";
  gesture: "swipeL" | "swipeR" | "swipeU" | "swipeD" | "thrust" | "tap" | "doubleTap" | "block" | "shake";
};

export type InputBinding = KeyboardBinding | GamepadBinding | EdgeIOBinding;

export function bindingKey(binding: InputBinding): string {
  if (binding.device === "keyboard") return `kb:${binding.code}`;
  if (binding.device === "edgeio") return `edge:${binding.gesture}`;
  const dir = binding.direction ?? "positive";
  return `gp:${binding.kind}:${binding.index}:${dir}`;
}

export function formatBindingLabel(binding: InputBinding): string {
  if (binding.device === "keyboard") {
    return binding.code.replace(/^Key/, "").replace(/^Digit/, "#").replace("Arrow", "");
  }
  if (binding.device === "edgeio") return binding.gesture;
  if (binding.kind === "button") return `Btn ${binding.index}`;
  const dir = binding.direction === "negative" ? "-" : "+";
  return `Axis ${binding.index}${dir}`;
}

export function isBindingActive(
  binding: InputBinding,
  keyboard: ReadonlySet<string>,
  gamepad: { buttons: boolean[]; axes: number[] } | null,
  deadzone: number,
  edgeGesture?: string,
): boolean {
  if (binding.device === "keyboard") return keyboard.has(binding.code);
  if (binding.device === "edgeio") return edgeGesture === binding.gesture;
  if (!gamepad) return false;
  if (binding.kind === "button") return gamepad.buttons[binding.index] ?? false;
  const threshold = binding.threshold ?? deadzone;
  const value = gamepad.axes[binding.index] ?? 0;
  if (binding.direction === "negative") return value < -threshold;
  return value > threshold;
}

export function findActionForBinding(
  bindings: Partial<Record<GameAction, InputBinding>>,
  binding: InputBinding,
): GameAction | null {
  const key = bindingKey(binding);
  for (const [action, b] of Object.entries(bindings) as [GameAction, InputBinding][]) {
    if (b && bindingKey(b) === key) return action;
  }
  return null;
}
