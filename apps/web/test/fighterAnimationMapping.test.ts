import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllFighterMovesets } from "@anime-aggressors/game-core";
import { ANIMATION_STATES, getAnimationKeyForMove } from "../src/renderer-three/fighters/FighterAnimationClips.ts";
import { getAllMoveAnimationSpecs, getMoveAnimationSpec } from "../src/renderer-three/fighters/moveAnimationMap.ts";

describe("fighter animation mapping", () => {
  it("defines required animation states", () => {
    assert.ok(ANIMATION_STATES.includes("idle"));
    assert.ok(ANIMATION_STATES.includes("superActive"));
    assert.ok(ANIMATION_STATES.includes("dash"));
    assert.ok(ANIMATION_STATES.includes("launch"));
    assert.equal(ANIMATION_STATES.length, 29);
  });

  it("maps every move to an animation key", () => {
    for (const move of getAllFighterMovesets()) {
      const key = getAnimationKeyForMove(move.id);
      assert.ok(key.length > 0);
      assert.equal(key, move.animationKey);
    }
  });

  it("provides move animation specs with motion arcs", () => {
    const specs = getAllMoveAnimationSpecs();
    assert.equal(specs.length, getAllFighterMovesets().length);
    for (const spec of specs) {
      assert.ok(spec.motionArc);
      assert.ok(spec.strikeFrame > 0);
    }
    const superSpec = getMoveAnimationSpec("ember-vale:super");
    assert.equal(superSpec?.motionArc, "beam");
    assert.equal(superSpec?.cameraImpulse, "super");
  });
});
