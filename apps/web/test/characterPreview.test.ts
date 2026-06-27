import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import { resolvePreviewAnimationForFighter } from "../src/renderer-three/preview/CharacterPreviewRenderer.ts";
import { computePreviewAnimation } from "../src/renderer-three/preview/PreviewAnimationController.ts";

describe("character preview", () => {
  it("maps each default fighter to a preview animation", () => {
    for (const f of getAllDefaultCreatedFighters()) {
      const anim = resolvePreviewAnimationForFighter(f.id);
      assert.ok(anim, `missing preview animation for ${f.id}`);
    }
  });

  it("hover animation produces distinct poses per fighter", () => {
    const ember = computePreviewAnimation("flame-gauntlet-ignite", 1000, "hover");
    const rook = computePreviewAnimation("impact-stomp", 1000, "hover");
    assert.notEqual(ember.armSwingR, rook.armSwingR);
  });

  it("select phase boosts aura opacity", () => {
    const hover = computePreviewAnimation("volt-afterimage", 500, "hover");
    const select = computePreviewAnimation("volt-afterimage", 500, "select");
    assert.ok(select.auraOpacity >= hover.auraOpacity);
  });
});
