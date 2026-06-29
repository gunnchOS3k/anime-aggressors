import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { renderAuraMeter } from "../src/ui/AuraMeter.ts";
import { createDefaultAuraState } from "@anime-aggressors/game-core";

describe("aura meter HUD", () => {
  it("renders aura meter with fill width", () => {
    const aura = { ...createDefaultAuraState(), current: 50, level: 2 };
    const html = renderAuraMeter(aura, "red", "left");
    assert.match(html, /pf-aura-meter/);
    assert.match(html, /width:50%/);
    assert.match(html, /L2/);
  });

  it("shows super-ready class at level 3", () => {
    const aura = { ...createDefaultAuraState(), current: 90, level: 3 };
    const html = renderAuraMeter(aura, "violet", "right");
    assert.match(html, /super-ready/);
  });

  it("shows charging class while charging", () => {
    const aura = { ...createDefaultAuraState(), current: 30, level: 1, charging: true };
    const html = renderAuraMeter(aura, "yellow", "left");
    assert.match(html, /charging/);
  });
});
