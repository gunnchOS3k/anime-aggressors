import * as THREE from "three";
import type { Hurtbox } from "@anime-aggressors/game-core";
import { fpToWorld } from "./RenderTypes.ts";
import { createHurtboxMaterial } from "./Materials.ts";

export class HurtboxDebugView {
  private boxes: THREE.Mesh[] = [];

  sync(hurtboxes: Hurtbox[], parent: THREE.Scene): void {
    this.clear(parent);
    const mat = createHurtboxMaterial();

    for (const hb of hurtboxes) {
      const mesh = new THREE.Mesh(
        new THREE.BoxGeometry(fpToWorld(hb.w), fpToWorld(hb.h), 0.35),
        mat,
      );
      mesh.position.set(
        fpToWorld(hb.x) + fpToWorld(hb.w) / 2,
        fpToWorld(hb.y) + fpToWorld(hb.h) / 2,
        0.4,
      );
      parent.add(mesh);
      this.boxes.push(mesh);
    }
  }

  clear(parent: THREE.Scene): void {
    for (const b of this.boxes) {
      parent.remove(b);
      b.geometry.dispose();
    }
    this.boxes = [];
  }
}
