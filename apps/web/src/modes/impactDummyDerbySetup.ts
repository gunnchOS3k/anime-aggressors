import type { FighterColor, FighterSize } from "@anime-aggressors/game-core";

export type ImpactDummyDerbySetup = {
  fighterId?: string;
  fighterName?: string;
  fighterSize?: FighterSize;
  fighterColor?: FighterColor;
  stageId: "impact-platform";
  inputProfileId?: string;
  ready: boolean;
};

const STORAGE_KEY = "anime-aggressors.derbySetup";

export function createDefaultDerbySetup(): ImpactDummyDerbySetup {
  return {
    stageId: "impact-platform",
    ready: false,
  };
}

export function loadDerbySetup(): ImpactDummyDerbySetup {
  if (typeof localStorage === "undefined") return createDefaultDerbySetup();
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return createDefaultDerbySetup();
    return { ...createDefaultDerbySetup(), ...(JSON.parse(raw) as ImpactDummyDerbySetup) };
  } catch {
    return createDefaultDerbySetup();
  }
}

export function saveDerbySetup(setup: ImpactDummyDerbySetup): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(setup));
}

export function isDerbySetupReady(setup: ImpactDummyDerbySetup): boolean {
  return !!(setup.fighterId && setup.fighterName && setup.fighterSize && setup.fighterColor);
}

export function clearDerbySetup(): void {
  localStorage.removeItem(STORAGE_KEY);
}
