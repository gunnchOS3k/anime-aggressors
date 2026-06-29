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

const { resolveDerbyRoute } = await import("../src/navigation/modeFlow.ts");
const { APP_ROUTES } = await import("../src/routes.ts");
const { clearDerbySetup } = await import("../src/modes/impactDummyDerbySetup.ts");

beforeEach(() => {
  storage.clear();
  clearDerbySetup();
});

describe("derby requires fighter selection", () => {
  it("redirects to select-fighter when no fighter", () => {
    const route = resolveDerbyRoute();
    assert.equal(route.route, APP_ROUTES.impactDummyDerbySelectFighter);
    assert.equal(route.mode, "impact-dummy-derby-fighter-select");
  });
});
