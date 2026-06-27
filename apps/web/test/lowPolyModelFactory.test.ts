import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { resolveFighterAppearance } from "../src/renderer-three/fighters/FighterAppearance.ts";
import { createFighterModel } from "../src/renderer-three/fighters/FighterModelFactory.ts";

describe("low poly model factory", () => {
  it("creates humanoid parts for each default fighter", () => {
    for (let i = 0; i < 4; i++) {
      const appearance = resolveFighterAppearance(getDefaultCreatedFighter(i));
      const parts = createFighterModel(appearance);
      assert.ok(parts.root.children.length >= 6);
      assert.ok(parts.torso);
      assert.ok(parts.head);
    }
  });
});
