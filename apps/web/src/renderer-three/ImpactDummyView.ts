import * as THREE from "three";
import type { ImpactDummyState } from "@anime-aggressors/game-core";

export class ImpactDummyView {
  readonly group = new THREE.Group();
  private mesh: THREE.Mesh;
  private damageRing: THREE.Mesh;

  private meshMat: THREE.MeshToonMaterial;

  constructor() {
    this.meshMat = new THREE.MeshToonMaterial({ color: 0xd8dce8 });
    this.mesh = new THREE.Mesh(new THREE.CylinderGeometry(0.55, 0.65, 1.7, 14), this.meshMat);
    this.mesh.position.y = 0.85;
    this.group.add(this.mesh);
    this.group.scale.setScalar(42);

    this.damageRing = new THREE.Mesh(
      new THREE.TorusGeometry(0.7, 0.06, 8, 24),
      new THREE.MeshBasicMaterial({ color: 0xff8844, transparent: true, opacity: 0.7 }),
    );
    this.damageRing.rotation.x = Math.PI / 2;
    this.damageRing.position.y = 0.2;
    this.group.add(this.damageRing);
  }

  update(dummy: ImpactDummyState): void {
    const scale = 1 / 256;
    this.group.position.set(dummy.x * scale, dummy.y * scale, 0);
    const pct = Math.min(dummy.damage / 150, 1);
    this.damageRing.scale.setScalar(1 + pct * 0.35);
    (this.damageRing.material as THREE.MeshBasicMaterial).color.setHSL(0.08 - pct * 0.06, 0.9, 0.55);
    this.meshMat.color.set(dummy.launched ? 0xffeeaa : 0xd8dce8);
  }
}
