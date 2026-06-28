import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import { resolveFighterAppearance } from "../src/renderer-three/fighters/FighterAppearance.ts";
import {
  createFighterModel,
  createFallbackFighterModel,
  countFighterMeshes,
} from "../src/renderer-three/fighters/FighterModelFactory.ts";

describe("fighter visual factory non-empty", () => {
  it("each default fighter returns non-empty model", () => {
    for (const fighter of getAllDefaultCreatedFighters()) {
      const appearance = resolveFighterAppearance(fighter);
      const parts = createFighterModel(appearance);
      assert.ok(countFighterMeshes(parts) >= 6, fighter.id);
    }
  });

  it("ember vale and orion vell are visible humanoids", () => {
    for (const id of ["ember-vale", "orion-vell"] as const) {
      const fighter = getAllDefaultCreatedFighters().find((f) => f.id === id);
      assert.ok(fighter, id);
      const parts = createFighterModel(resolveFighterAppearance(fighter!));
      assert.ok(countFighterMeshes(parts) >= 6, id);
    }
  });

  it("unknown fighter id uses fallback low-poly humanoid", () => {
    const parts = createFallbackFighterModel(0);
    assert.ok(countFighterMeshes(parts) >= 6);
    assert.ok(parts.head);
    assert.ok(parts.torso);
    assert.ok(parts.leftLeg);
    assert.ok(parts.rightLeg);
  });
});
