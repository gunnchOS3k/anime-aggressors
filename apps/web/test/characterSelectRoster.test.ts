import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { DEFAULT_FIGHTERS, getRoygbivColors } from "@anime-aggressors/game-core";

describe("character select roster", () => {
  it("has exactly seven ROYGBIV default fighters", () => {
    assert.equal(DEFAULT_FIGHTERS.length, 7);
    assert.equal(getRoygbivColors().length, 7);
  });

  it("includes mixed sizes small medium large", () => {
    const sizes = DEFAULT_FIGHTERS.map((f) => f.size);
    assert.ok(sizes.includes("small"));
    assert.ok(sizes.includes("medium"));
    assert.ok(sizes.includes("large"));
  });

  it("each fighter has signature move and preview animation", () => {
    for (const f of DEFAULT_FIGHTERS) {
      assert.ok(f.signatureMoveName.length > 0);
      assert.ok(f.previewAnimation.length > 0);
      assert.ok(f.visualStyleId.length > 0);
    }
  });
});
