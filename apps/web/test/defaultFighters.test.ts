import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { DEFAULT_FIGHTERS } from "@anime-aggressors/game-core";

describe("default fighters web contract", () => {
  it("exports seven fighters with ROYGBIV colors once each", () => {
    assert.equal(DEFAULT_FIGHTERS.length, 7);
    const colors = DEFAULT_FIGHTERS.map((f) => f.color);
    assert.equal(new Set(colors).size, 7);
  });
});
