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

const { guardModeStart } = await import("../src/navigation/StartFlowGuard.ts");
const { clearMatchSetup, createDefaultMatchSetup, saveMatchSetup } = await import(
  "../src/match/matchSetupSession.ts"
);
const { clearDerbySetup } = await import("../src/modes/impactDummyDerbySetup.ts");

beforeEach(() => {
  storage.clear();
  clearMatchSetup();
  clearDerbySetup();
});

describe("start flow guard", () => {
  it("routes incomplete start match to rules", () => {
    saveMatchSetup({ ...createDefaultMatchSetup(), rulesetId: undefined, ruleset: undefined });
    const g = guardModeStart("startMatch");
    assert.equal(g.ok, false);
    assert.equal(g.missing, "rules");
  });

  it("routes derby without fighter to derby fighter select", () => {
    const g = guardModeStart("impactDummyDerby");
    assert.equal(g.ok, false);
    assert.equal(g.missing, "derbyFighter");
    assert.equal(g.redirectMode, "impact-dummy-derby-fighter-select");
  });
});
