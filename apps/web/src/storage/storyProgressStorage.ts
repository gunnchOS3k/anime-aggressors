import {
  createInitialStoryProgress,
  type StoryProgressState,
} from "@anime-aggressors/game-core";

const STORAGE_KEY = "aa.storyProgress.v1_3";

export function loadStoryProgress(): StoryProgressState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return createInitialStoryProgress();
    const parsed = JSON.parse(raw) as StoryProgressState;
    if (parsed?.schema !== "story_progress_v1_3") return createInitialStoryProgress();
    return parsed;
  } catch {
    return createInitialStoryProgress();
  }
}

export function saveStoryProgress(state: StoryProgressState): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

export function resetStoryProgress(): StoryProgressState {
  const next = createInitialStoryProgress();
  saveStoryProgress(next);
  return next;
}
