import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { DEFAULT_FIGHTER_ROSTER, getDefaultCreatedFighter } from "@anime-aggressors/game-core";

describe("default fighter roster", () => {
  it("includes four original fighters", () => {
    assert.equal(DEFAULT_FIGHTER_ROSTER.length, 4);
    assert.deepEqual(
      DEFAULT_FIGHTER_ROSTER.map((f) => f.name),
      ["Ember Vale", "Tide Kuro", "Zeph Ray", "Nova Grimm"],
    );
  });

  it("getDefaultCreatedFighter returns roster entry by index", () => {
    assert.equal(getDefaultCreatedFighter(0).name, "Ember Vale");
    assert.equal(getDefaultCreatedFighter(3).name, "Nova Grimm");
    assert.equal(getDefaultCreatedFighter(3).size, "large");
  });
});
