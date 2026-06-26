import type { GameRuleset } from "@anime-aggressors/game-core";
import {
  cloneRuleset,
  DEFAULT_RULESET,
  RULESET_PRESETS,
  validateRuleset,
} from "@anime-aggressors/game-core";

const RULESETS_KEY = "aa-rulesets";
const ACTIVE_RULESET_KEY = "aa-active-ruleset";

export function listRulesets(): GameRuleset[] {
  if (typeof localStorage === "undefined") return [...RULESET_PRESETS].map(cloneRuleset);
  try {
    const raw = localStorage.getItem(RULESETS_KEY);
    const saved: GameRuleset[] = raw ? (JSON.parse(raw) as GameRuleset[]) : [];
    const byId = new Map<string, GameRuleset>();
    for (const preset of RULESET_PRESETS) byId.set(preset.id, cloneRuleset(preset));
    for (const r of saved) byId.set(r.id, r);
    return [...byId.values()];
  } catch {
    return [...RULESET_PRESETS].map(cloneRuleset);
  }
}

export function saveRuleset(ruleset: GameRuleset): GameRuleset {
  const updated = {
    ...ruleset,
    updatedAt: new Date().toISOString(),
    createdAt: ruleset.createdAt || new Date().toISOString(),
  };
  if (!validateRuleset(updated)) throw new Error("Invalid ruleset");
  const saved = listRulesets()
    .filter((r) => !RULESET_PRESETS.some((p) => p.id === r.id))
    .filter((r) => r.id !== updated.id);
  saved.push(updated);
  localStorage.setItem(RULESETS_KEY, JSON.stringify(saved));
  return updated;
}

export function deleteRuleset(id: string): void {
  if (RULESET_PRESETS.some((p) => p.id === id)) return;
  const saved = listRulesets()
    .filter((r) => !RULESET_PRESETS.some((p) => p.id === r.id))
    .filter((r) => r.id !== id);
  localStorage.setItem(RULESETS_KEY, JSON.stringify(saved));
  if (getActiveRulesetId() === id) setActiveRulesetId(DEFAULT_RULESET.id);
}

export function duplicateRuleset(id: string): GameRuleset | null {
  const source = getRuleset(id);
  if (!source) return null;
  const copy: GameRuleset = {
    ...cloneRuleset(source),
    id: `ruleset-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`,
    name: `${source.name} Copy`,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  return saveRuleset(copy);
}

export function getRuleset(id: string): GameRuleset | null {
  return listRulesets().find((r) => r.id === id) ?? null;
}

export function setActiveRulesetId(id: string): void {
  localStorage.setItem(ACTIVE_RULESET_KEY, id);
}

export function getActiveRulesetId(): string {
  return localStorage.getItem(ACTIVE_RULESET_KEY) ?? DEFAULT_RULESET.id;
}

export function getActiveRuleset(): GameRuleset {
  return getRuleset(getActiveRulesetId()) ?? cloneRuleset(DEFAULT_RULESET);
}

export function resetRulesetsToDefaults(): void {
  localStorage.removeItem(RULESETS_KEY);
  localStorage.removeItem(ACTIVE_RULESET_KEY);
}

export function createCustomRuleset(name: string): GameRuleset {
  return saveRuleset({
    ...cloneRuleset(DEFAULT_RULESET),
    id: `ruleset-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`,
    name,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
}
