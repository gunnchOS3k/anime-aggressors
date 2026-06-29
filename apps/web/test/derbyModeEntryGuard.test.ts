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

const { guardDerbyEntry } = await import("../src/navigation/modeEntryGuards.ts");
const { resolveDerbyRoute } = await import("../src/navigation/modeFlow.ts");
const { APP_ROUTES } = await import("../src/routes.ts");
const { clearDerbySetup, saveDerbySetup } = await import("../src/modes/impactDummyDerbySetup.ts");

beforeEach(() => {
  storage.clear();
  clearDerbySetup();
});

describe("derby mode entry guard", () => {
  it("redirects when no fighter selected", () => {
    const guard = guardDerbyEntry();
    assert.equal(guard.ok, false);
    assert.equal(guard.redirectMode, "impact-dummy-derby-fighter-select");
    const route = resolveDerbyRoute();
    assert.equal(route.route, APP_ROUTES.impactDummyDerbyFighterSelect);
  });

  it("allows derby when fighter setup complete", () => {
    saveDerbySetup({
      fighterId: "ember-vale",
      fighterName: "Ember Vale",
      fighterSize: "medium",
      fighterColor: "red",
      stageId: "impact-platform",
      ready: false,
    });
    const guard = guardDerbyEntry();
    assert.equal(guard.ok, true);
    assert.equal(resolveDerbyRoute().mode, "impact-dummy-derby");
  });
});
