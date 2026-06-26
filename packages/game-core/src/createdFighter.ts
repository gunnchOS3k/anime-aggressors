import type { FighterColor, ElementEffect } from "./elements.js";
import { getElementForColor } from "./elements.js";
import type { FighterSize } from "./sizeClasses.js";

export type CreatedFighter = {
  id: string;
  name: string;
  size: FighterSize;
  color: FighterColor;
  element: ElementEffect;
  createdAt: string;
  updatedAt: string;
};

export const DEFAULT_FIGHTER_NAME = "Rookie";

export function createCreatedFighterId(): string {
  return `fighter-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}

export function buildCreatedFighter(
  input: Pick<CreatedFighter, "name" | "size" | "color"> & { id?: string },
): CreatedFighter {
  const now = new Date().toISOString();
  const element = getElementForColor(input.color).effect;
  return {
    id: input.id ?? createCreatedFighterId(),
    name: input.name.trim() || DEFAULT_FIGHTER_NAME,
    size: input.size,
    color: input.color,
    element,
    createdAt: now,
    updatedAt: now,
  };
}

export function serializeCreatedFighter(fighter: CreatedFighter): string {
  return JSON.stringify(fighter);
}

export function deserializeCreatedFighter(json: string): CreatedFighter | null {
  try {
    const parsed = JSON.parse(json) as CreatedFighter;
    if (!parsed.id || !parsed.size || !parsed.color) return null;
    const element = getElementForColor(parsed.color).effect;
    return { ...parsed, element };
  } catch {
    return null;
  }
}

export function getDefaultCreatedFighter(playerIndex: number): CreatedFighter {
  const presets: Array<Pick<CreatedFighter, "name" | "size" | "color">> = [
    { name: "Ember Spark", size: "medium", color: "red" },
    { name: "Tide Breaker", size: "medium", color: "blue" },
  ];
  const preset = presets[playerIndex] ?? presets[0];
  return buildCreatedFighter({ ...preset, id: `default-${playerIndex}` });
}
