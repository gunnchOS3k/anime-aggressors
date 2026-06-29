import type { FighterSize } from "../sizeClasses.js";
import { FP_SCALE, SIM_HZ } from "../constants.js";

/** Base movement values after platform-fighter speed pass (fixed-point per frame @ 60 Hz). */
export const MOVEMENT_BASE = {
  runSpeed: (10.2 * FP_SCALE) / SIM_HZ,
  dashSpeed: (16 * FP_SCALE) / SIM_HZ,
  airDrift: (5.4 * FP_SCALE) / SIM_HZ,
  jumpVelocity: (-17.5 * FP_SCALE) / SIM_HZ,
  fastFallMult: 180,
  chargeMoveMult: 0.45,
} as const;

/** Size-class multipliers applied on top of MOVEMENT_BASE. */
export const MOVEMENT_TUNING: Record<
  FighterSize,
  {
    runSpeed: number;
    dashSpeed: number;
    airDrift: number;
    jumpVelocity: number;
    acceleration: number;
    fastFall: number;
  }
> = {
  small: {
    runSpeed: 1.35,
    dashSpeed: 1.7,
    airDrift: 1.25,
    jumpVelocity: 1.1,
    acceleration: 1.35,
    fastFall: 1.25,
  },
  medium: {
    runSpeed: 1.15,
    dashSpeed: 1.45,
    airDrift: 1.1,
    jumpVelocity: 1.0,
    acceleration: 1.15,
    fastFall: 1.15,
  },
  large: {
    runSpeed: 0.95,
    dashSpeed: 1.25,
    airDrift: 0.9,
    jumpVelocity: 0.92,
    acceleration: 0.95,
    fastFall: 1.05,
  },
};

export function movementTuningForSize(size: FighterSize) {
  return MOVEMENT_TUNING[size];
}

export function scaledMovementValue(base: number, multiplier: number): number {
  return Math.floor(base * multiplier);
}
