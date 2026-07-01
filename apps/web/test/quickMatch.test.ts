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

const { createQuickMatchSetup, isQuickMatchSetupValid } = await import("../src/match/quickMatch.ts");

beforeEach(() => storage.clear());

describe("quick match setup", () => {
  it("creates valid skyline stock match defaults", () => {
    const setup = createQuickMatchSetup();
    assert.ok(isQuickMatchSetupValid(setup));
    assert.equal(setup.stageId, "skyline-arena");
    assert.equal(setup.fighters.length, 2);
  });

  it("rejects corrupt partial setup", () => {
    const bad = createQuickMatchSetup();
    bad.stageId = "not-a-stage";
    assert.equal(isQuickMatchSetupValid(bad), false);
  });
});
