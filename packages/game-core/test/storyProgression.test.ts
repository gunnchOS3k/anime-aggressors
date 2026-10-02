import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  SPECTRUM_STORY_FIGHTER_IDS,
  completeGrayRoute,
  createInitialStoryProgress,
  isCosmicPlayable,
  setCosmicDevOverride,
  setEssenceCount,
  setPuppetForm,
} from "@anime-aggressors/game-core";

describe("story progression v1.3", () => {
  it("starts with spectrum locked cosmic and Kaia root", () => {
    const s = createInitialStoryProgress();
    assert.equal(s.activeRouteId, "kaia-windrow");
    assert.equal(s.routes["kaia-windrow"].isRoot, true);
    assert.equal(s.yinUnlocked, false);
    assert.equal(isCosmicPlayable(s, "yin"), false);
  });

  it("dev override unlocks yin/yang without story completion", () => {
    let s = createInitialStoryProgress();
    s = setCosmicDevOverride(s, true);
    assert.equal(isCosmicPlayable(s, "yin"), true);
    assert.equal(isCosmicPlayable(s, "yang"), true);
    assert.equal(s.yinUnlocked, false);
  });

  it("seven gray routes unlock yin and yang", () => {
    let s = createInitialStoryProgress();
    for (const id of SPECTRUM_STORY_FIGHTER_IDS) {
      s = completeGrayRoute(s, id);
    }
    assert.equal(s.grayRoutesCompleted.length, 7);
    assert.equal(s.yinUnlocked, true);
    assert.equal(s.yangUnlocked, true);
    assert.equal(s.essenceCount, 6);
  });

  it("puppet and essence setters are pure", () => {
    let s = createInitialStoryProgress();
    s = setPuppetForm(s, "BLACK_PUPPET");
    s = setEssenceCount(s, 4);
    assert.equal(s.puppetForm, "BLACK_PUPPET");
    assert.equal(s.essenceCount, 4);
  });
});
