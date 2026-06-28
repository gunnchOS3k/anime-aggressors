import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { ARENA_THEME } from "../src/ui/theme/arenaTheme.ts";
import { ALL_MAIN_MENU_ITEMS } from "../src/ui/mainMenuConfig.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("setup route safety", () => {
  it("arena theme routes use hash paths only", () => {
    for (const route of Object.values(ARENA_THEME.routes)) {
      assert.ok(route.startsWith("#/"), route);
      assert.notEqual(route, "/play");
    }
  });

  it("setup screens do not link to root /play", () => {
    const files = [
      "MatchSetupRulesScreen.ts",
      "MatchSetupStageScreen.ts",
      "CharacterSelectScreen.ts",
      "MatchSetupControlsScreen.ts",
      "CustomGameScreen.ts",
    ];
    for (const file of files) {
      const src = fs.readFileSync(path.join(webRoot, "src/screens", file), "utf8");
      assert.doesNotMatch(src, /href="\/play"/);
      assert.doesNotMatch(src, /location\.href\s*=\s*["']\/play/);
    }
  });

  it("main menu items avoid /play", () => {
    for (const item of ALL_MAIN_MENU_ITEMS) {
      assert.notEqual(item.route, "/play");
    }
  });
});
