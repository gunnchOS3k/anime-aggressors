import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  DEFAULT_FIGHTER_APPEARANCES,
  getDefaultFighterAppearance,
} from "../src/renderer-three/fighters/defaultFighterAppearances.ts";

describe("default fighter appearances", () => {
  it("defines seven visual configs", () => {
    assert.equal(DEFAULT_FIGHTER_APPEARANCES.length, 7);
  });

  it("each config has trail style and preview animation", () => {
    for (const cfg of DEFAULT_FIGHTER_APPEARANCES) {
      assert.ok(cfg.trailStyle);
      assert.ok(cfg.previewAnimation);
      assert.ok(cfg.primaryColor.startsWith("#"));
    }
  });

  it("looks up appearance by fighter id", () => {
    const ember = getDefaultFighterAppearance("ember-vale");
    assert.equal(ember?.trailStyle, "flame");
    assert.equal(ember?.previewAnimation, "flame-gauntlet-ignite");
  });
});
