import * as THREE from "three";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import { resolveFighterAppearance } from "../fighters/FighterAppearance.ts";
import {
  createPreviewFighterModel,
  createFallbackFighterModel,
  destroyFighterModel,
  countFighterMeshes,
  type LowPolyHumanoidParts,
} from "../fighters/FighterModelFactory.ts";
import { measureModelBounds } from "../modelBounds.ts";

export type MenuFighterSlot = {
  fighterId: string;
  parts: LowPolyHumanoidParts;
  baseX: number;
  facing: number;
};

export type MenuFighterShowcaseResult = {
  group: THREE.Group;
  slots: MenuFighterSlot[];
  fighterCount: number;
  meshCount: number;
};

const DEFAULT_SHOWCASE_IDS = ["ember-vale", "orion-vell"] as const;

function loadFighterById(id: string, x: number, facing: number): MenuFighterSlot | null {
  const roster = getAllDefaultCreatedFighters();
  const fighter = roster.find((f) => f.id === id);
  let parts: LowPolyHumanoidParts;
  try {
    parts = fighter
      ? createPreviewFighterModel(resolveFighterAppearance(fighter))
      : createFallbackFighterModel(0);
  } catch {
    parts = createFallbackFighterModel(0);
  }

  const bounds = measureModelBounds(parts.root);
  if (bounds.height < 0.3) {
    destroyFighterModel(parts);
    parts = createFallbackFighterModel(0);
  }

  parts.root.position.set(x, 0, 0);
  parts.root.rotation.y = facing > 0 ? 0.15 : Math.PI - 0.15;
  return { fighterId: id, parts, baseX: x, facing };
}

export function createMenuFighterShowcase(
  fighterIds: readonly string[] = DEFAULT_SHOWCASE_IDS,
): MenuFighterShowcaseResult {
  const group = new THREE.Group();
  const slots: MenuFighterSlot[] = [];
  const positions = [-1.35, 1.35];

  fighterIds.forEach((id, i) => {
    const slot = loadFighterById(id, positions[i] ?? 0, i === 0 ? 1 : -1);
    if (slot) {
      group.add(slot.parts.root);
      slots.push(slot);
    }
  });

  if (slots.length === 0) {
    const fallback = loadFighterById("fallback", 0, 1);
    if (fallback) {
      group.add(fallback.parts.root);
      slots.push(fallback);
    }
  }

  let meshCount = 0;
  for (const slot of slots) {
    meshCount += countFighterMeshes(slot.parts);
  }

  return { group, slots, fighterCount: slots.length, meshCount };
}

export function updateMenuFighterShowcase(slots: MenuFighterSlot[], t: number): void {
  for (const slot of slots) {
    const bob = Math.sin(t * 1.4 + slot.baseX) * 0.04;
    slot.parts.root.position.y = bob;
    slot.parts.root.rotation.y = (slot.facing > 0 ? 0.15 : Math.PI - 0.15) + Math.sin(t * 0.8) * 0.05;
    if (slot.parts.leftArm) slot.parts.leftArm.rotation.x = Math.sin(t * 1.2) * 0.12 - 0.08;
    if (slot.parts.rightArm) slot.parts.rightArm.rotation.x = -Math.sin(t * 1.2) * 0.12 - 0.08;
  }
}

export function disposeMenuFighterShowcase(slots: MenuFighterSlot[]): void {
  for (const slot of slots) {
    destroyFighterModel(slot.parts);
  }
}

export { DEFAULT_SHOWCASE_IDS };
