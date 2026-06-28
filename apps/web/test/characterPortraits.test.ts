import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import {
  getPortraitConfigForFighter,
  listDefaultPortraitFighterIds,
  renderFighterPortraitHtml,
  renderFighterPortraitSvg,
} from "../src/renderer-three/portraits/FighterPortraitFactory.ts";

describe("character portraits", () => {
  it("each default fighter has a portrait config", () => {
    const ids = listDefaultPortraitFighterIds();
    assert.equal(ids.length, 7);
    for (const fighter of getAllDefaultCreatedFighters()) {
      const cfg = getPortraitConfigForFighter(fighter.id);
      assert.ok(cfg.accentColor);
      assert.ok(cfg.hairStyle);
      assert.ok(cfg.shoulderStyle);
    }
  });

  it("portrait SVG includes visual elements", () => {
    const svg = renderFighterPortraitSvg("ember-vale", 64);
    assert.match(svg, /fighter-portrait-svg/);
    assert.match(svg, /<path/);
    assert.match(svg, /ember-vale/);
  });

  it("portrait HTML wraps bust portrait", () => {
    const html = renderFighterPortraitHtml("orion-vell", 72);
    assert.match(html, /fighter-portrait/);
    assert.match(html, /orion-vell/);
  });
});
