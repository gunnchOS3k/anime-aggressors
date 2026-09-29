/**
 * Story progression — Essence, puppets, Gray routes, Yin/Yang unlock.
 * V1.3 playable campaign state (DRAFT_NARRATIVE_COPY where dialogue is temporary).
 */

import type { DefaultFighterId } from "../defaultFighters.js";

export const SPECTRUM_STORY_FIGHTER_IDS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
] as const satisfies readonly DefaultFighterId[];

export type SpectrumStoryFighterId = (typeof SPECTRUM_STORY_FIGHTER_IDS)[number];

export type StoryPuppetForm = "NORMAL" | "BLACK_PUPPET" | "WHITE_PUPPET";

export type EssenceTier = 0 | 1 | 2 | 4 | 6;

export const ESSENCE_TIERS: readonly EssenceTier[] = [0, 1, 2, 4, 6] as const;

export type StoryRouteId = SpectrumStoryFighterId;

export type StoryRouteState = {
  routeId: StoryRouteId;
  /** Root narrative anchor is Kaia / green. */
  isRoot: boolean;
  completed: boolean;
  grayFormUnlocked: boolean;
  draftTitle: string;
  draftSummary: string;
};

export type StoryProgressState = {
  schema: "story_progress_v1_3" | "story_progress_v1_5";
  activeRouteId: StoryRouteId | null;
  essenceCount: EssenceTier;
  puppetForm: StoryPuppetForm;
  grayRoutesCompleted: StoryRouteId[];
  yinUnlocked: boolean;
  yangUnlocked: boolean;
  /** Dev/QA override — does not write into saved unlock flags when toggled off. */
  cosmicDevOverride: boolean;
  routes: Record<StoryRouteId, StoryRouteState>;
};

const DRAFT: Record<StoryRouteId, { title: string; summary: string }> = {
  "kaia-windrow": {
    title: "Root Current — Kaia's Green Path",
    summary: "DRAFT_NARRATIVE_COPY: Begin at the green root. Gather ally Essences without losing yourself.",
  },
  "ember-vale": {
    title: "Furnace Perspective",
    summary: "DRAFT_NARRATIVE_COPY: Ember's heat tests what you keep when everything burns.",
  },
  "rook-ironside": {
    title: "Bastion Perspective",
    summary: "DRAFT_NARRATIVE_COPY: Rook demands weight and patience before the prism opens.",
  },
  "juno-spark": {
    title: "Courier Perspective",
    summary: "DRAFT_NARRATIVE_COPY: Juno's circuit races the timeline of every sacrifice.",
  },
  "nix-calder": {
    title: "Lattice Perspective",
    summary: "DRAFT_NARRATIVE_COPY: Nix freezes choices into structures you must break cleanly.",
  },
  "orion-vell": {
    title: "Orbital Perspective",
    summary: "DRAFT_NARRATIVE_COPY: Orion pulls every route into one gravity well.",
  },
  "vesper-nyx": {
    title: "Phase Perspective",
    summary: "DRAFT_NARRATIVE_COPY: Vesper asks what remains when identity phases out.",
  },
};

export function createInitialStoryProgress(): StoryProgressState {
  const routes = {} as Record<StoryRouteId, StoryRouteState>;
  for (const id of SPECTRUM_STORY_FIGHTER_IDS) {
    const draft = DRAFT[id];
    routes[id] = {
      routeId: id,
      isRoot: id === "kaia-windrow",
      completed: false,
      grayFormUnlocked: false,
      draftTitle: draft.title,
      draftSummary: draft.summary,
    };
  }
  return {
    schema: "story_progress_v1_3",
    activeRouteId: "kaia-windrow",
    essenceCount: 0,
    puppetForm: "NORMAL",
    grayRoutesCompleted: [],
    yinUnlocked: false,
    yangUnlocked: false,
    cosmicDevOverride: false,
    routes,
  };
}

export function normalizeEssenceTier(value: number): EssenceTier {
  if (value >= 6) return 6;
  if (value >= 4) return 4;
  if (value >= 2) return 2;
  if (value >= 1) return 1;
  return 0;
}

export function essenceTierName(tier: EssenceTier): string {
  switch (tier) {
    case 0:
      return "BASE";
    case 1:
      return "SACRIFICE_POWER_BOOST";
    case 2:
      return "POST_3V2_IMBALANCE_LEVELING";
    case 4:
      return "LAST_TWO_PILLARS_APPROACH";
    case 6:
      return "GRAY_PRISMATIC_CHROMATIC";
  }
}

export function isPrismaticGray(state: StoryProgressState): boolean {
  return state.essenceCount === 6;
}

export function setPuppetForm(state: StoryProgressState, form: StoryPuppetForm): StoryProgressState {
  return { ...state, puppetForm: form };
}

export function setEssenceCount(state: StoryProgressState, count: number): StoryProgressState {
  return { ...state, essenceCount: normalizeEssenceTier(count) };
}

export function completeGrayRoute(state: StoryProgressState, routeId: StoryRouteId): StoryProgressState {
  const routes = { ...state.routes };
  const route = { ...routes[routeId], completed: true, grayFormUnlocked: true };
  routes[routeId] = route;
  const grayRoutesCompleted = state.grayRoutesCompleted.includes(routeId)
    ? [...state.grayRoutesCompleted]
    : [...state.grayRoutesCompleted, routeId];
  const allSeven = SPECTRUM_STORY_FIGHTER_IDS.every((id) => grayRoutesCompleted.includes(id));
  return {
    ...state,
    routes,
    grayRoutesCompleted,
    essenceCount: allSeven ? 6 : state.essenceCount === 6 ? 6 : normalizeEssenceTier(Math.max(state.essenceCount, grayRoutesCompleted.length >= 4 ? 4 : grayRoutesCompleted.length >= 2 ? 2 : grayRoutesCompleted.length)),
    yinUnlocked: allSeven || state.yinUnlocked,
    yangUnlocked: allSeven || state.yangUnlocked,
  };
}

export function setCosmicDevOverride(state: StoryProgressState, enabled: boolean): StoryProgressState {
  return { ...state, cosmicDevOverride: enabled };
}

export function isCosmicPlayable(state: StoryProgressState, fighterId: string): boolean {
  if (fighterId !== "yin" && fighterId !== "yang") return true;
  if (state.cosmicDevOverride) return true;
  return fighterId === "yin" ? state.yinUnlocked : state.yangUnlocked;
}

export function listSelectableStoryFighterIds(state: StoryProgressState): DefaultFighterId[] {
  const base: DefaultFighterId[] = [...SPECTRUM_STORY_FIGHTER_IDS];
  if (isCosmicPlayable(state, "yin")) base.push("yin");
  if (isCosmicPlayable(state, "yang")) base.push("yang");
  return base;
}

export function presentationModifiers(state: StoryProgressState): {
  puppetForm: StoryPuppetForm;
  essenceTier: EssenceTier;
  prismaticGray: boolean;
  maskEnabled: boolean;
  motionNote: string;
} {
  const puppetForm = state.puppetForm;
  const maskEnabled = puppetForm !== "NORMAL";
  let motionNote = "native identity";
  if (puppetForm === "BLACK_PUPPET") motionNote = "secondary motion suppressed; inward drag; hue pulse remains";
  if (puppetForm === "WHITE_PUPPET") motionNote = "exact symmetry/repetition; white overwrite; dark imperfection remains";
  if (isPrismaticGray(state)) motionNote = "prismatic gray — all seven colors without dominance";
  return {
    puppetForm,
    essenceTier: state.essenceCount,
    prismaticGray: isPrismaticGray(state),
    maskEnabled,
    motionNote,
  };
}
