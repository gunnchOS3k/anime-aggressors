/**
 * Maps Edge-IO wearable gestures into standard InputFrame actions.
 * Wearables never bypass the deterministic input abstraction.
 *
 * Default mapping:
 * - swipeL/swipeR → dodge (with directional intent via left/right)
 * - thrust → attack or special (configurable)
 * - tap → light attack
 * - block → shield
 * - doubleTap → special
 */

import type { GestureName, InputFrame } from "@anime-aggressors/game-core";

export type EdgeIOMapperConfig = {
  thrustAsSpecial: boolean;
};

export const DEFAULT_EDGEIO_CONFIG: EdgeIOMapperConfig = {
  thrustAsSpecial: false,
};

export function applyEdgeIOGesture(
  base: InputFrame,
  gesture: GestureName,
  config: EdgeIOMapperConfig = DEFAULT_EDGEIO_CONFIG,
): InputFrame {
  const next = { ...base, wearableGesture: gesture };

  switch (gesture) {
    case "swipeL":
      return { ...next, left: true, dodge: true };
    case "swipeR":
      return { ...next, right: true, dodge: true };
    case "swipeU":
      return { ...next, up: true, jump: true };
    case "swipeD":
      return { ...next, down: true, shield: true };
    case "thrust":
      return config.thrustAsSpecial
        ? { ...next, special: true }
        : { ...next, attack: true };
    case "tap":
      return { ...next, attack: true };
    case "doubleTap":
      return { ...next, special: true };
    case "block":
      return { ...next, shield: true };
    case "shake":
      return { ...next, grab: true };
    default:
      return next;
  }
}

export function gestureToActions(gesture: GestureName): Partial<InputFrame> {
  return applyEdgeIOGesture(
    {
      frame: 0,
      playerId: 0,
      left: false,
      right: false,
      up: false,
      down: false,
      jump: false,
      attack: false,
      special: false,
      shield: false,
      dodge: false,
      grab: false,
    },
    gesture,
  );
}
