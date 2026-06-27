import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";

const storage = new Map<string, string>();

(globalThis as { localStorage?: Storage }).localStorage = {
  getItem: (k) => storage.get(k) ?? null,
  setItem: (k, v) => storage.set(k, v),
  removeItem: (k) => storage.delete(k),
  clear: () => storage.clear(),
  key: () => null,
  length: 0,
};

const {
  buildGameConfigFromSetup,
  clearMatchSetup,
  createDefaultMatchSetup,
  isMatchSetupReady,
  loadMatchSetup,
  saveMatchSetup,
} = await import("../src/match/matchSetupSession.ts");

beforeEach(() => {
  storage.clear();
  clearMatchSetup();
});

describe("matchSetupSession", () => {
  it("creates default setup with rules and fighters", () => {
    const setup = createDefaultMatchSetup();
    assert.ok(setup.ruleset);
    assert.equal(setup.fighters.length >= 2, true);
    assert.ok(setup.stageId);
  });

  it("persists to anime-aggressors.activeMatchSetup", () => {
    const setup = createDefaultMatchSetup();
    setup.stageId = "training-grid";
    setup.stageName = "Training Grid";
    saveMatchSetup(setup);
    const loaded = loadMatchSetup();
    assert.equal(loaded.stageId, "training-grid");
    assert.equal(loaded.stageName, "Training Grid");
  });

  it("isMatchSetupReady requires rules, stage, and fighters", () => {
    const setup = createDefaultMatchSetup();
    assert.equal(isMatchSetupReady(setup), true);
    const incomplete = { ...setup, stageId: undefined };
    assert.equal(isMatchSetupReady(incomplete), false);
  });

  it("buildGameConfigFromSetup produces valid config", () => {
    const setup = createDefaultMatchSetup();
    const config = buildGameConfigFromSetup(setup);
    assert.equal(config.playerCount, 2);
    assert.ok(config.characterIds.length >= 2);
    assert.equal(config.stageId, setup.stageId);
  });

  it("clearMatchSetup removes storage", () => {
    saveMatchSetup(createDefaultMatchSetup());
    clearMatchSetup();
    assert.equal(storage.has("anime-aggressors.activeMatchSetup"), false);
  });
});
