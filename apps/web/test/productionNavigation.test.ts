import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { APP_ROUTES } from "../src/routes.ts";
import { renderHomeMarkup } from "../src/screens/homeScreenMarkup.ts";
import { MODE_ROUTE_MAP } from "../src/navigation/modeRouteMap.ts";

const storage = new Map<string, string>();
(globalThis as { localStorage?: Storage }).localStorage = {
  getItem: (k) => storage.get(k) ?? null,
  setItem: (k, v) => storage.set(k, v),
  removeItem: (k) => storage.delete(k),
  clear: () => storage.clear(),
  key: () => null,
  length: 0,
};

const { resetGameState } = await import("../src/match/quickMatch.ts");
const { loadMatchSetup } = await import("../src/match/matchSetupSession.ts");

beforeEach(() => storage.clear());

describe("production navigation flow", () => {
  it("start match flow is fighter → stage → ready → battle", () => {
    const steps = MODE_ROUTE_MAP.startMatch.map((s) => s.mode);
    assert.deepEqual(steps, ["fighter-select", "stage-select", "match-setup-controls", "battle"]);
  });

  it("home loads with Start Game and Quick Play", () => {
    const html = renderHomeMarkup();
    assert.match(html, /data-testid="arena-hub"/);
    assert.match(html, /Start Game/);
    assert.match(html, /Quick Play/);
  });

  it("labs are separated from carousel", () => {
    const html = renderHomeMarkup();
    assert.match(html, /menu-labs/);
    assert.doesNotMatch(html, /Godot Combat Prototype[\s\S]*menu-carousel/);
  });

  it("reset game state restores valid setup", () => {
    storage.set("anime-aggressors.activeMatchSetup", "{bad");
    resetGameState();
    const setup = loadMatchSetup();
    assert.ok(setup.fighters.length >= 2);
    assert.ok(setup.stageId);
  });

  it("training route is registered", () => {
    assert.equal(APP_ROUTES.training, "#/training");
  });

  it("controls and about routes exist", () => {
    assert.equal(APP_ROUTES.controls, "#/controls");
    assert.equal(APP_ROUTES.about, "#/about");
  });
});
