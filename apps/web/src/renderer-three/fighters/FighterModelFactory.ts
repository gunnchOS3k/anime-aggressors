import * as THREE from "three";
import type { FighterAppearance } from "./FighterAppearance.ts";
import { buildLowPolyHumanoid, disposeHumanoid, type LowPolyHumanoidParts } from "./LowPolyHumanoid.ts";

export function createFighterModel(appearance: FighterAppearance): LowPolyHumanoidParts {
  return buildLowPolyHumanoid(appearance);
}

export function destroyFighterModel(parts: LowPolyHumanoidParts): void {
  disposeHumanoid(parts);
}

export { buildLowPolyHumanoid, disposeHumanoid, type LowPolyHumanoidParts };
