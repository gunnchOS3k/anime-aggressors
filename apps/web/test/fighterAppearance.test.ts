import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import {
  resolveFighterAppearance,
  silhouetteForFighterId,
} from "../src/renderer-three/fighters/FighterAppearance.ts";

describe("fighter appearance mapping", () => {
  it("maps default roster to distinct silhouettes", () => {
    assert.equal(silhouetteForFighterId("default-0"), "angular");
    assert.equal(silhouetteForFighterId("default-1"), "sleek");
    assert.equal(silhouetteForFighterId("default-2"), "lean");
    assert.equal(silhouetteForFighterId("default-3"), "heavy");
  });

  it("assigns element VFX styles from ROYGBIV", () => {
    const ember = resolveFighterAppearance(getDefaultCreatedFighter(0));
    const tide = resolveFighterAppearance(getDefaultCreatedFighter(1));
    assert.equal(ember.vfx.trail, "flameArc");
    assert.equal(tide.vfx.trail, "waterRibbon");
    assert.notEqual(ember.primaryHex, tide.primaryHex);
  });

  it("scales small and large fighters differently", () => {
    const zeph = resolveFighterAppearance(getDefaultCreatedFighter(2));
    const nova = resolveFighterAppearance(getDefaultCreatedFighter(3));
    assert.ok(zeph.scale < nova.scale);
  });
});
