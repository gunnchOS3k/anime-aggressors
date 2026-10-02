export {
  SPECTRUM_STORY_FIGHTER_IDS,
  ESSENCE_TIERS,
  createInitialStoryProgress,
  normalizeEssenceTier,
  essenceTierName,
  isPrismaticGray,
  setPuppetForm,
  setEssenceCount,
  completeGrayRoute,
  setCosmicDevOverride,
  isCosmicPlayable,
  listSelectableStoryFighterIds,
  presentationModifiers,
} from "./storyProgression.js";
export type {
  SpectrumStoryFighterId,
  StoryPuppetForm,
  EssenceTier,
  StoryRouteId,
  StoryRouteState,
  StoryProgressState,
} from "./storyProgression.js";

export {
  STORY_ROUTE_GRAPHS,
  migrateStoryProgress,
  getActiveNode,
  startRoute,
  advanceAfterWin,
  recordLoss,
  encounterConfig,
} from "./storyDirector.js";
export type {
  StoryNodeKind,
  StoryNode,
  StoryRouteGraph,
  StoryDirectorState,
} from "./storyDirector.js";
