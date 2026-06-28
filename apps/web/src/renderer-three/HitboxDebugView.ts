import * as THREE from "three";
import type { Hitbox } from "@anime-aggressors/game-core";
import { fpToWorld } from "./RenderTypes.ts";
import { createHitboxMaterial } from "./Materials.ts";

export class HitboxDebugView {
  private boxes: THREE.Mesh[] = [];

  sync(hitboxes: Hitbox[], parent: THREE.Scene): void {
    this.clear(parent);
    const mat = createHitboxMaterial();

    for (const hb of hitboxes) {
      if (!hb.active) continue;
      const mesh = new THREE.Mesh(
        new THREE.BoxGeometry(fpToWorld(hb.w), fpToWorld(hb.h), 0.4),
        mat,
      );
      mesh.position.set(
        fpToWorld(hb.x) + fpToWorld(hb.w) / 2,
        fpToWorld(hb.y) + fpToWorld(hb.h) / 2,
        0.6,
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
