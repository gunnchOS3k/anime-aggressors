import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { ROYGBIV_AURA_STYLES } from "../src/renderer-three/vfx/AuraChargeMaterials.ts";

describe("elemental aura VFX", () => {
  it("each ROYGBIV element has unique aura visual config", () => {
    const colors = Object.keys(ROYGBIV_AURA_STYLES);
    assert.equal(colors.length, 7);
    const shapes = new Set(Object.values(ROYGBIV_AURA_STYLES).map((s) => s.shape));
    assert.equal(shapes.size, 7);
    const particles = new Set(Object.values(ROYGBIV_AURA_STYLES).map((s) => s.particle));
    assert.equal(particles.size, 7);
  });
});
