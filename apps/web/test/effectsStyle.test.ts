import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getElementVfxStyle, getElementTrailStyle } from "../src/renderer-three/fighters/FighterEffectsStyle.ts";

describe("element VFX style mapping", () => {
  it("maps all ROYGBIV colors to trail styles", () => {
    const colors = ["red", "orange", "yellow", "green", "blue", "indigo", "violet"] as const;
    for (const c of colors) {
      const style = getElementVfxStyle(c);
      assert.ok(style.hitSpark > 0);
      assert.ok(style.aura > 0);
      assert.ok(getElementTrailStyle(c));
    }
  });

  it("uses distinct trails for flame vs frost vs void", () => {
    assert.equal(getElementTrailStyle("red"), "flameArc");
    assert.equal(getElementTrailStyle("blue"), "frostShard");
    assert.equal(getElementTrailStyle("violet"), "voidSmear");
  });
});
