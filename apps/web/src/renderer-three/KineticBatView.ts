import * as THREE from "three";
import type { KineticBatState } from "@anime-aggressors/game-core";

export class KineticBatView {
  readonly group = new THREE.Group();
  private bat: THREE.Mesh;
  private glow: THREE.Mesh;

  constructor() {
    this.bat = new THREE.Mesh(
      new THREE.BoxGeometry(0.18, 1.35, 0.18),
      new THREE.MeshToonMaterial({ color: 0x66ccff }),
    );
    this.bat.position.y = 0.65;
    this.group.add(this.bat);

    this.glow = new THREE.Mesh(
      new THREE.SphereGeometry(0.25, 10, 10),
      new THREE.MeshBasicMaterial({ color: 0x88eeff, transparent: true, opacity: 0.45 }),
    );
    this.glow.position.set(0.9, 1.1, 0.2);
    this.group.add(this.glow);
  }

  update(bat: KineticBatState, playerFacing: number, playerX: number, playerY: number): void {
    this.group.visible = bat.equipped || bat.available;
    this.group.position.set(playerX, playerY, 0.35);
    this.group.scale.x = playerFacing;

    const swing = bat.swingState === "active" ? bat.swingFrame * 0.12 : 0;
    this.bat.rotation.z = -swing * playerFacing;
    this.glow.visible = bat.sweetSpotActive;
  }
}
