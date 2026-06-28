import * as THREE from "three";
import type { FighterAppearance } from "./FighterAppearance.ts";
import { buildLowPolyHumanoid, disposeHumanoid, type LowPolyHumanoidParts } from "./LowPolyHumanoid.ts";
import { characterWorldScale } from "../RenderTypes.ts";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { resolveFighterAppearance } from "./FighterAppearance.ts";

export function createFighterModel(appearance: FighterAppearance): LowPolyHumanoidParts {
  const parts = buildLowPolyHumanoid(appearance);
  const scale = characterWorldScale(appearance.scale);
  parts.root.scale.setScalar(scale);
  return parts;
}

export function createFallbackFighterModel(playerIndex = 0): LowPolyHumanoidParts {
  const appearance = resolveFighterAppearance(getDefaultCreatedFighter(playerIndex));
  return createFighterModel(appearance);
}

export function destroyFighterModel(parts: LowPolyHumanoidParts): void {
  disposeHumanoid(parts);
}

export function countFighterMeshes(parts: LowPolyHumanoidParts): number {
  let n = 0;
  parts.root.traverse((o) => {
    if (o instanceof THREE.Mesh) n += 1;
  });
  return n;
}

export { buildLowPolyHumanoid, disposeHumanoid, type LowPolyHumanoidParts };
