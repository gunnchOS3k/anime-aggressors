import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import { resolveFighterAppearance } from "../src/renderer-three/fighters/FighterAppearance.ts";
import { createFighterModel } from "../src/renderer-three/fighters/FighterModelFactory.ts";

describe("low poly model factory", () => {
  it("creates humanoid parts for each default fighter", () => {
    for (const fighter of getAllDefaultCreatedFighters()) {
      const appearance = resolveFighterAppearance(fighter);
      const parts = createFighterModel(appearance);
      assert.ok(parts.root.children.length >= 6);
      assert.ok(parts.torso);
      assert.ok(parts.head);
    }
  });
});
