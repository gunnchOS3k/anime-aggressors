import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { createDefaultAuraState, isSuperReady } from "@anime-aggressors/game-core";
import { renderAuraMeter } from "../src/ui/AuraMeter.ts";
import { renderSuperReadyBadge } from "../src/ui/SuperReadyBadge.ts";

describe("aura meter HUD", () => {
  it("renders aura meter with fill width", () => {
    const aura = createDefaultAuraState();
    aura.current = 50;
    aura.level = 2;
    const html = renderAuraMeter(aura, "red", "left");
    assert.match(html, /width:50%/);
    assert.match(html, /L2/);
  });

  it("shows super ready badge at level 3", () => {
    const aura = createDefaultAuraState();
    aura.current = 90;
    aura.level = 3;
    assert.equal(isSuperReady(aura), true);
    assert.match(renderSuperReadyBadge(aura), /SUPER READY/);
  });
});
