import type { CreatedFighter } from "@anime-aggressors/game-core";
import {
  buildCreatedFighter,
  deserializeCreatedFighter,
  serializeCreatedFighter,
} from "@anime-aggressors/game-core";

const STORAGE_KEY = "aa-created-fighters";

export function listCreatedFighters(): CreatedFighter[] {
  if (typeof localStorage === "undefined") return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const ids = JSON.parse(raw) as string[];
    return ids
      .map((id) => localStorage.getItem(`${STORAGE_KEY}:${id}`))
      .filter((v): v is string => !!v)
      .map((json) => deserializeCreatedFighter(json))
      .filter((f): f is CreatedFighter => f !== null);
  } catch {
    return [];
  }
}

export function saveCreatedFighter(fighter: CreatedFighter): CreatedFighter {
  const updated = { ...fighter, updatedAt: new Date().toISOString() };
  localStorage.setItem(`${STORAGE_KEY}:${updated.id}`, serializeCreatedFighter(updated));
  const ids = new Set(listCreatedFighters().map((f) => f.id));
  ids.add(updated.id);
  localStorage.setItem(STORAGE_KEY, JSON.stringify([...ids]));
  return updated;
}

export function createAndSaveFighter(
  input: Pick<CreatedFighter, "name" | "size" | "color">,
): CreatedFighter {
  return saveCreatedFighter(buildCreatedFighter(input));
}

export function deleteCreatedFighter(id: string): void {
  localStorage.removeItem(`${STORAGE_KEY}:${id}`);
  const remaining = listCreatedFighters().filter((f) => f.id !== id).map((f) => f.id);
  localStorage.setItem(STORAGE_KEY, JSON.stringify(remaining));
}

export function getCreatedFighter(id: string): CreatedFighter | null {
  const json = localStorage.getItem(`${STORAGE_KEY}:${id}`);
  if (!json) return null;
  return deserializeCreatedFighter(json);
}

export function updateCreatedFighter(
  id: string,
  patch: Partial<Pick<CreatedFighter, "name" | "size" | "color">>,
): CreatedFighter | null {
  const existing = getCreatedFighter(id);
  if (!existing) return null;
  return saveCreatedFighter(
    buildCreatedFighter({
      id: existing.id,
      name: patch.name ?? existing.name,
      size: patch.size ?? existing.size,
      color: patch.color ?? existing.color,
    }),
  );
}
