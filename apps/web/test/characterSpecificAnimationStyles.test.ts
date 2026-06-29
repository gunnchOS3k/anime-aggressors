import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { listStyledFighterIds } from "../src/renderer-three/fighters/fighterAnimationStyles.ts";

describe("character specific animation styles", () => {
  it("each default fighter has a style", () => {
    const ids = listStyledFighterIds();
    assert.ok(ids.includes("ember-vale"));
    assert.ok(ids.includes("juno-spark"));
    assert.equal(ids.length, 7);
  });
});
