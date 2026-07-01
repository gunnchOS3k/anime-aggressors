import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { APP_ROUTES } from "../src/routes.ts";
import { ALL_MAIN_MENU_ITEMS, MAIN_MENU_LABS, MAIN_MENU_PRIMARY } from "../src/ui/mainMenuConfig.ts";
import { renderHomeMarkup } from "../src/screens/homeScreenMarkup.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("main menu routes", () => {
  it("Start Game is primary menu entry", () => {
    assert.equal(MAIN_MENU_PRIMARY[0]!.id, "btn-start-game");
    assert.equal(MAIN_MENU_PRIMARY[0]!.label, "Start Game");
    assert.equal(MAIN_MENU_PRIMARY[0]!.route, APP_ROUTES.fighterSelect);
    assert.equal(MAIN_MENU_PRIMARY[0]!.mode, "fighter-select");
  });

  it("Quick Play routes to battle", () => {
    const quick = MAIN_MENU_PRIMARY.find((m) => m.id === "btn-quick-match");
    assert.equal(quick?.label, "Quick Play");
    assert.equal(quick?.route, APP_ROUTES.battle);
  });

  it("custom match setup remains available as secondary primary", () => {
    const custom = MAIN_MENU_PRIMARY.find((m) => m.id === "btn-play-match");
    assert.equal(custom?.route, APP_ROUTES.matchSetupRules);
    assert.equal(custom?.mode, "match-setup-rules");
  });

  it("experimental modes live under labs", () => {
    const labIds = new Set(MAIN_MENU_LABS.map((m) => m.id));
    assert.ok(labIds.has("btn-godot-combat"));
    assert.ok(labIds.has("btn-flagline-clash"));
    assert.ok(labIds.has("btn-impact-dummy-derby"));
  });

  it("no home menu item points to root /play", () => {
    for (const item of ALL_MAIN_MENU_ITEMS) {
      assert.notEqual(item.route, "/play");
      assert.notEqual(item.route, "#/play");
      assert.ok(item.route.startsWith("#/"), item.route);
    }
    const html = renderHomeMarkup();
    assert.doesNotMatch(html, /href="\/play"/);
    assert.doesNotMatch(html, /href='#\/play'/);
  });

  it("preserves core mode routes", () => {
    const routes = new Map(ALL_MAIN_MENU_ITEMS.map((i) => [i.id, i.route]));
    assert.equal(routes.get("btn-training"), APP_ROUTES.training);
    assert.equal(routes.get("btn-fighter-select"), APP_ROUTES.fighterSelect);
    assert.equal(routes.get("btn-stage-select"), APP_ROUTES.stageSelect);
    assert.equal(routes.get("btn-create-fighter"), APP_ROUTES.createFighter);
    assert.equal(routes.get("btn-career"), APP_ROUTES.career);
    assert.equal(routes.get("btn-controls"), APP_ROUTES.controls);
  });

  it("home screen source does not link to forbidden root play", () => {
    const homeSrc = fs.readFileSync(path.join(webRoot, "src/screens/HomeScreen.ts"), "utf8");
    assert.doesNotMatch(homeSrc, /href="\/play"/);
  });
});
