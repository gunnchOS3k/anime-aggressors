import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import {
  bootImpactDummyDerby,
  canDerbySimulate,
  shouldShowDerbyResults,
} from "../src/modes/impactDummyDerbyBoot.ts";

describe("impact dummy derby boot", () => {
  it("boot succeeds with default fighter", () => {
    const fighter = getDefaultCreatedFighter(0);
    const { result } = bootImpactDummyDerby(fighter);
    assert.equal(result.playerLoaded, true);
    assert.equal(result.dummyLoaded, true);
    assert.equal(result.runwayLoaded, true);
    assert.equal(result.ok, true);
    assert.ok(canDerbySimulate(result));
  });

  it("boot fails when player not loaded", () => {
    assert.equal(
      canDerbySimulate({
        ok: false,
        playerLoaded: false,
        dummyLoaded: true,
        batLoaded: true,
        runwayLoaded: true,
        cameraReady: true,
        errors: ["player not loaded"],
        stageObjectCount: 10,
        playerMeshCount: 0,
      }),
      false,
    );
  });

  it("canDerbySimulate requires all critical flags", () => {
    assert.equal(
      canDerbySimulate({
        ok: false,
        playerLoaded: true,
        dummyLoaded: true,
        batLoaded: true,
        runwayLoaded: true,
        cameraReady: true,
        errors: [],
        stageObjectCount: 10,
        playerMeshCount: 8,
      }),
      false,
    );
  });

  it("shouldShowDerbyResults blocks zero-hit fake results", () => {
    assert.equal(
      shouldShowDerbyResults({
        phase: "results",
        totalHits: 0,
        dummy: { damage: 0, launched: false },
      }),
      false,
    );
    assert.equal(
      shouldShowDerbyResults({
        phase: "results",
        totalHits: 2,
        dummy: { damage: 40, launched: true },
      }),
      true,
    );
  });
});
