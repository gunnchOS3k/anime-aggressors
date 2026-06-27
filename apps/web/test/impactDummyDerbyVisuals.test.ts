import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("impact dummy derby visuals", () => {
  it("derby view imports visual components", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/modes/impactDummyDerbyView.ts"), "utf8");
    assert.match(src, /ImpactDummyView/);
    assert.match(src, /KineticBatView/);
    assert.match(src, /DistanceMarkerView/);
    assert.match(src, /LaunchTrailView/);
  });

  it("dummy view uses low-poly cylinder body", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/renderer-three/ImpactDummyView.ts"), "utf8");
    assert.match(src, /CylinderGeometry/);
    assert.match(src, /damageRing/);
  });
});
