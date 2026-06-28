import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { menuFocusStep } from "../src/input/menuFocusUtils.ts";
import { MAIN_MENU_SECONDARY } from "../src/ui/mainMenuConfig.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("menu navigation", () => {
  it("can move focus across carousel items", () => {
    const first = MAIN_MENU_SECONDARY[0]!.id;
    const second = menuFocusStep(first, MAIN_MENU_SECONDARY, 1);
    assert.notEqual(second, first);
    assert.ok(MAIN_MENU_SECONDARY.some((i) => i.id === second));
  });

  it("wraps focus at carousel end", () => {
    const last = MAIN_MENU_SECONDARY[MAIN_MENU_SECONDARY.length - 1]!.id;
    const wrapped = menuFocusStep(last, MAIN_MENU_SECONDARY, 1);
    assert.equal(wrapped, MAIN_MENU_SECONDARY[0]!.id);
  });

  it("menu navigation module exports controller factory", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/input/menuNavigation.ts"), "utf8");
    assert.match(src, /createMenuNavigation/);
    assert.match(src, /ArrowDown/);
    assert.match(src, /Enter/);
  });
});
