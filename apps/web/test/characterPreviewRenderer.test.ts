import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import { resolveFighterAppearance } from "../src/renderer-three/fighters/FighterAppearance.ts";
import {
  createPreviewFighterModel,
  countFighterMeshes,
} from "../src/renderer-three/fighters/FighterModelFactory.ts";
import { measureModelBounds, meetsPreviewBounds } from "../src/renderer-three/modelBounds.ts";
import { resolvePreviewAnimationForFighter } from "../src/renderer-three/preview/CharacterPreviewRenderer.ts";

describe("character preview renderer models", () => {
  it("creates non-empty preview model for each default fighter", () => {
    for (const fighter of getAllDefaultCreatedFighters()) {
      const parts = createPreviewFighterModel(resolveFighterAppearance(fighter));
      assert.ok(countFighterMeshes(parts) >= 6, fighter.id);
      const bounds = measureModelBounds(parts.root);
      assert.ok(meetsPreviewBounds(bounds), `${fighter.id} bounds ${JSON.stringify(bounds)}`);
    }
  });

  it("hovering Ember Vale loads ember preview model with depth", () => {
    const ember = getAllDefaultCreatedFighters().find((f) => f.id === "ember-vale")!;
    const parts = createPreviewFighterModel(resolveFighterAppearance(ember));
    const bounds = measureModelBounds(parts.root);
    assert.ok(bounds.height >= 0.9);
    assert.ok(bounds.depth >= 0.25);
    assert.ok(resolvePreviewAnimationForFighter("ember-vale"));
  });

  it("hovering Rook loads rook preview model with depth", () => {
    const rook = getAllDefaultCreatedFighters().find((f) => f.id === "rook-ironside")!;
    const parts = createPreviewFighterModel(resolveFighterAppearance(rook));
    const bounds = measureModelBounds(parts.root);
    assert.ok(bounds.height >= 0.9);
    assert.ok(bounds.depth >= 0.25);
  });
});
