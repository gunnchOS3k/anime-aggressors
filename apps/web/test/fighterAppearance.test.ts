import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import {
  resolveFighterAppearance,
  silhouetteForFighterId,
} from "../src/renderer-three/fighters/FighterAppearance.ts";

describe("fighter appearance mapping", () => {
  it("maps default roster to distinct silhouettes", () => {
    assert.equal(silhouetteForFighterId("ember-vale"), "angular");
    assert.equal(silhouetteForFighterId("rook-ironside"), "heavy");
    assert.equal(silhouetteForFighterId("juno-spark"), "lean");
    assert.equal(silhouetteForFighterId("nix-calder"), "heavy");
  });

  it("assigns element VFX styles from ROYGBIV", () => {
    const roster = getAllDefaultCreatedFighters();
    const ember = resolveFighterAppearance(roster[0]!);
    const rook = resolveFighterAppearance(roster[1]!);
    assert.equal(ember.vfx.trail, "flameArc");
    assert.equal(rook.vfx.trail, "impactBurst");
    assert.notEqual(ember.primaryHex, rook.primaryHex);
  });

  it("scales small and large fighters differently", () => {
    const roster = getAllDefaultCreatedFighters();
    const juno = resolveFighterAppearance(roster.find((f) => f.id === "juno-spark")!);
    const rook = resolveFighterAppearance(roster.find((f) => f.id === "rook-ironside")!);
    assert.ok(juno.scale < rook.scale);
  });
});
