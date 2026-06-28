import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  ALL_MOVE_SLOTS,
  DEFAULT_FIGHTERS,
  fighterSkillCeiling,
  fighterSkillFloor,
  getAllFighterMovesets,
  getFighterMoveset,
} from "../src/index.js";

describe("move definitions", () => {
  it("all default fighters have complete universal movesets", () => {
    for (const fighter of DEFAULT_FIGHTERS) {
      const moveset = getFighterMoveset(fighter.id);
      assert.equal(moveset.length, ALL_MOVE_SLOTS.length);
      for (const slot of ALL_MOVE_SLOTS) {
        assert.ok(moveset.some((m) => m.slot === slot), `${fighter.id} missing ${slot}`);
      }
    }
  });

  it("all moves have animation keys and vfx styles", () => {
    for (const move of getAllFighterMovesets()) {
      assert.ok(move.animationKey.length > 0, `${move.id} missing animationKey`);
      assert.ok(move.vfxStyle.length > 0, `${move.id} missing vfxStyle`);
    }
  });

  it("beginner characters have beginner skill floor", () => {
    const beginners = ["ember-vale", "rook-ironside", "nix-calder"];
    for (const id of beginners) {
      assert.equal(fighterSkillFloor(id), "beginner");
    }
  });

  it("advanced characters have high skill ceiling", () => {
    const advanced = ["juno-spark", "vesper-nyx"];
    for (const id of advanced) {
      assert.equal(fighterSkillFloor(id), "advanced");
      assert.equal(fighterSkillCeiling(id), "high");
    }
  });
});
