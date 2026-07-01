import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { renderHomeMarkup } from "../src/screens/homeScreenMarkup.ts";
import {
  MAIN_MENU_LABS,
  MAIN_MENU_PLAYER,
  MAIN_MENU_PRIMARY,
  MAIN_MENU_SECONDARY,
} from "../src/ui/mainMenuConfig.ts";

describe("main menu hierarchy", () => {
  it("primary tier includes Quick Match and custom setup", () => {
    assert.equal(MAIN_MENU_PRIMARY.length, 2);
    assert.equal(MAIN_MENU_PRIMARY[0]!.id, "btn-quick-match");
    assert.equal(MAIN_MENU_PRIMARY[1]!.id, "btn-play-match");
    assert.equal(MAIN_MENU_PRIMARY[1]!.tier, "primary");
  });

  it("secondary modes are separate from labs", () => {
    for (const item of MAIN_MENU_SECONDARY) {
      assert.equal(item.tier, "secondary");
    }
    for (const item of MAIN_MENU_LABS) {
      assert.equal(item.tier, "labs");
    }
  });

  it("Start Match has hero styling in markup", () => {
    const html = renderHomeMarkup();
    assert.match(html, /menu-btn--hero/);
    assert.match(html, /arena-hub__cta/);
  });

  it("labs section is visually secondary in markup", () => {
    const html = renderHomeMarkup();
    assert.match(html, /menu-labs/);
    assert.match(html, /Labs &amp; Debug/);
    assert.match(html, /menu-btn--labs/);
    assert.doesNotMatch(html, /menu-btn--labs menu-btn--hero/);
  });

  it("player panel is grouped separately from carousel", () => {
    const html = renderHomeMarkup();
    assert.match(html, /menu-panel/);
    for (const item of MAIN_MENU_PLAYER) {
      assert.match(html, new RegExp(`>${item.label}<`));
    }
  });
});
