import {
  createInitialStoryProgress,
  migrateStoryProgress,
  type StoryDirectorState,
  type StoryProgressState,
} from "@anime-aggressors/game-core";

const STORAGE_KEY_V13 = "aa.storyProgress.v1_3";
const STORAGE_KEY = "aa.storyProgress.v1_5";
const TEST_KEY = "aa.storyProgress.v1_5.test";

function key(testProfile = false): string {
  return testProfile ? TEST_KEY : STORAGE_KEY;
}

export function loadStoryProgress(opts?: { testProfile?: boolean }): StoryDirectorState {
  try {
    const k = key(opts?.testProfile);
    let raw = localStorage.getItem(k);
    if (!raw && !opts?.testProfile) {
      raw = localStorage.getItem(STORAGE_KEY_V13);
    }
    if (!raw) return migrateStoryProgress(createInitialStoryProgress());
    const parsed = JSON.parse(raw) as StoryProgressState | StoryDirectorState;
    if (parsed?.schema !== "story_progress_v1_3" && parsed?.schema !== "story_progress_v1_5") {
      return migrateStoryProgress(createInitialStoryProgress());
    }
    return migrateStoryProgress(parsed);
  } catch {
    return migrateStoryProgress(createInitialStoryProgress());
  }
}

export function saveStoryProgress(state: StoryDirectorState, opts?: { testProfile?: boolean }): void {
  localStorage.setItem(key(opts?.testProfile), JSON.stringify(state));
}

export function resetStoryProgress(opts?: { testProfile?: boolean }): StoryDirectorState {
  const next = migrateStoryProgress(createInitialStoryProgress());
  saveStoryProgress(next, opts);
  return next;
}

export function isStoryDevMode(): boolean {
  try {
    const q = new URLSearchParams(location.hash.split("?")[1] ?? "");
    return q.get("dev") === "1" || (window as unknown as { __AA_STORY_DEV__?: boolean }).__AA_STORY_DEV__ === true;
  } catch {
    return false;
  }
}
