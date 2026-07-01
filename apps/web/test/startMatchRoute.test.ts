import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { APP_ROUTES } from "../src/routes.ts";
import { renderHomeMarkup } from "../src/screens/homeScreenMarkup.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const storage = new Map<string, string>();
(globalThis as { localStorage?: Storage }).localStorage = {
  getItem: (k) => storage.get(k) ?? null,
  setItem: (k, v) => storage.set(k, v),
  removeItem: (k) => storage.delete(k),
  clear: () => storage.clear(),
  key: () => null,
  length: 0,
};

const { createQuickMatchSetup } = await import("../src/match/quickMatch.ts");

beforeEach(() => storage.clear());

describe("start match route", () => {
  it("Quick Play uses battle route", () => {
    assert.equal(APP_ROUTES.battle, "#/battle");
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-quick-match"/);
    assert.match(html, /Quick Play/);
    assert.match(html, /#\/battle/);
  });

  it("Start Game links to fighter select", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-start-game"/);
    assert.match(html, /Start Game/);
    assert.match(html, /#\/fighter-select/);
  });

  it("reset game state button exists on home", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-reset-game-state"/);
  });

  it("advanced setup links to match setup rules", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-play-match"/);
    assert.match(html, /Advanced Match Setup/);
    assert.match(html, /#\/match-setup\/rules/);
  });

  it("quick match defaults use skyline arena and 3 stocks", () => {
    const setup = createQuickMatchSetup();
    assert.equal(setup.stageId, "skyline-arena");
    assert.equal(setup.ruleset?.stocks, 3);
    assert.equal(setup.playerCount, 2);
    assert.equal(setup.ruleset?.itemFrequency, "off");
  });

  it("main menu config maps btn-quick-match to battle", () => {
    const config = fs.readFileSync(path.join(webRoot, "src/ui/mainMenuConfig.ts"), "utf8");
    assert.match(config, /btn-quick-match/);
    assert.match(config, /battle/);
  });
});
