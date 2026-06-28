import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import { resolveFighterAppearance } from "../src/renderer-three/fighters/FighterAppearance.ts";
import { createFighterModel, createPreviewFighterModel } from "../src/renderer-three/fighters/FighterModelFactory.ts";
import { measureModelBounds, meetsPreviewBounds, meetsBattleFighterBounds } from "../src/renderer-three/modelBounds.ts";

describe("fighter model depth", () => {
  it("preview models have readable height and z-depth", () => {
    for (const fighter of getAllDefaultCreatedFighters()) {
      const bounds = measureModelBounds(createPreviewFighterModel(resolveFighterAppearance(fighter)).root);
      assert.ok(meetsPreviewBounds(bounds), `${fighter.id} preview too flat`);
    }
  });

  it("battle models have nonzero z-depth and height", () => {
    for (const fighter of getAllDefaultCreatedFighters()) {
      const bounds = measureModelBounds(createFighterModel(resolveFighterAppearance(fighter)).root);
      assert.ok(bounds.depth >= 8, `${fighter.id} battle depth ${bounds.depth}`);
      assert.ok(meetsBattleFighterBounds(bounds), `${fighter.id} battle bounds`);
    }
  });

  it("unknown fighter fallback still has 3D depth", () => {
    const parts = createFighterModel(resolveFighterAppearance(getAllDefaultCreatedFighters()[0]!));
    const bounds = measureModelBounds(parts.root);
    assert.ok(bounds.depth > 0);
    assert.ok(bounds.height > 0);
  });
});
