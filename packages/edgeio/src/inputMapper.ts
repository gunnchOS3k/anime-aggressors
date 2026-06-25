import type { GestureName } from "./gestures.js";

/** Maps wearable gesture to game input flags (mirrors apps/web edgeioMapper). */
export type MappedInput = {
  left?: boolean;
  right?: boolean;
  up?: boolean;
  down?: boolean;
  jump?: boolean;
  attack?: boolean;
  special?: boolean;
  shield?: boolean;
  dodge?: boolean;
  grab?: boolean;
  wearableGesture?: GestureName;
};

export function mapGestureToInput(gesture: GestureName, thrustAsSpecial = false): MappedInput {
  switch (gesture) {
    case "swipeL":
      return { left: true, dodge: true, wearableGesture: gesture };
    case "swipeR":
      return { right: true, dodge: true, wearableGesture: gesture };
    case "swipeU":
      return { up: true, jump: true, wearableGesture: gesture };
    case "swipeD":
      return { down: true, shield: true, wearableGesture: gesture };
    case "thrust":
      return thrustAsSpecial
        ? { special: true, wearableGesture: gesture }
        : { attack: true, wearableGesture: gesture };
    case "tap":
      return { attack: true, wearableGesture: gesture };
    case "doubleTap":
      return { special: true, wearableGesture: gesture };
    case "block":
      return { shield: true, wearableGesture: gesture };
    case "shake":
      return { grab: true, wearableGesture: gesture };
    default:
      return { wearableGesture: gesture };
  }
}
