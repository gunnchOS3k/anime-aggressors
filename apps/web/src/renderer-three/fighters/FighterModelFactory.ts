import * as THREE from "three";
import type { FighterSize } from "@anime-aggressors/game-core";
import type { FighterAppearance } from "./FighterAppearance.ts";
import { buildLowPolyHumanoid, disposeHumanoid, type LowPolyHumanoidParts } from "./LowPolyHumanoid.ts";
import { characterWorldScale } from "../RenderTypes.ts";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { resolveFighterAppearance } from "./FighterAppearance.ts";

/** Preview scene uses unscaled humanoid (~2 units tall). */
export function createPreviewFighterModel(appearance: FighterAppearance): LowPolyHumanoidParts {
  const parts = buildLowPolyHumanoid(appearance);
  parts.root.scale.setScalar(appearance.scale);
  return parts;
}

export function createFighterModel(appearance: FighterAppearance): LowPolyHumanoidParts {
  const parts = buildLowPolyHumanoid(appearance);
  const scale = characterWorldScale(appearance.size);
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
