import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { CameraImpulseSystem } from "../src/renderer-three/camera/CameraImpulseSystem.ts";

describe("camera impulse system", () => {
  it("triggers shake on heavy hit", () => {
    const sys = new CameraImpulseSystem();
    sys.trigger("heavyHit", 1, 0);
    const pulse = sys.tick();
    assert.equal(pulse.active, true);
    assert.ok(Math.abs(pulse.shakeX) > 0 || pulse.zoomPunch > 0);
  });

  it("heavy hit impulse exceeds light hit", () => {
    const heavy = new CameraImpulseSystem();
    heavy.trigger("heavyHit");
    const h = heavy.tick();

    const light = new CameraImpulseSystem();
    light.trigger("lightHit");
    const l = light.tick();

    assert.ok(h.zoomPunch >= l.zoomPunch);
  });
});
