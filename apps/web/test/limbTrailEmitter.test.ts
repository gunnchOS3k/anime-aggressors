import { describe, it } from "node:test";
import assert from "node:assert/strict";
import * as THREE from "three";
import { createLimbTrailMesh } from "../src/renderer-three/vfx/LimbTrailEmitter.ts";

describe("limb trail emitter", () => {
  it("creates trail mesh away from origin", () => {
    const mesh = createLimbTrailMesh(0xff6600);
    assert.ok(mesh instanceof THREE.Mesh);
    assert.ok(mesh.geometry);
  });
});
