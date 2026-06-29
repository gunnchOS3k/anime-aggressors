import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("impact dummy derby visuals", () => {
  it("derby boot loads visual components", () => {
    const boot = fs.readFileSync(path.join(webRoot, "src/modes/impactDummyDerbyBoot.ts"), "utf8");
    const view = fs.readFileSync(path.join(webRoot, "src/modes/impactDummyDerbyView.ts"), "utf8");
    assert.match(boot, /ImpactDummyView/);
    assert.match(boot, /KineticBatView/);
    assert.match(boot, /DistanceMarkerView/);
    assert.match(view, /dummyView\.group/);
    assert.match(view, /batView\.group/);
  });

  it("dummy view uses low-poly cylinder body", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/renderer-three/ImpactDummyView.ts"), "utf8");
    assert.match(src, /CylinderGeometry/);
    assert.match(src, /damageRing/);
  });
});
