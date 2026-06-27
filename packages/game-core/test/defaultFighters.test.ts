import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  DEFAULT_FIGHTERS,
  DEFAULT_FIGHTER_ROSTER,
  getAllDefaultCreatedFighters,
  getDefaultCreatedFighter,
  getDefaultFighterProfile,
  getRoygbivColors,
  normalizeDefaultFighterId,
} from "@anime-aggressors/game-core";

describe("default fighter roster", () => {
  it("includes seven original ROYGBIV fighters", () => {
    assert.equal(DEFAULT_FIGHTERS.length, 7);
    assert.equal(DEFAULT_FIGHTER_ROSTER.length, 7);
  });

  it("represents each ROYGBIV color once", () => {
    const colors = getRoygbivColors();
    assert.equal(new Set(colors).size, 7);
    assert.deepEqual(colors.sort(), ["blue", "green", "indigo", "orange", "red", "violet", "yellow"].sort());
  });

  it("mixes small, medium, and large sizes", () => {
    const sizes = DEFAULT_FIGHTERS.map((f) => f.size);
    assert.ok(sizes.includes("small"));
    assert.ok(sizes.includes("medium"));
    assert.ok(sizes.includes("large"));
    assert.equal(sizes.filter((s) => s === "small").length, 2);
    assert.equal(sizes.filter((s) => s === "medium").length, 3);
    assert.equal(sizes.filter((s) => s === "large").length, 2);
  });

  it("each fighter has preview animation and visual style", () => {
    for (const f of DEFAULT_FIGHTERS) {
      assert.ok(f.previewAnimation);
      assert.ok(f.visualStyleId);
      assert.ok(f.signatureMoveName);
      assert.ok(f.shortTagline);
    }
  });

  it("getDefaultCreatedFighter returns roster entry by index", () => {
    assert.equal(getDefaultCreatedFighter(0).name, "Ember Vale");
    assert.equal(getDefaultCreatedFighter(0).id, "ember-vale");
    assert.equal(getDefaultCreatedFighter(1).name, "Rook Ironside");
    assert.equal(getDefaultCreatedFighter(6).name, "Vesper Nyx");
    assert.equal(getDefaultCreatedFighter(6).size, "small");
  });

  it("getAllDefaultCreatedFighters returns full roster", () => {
    assert.equal(getAllDefaultCreatedFighters().length, 7);
  });

  it("maps legacy default ids to new roster ids", () => {
    assert.equal(normalizeDefaultFighterId("default-0"), "ember-vale");
    assert.equal(getDefaultFighterProfile("default-1")?.name, "Rook Ironside");
  });
});
