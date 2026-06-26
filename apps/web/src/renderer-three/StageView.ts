import * as THREE from "three";
import { fpToWorld } from "./RenderTypes.js";
import { createStageMaterial } from "./Materials.js";

export class StageView {
  readonly group = new THREE.Group();
  private blastZone: THREE.LineSegments | null = null;
  private label: THREE.Mesh | null = null;

  constructor() {
    const floorMat = createStageMaterial(0x2d3436);
    const platMat = createStageMaterial(0x636e72);

    // Main platform (authoritative floor at y≈900 fp → ~3.5 world)
    const main = new THREE.Mesh(new THREE.BoxGeometry(24, 0.6, 4), floorMat);
    main.position.set(12, 3.2, 0);
    this.group.add(main);

    // Side platforms
    const leftPlat = new THREE.Mesh(new THREE.BoxGeometry(6, 0.5, 3), platMat);
    leftPlat.position.set(5, 5.5, -0.5);
    this.group.add(leftPlat);

    const rightPlat = new THREE.Mesh(new THREE.BoxGeometry(6, 0.5, 3), platMat);
    rightPlat.position.set(19, 5.5, 0.5);
    this.group.add(rightPlat);

    // Parallax layers
    for (let i = 0; i < 3; i++) {
      const bg = new THREE.Mesh(
        new THREE.PlaneGeometry(40, 16),
        new THREE.MeshBasicMaterial({
          color: new THREE.Color().setHSL(0.62 - i * 0.05, 0.35, 0.12 + i * 0.06),
          transparent: true,
          opacity: 0.35 - i * 0.08,
        }),
      );
      bg.position.set(12, 8, -8 - i * 4);
      this.group.add(bg);
    }

    // Depth props (non-authoritative)
    const tower = new THREE.Mesh(new THREE.BoxGeometry(1.2, 8, 1.2), platMat);
    tower.position.set(3, 6, -2);
    this.group.add(tower);

    const tower2 = tower.clone();
    tower2.position.set(21, 6, 2);
    this.group.add(tower2);

    // Stage name card
    const card = new THREE.Mesh(
      new THREE.PlaneGeometry(6, 1.2),
      new THREE.MeshBasicMaterial({ color: 0x111122, transparent: true, opacity: 0.7 }),
    );
    card.position.set(12, 9.5, 2);
    this.label = card;
    this.group.add(card);
  }

  setBlastZonesVisible(visible: boolean, bounds?: { left: number; right: number; top: number; bottom: number }): void {
    if (!visible) {
      if (this.blastZone) this.blastZone.visible = false;
      return;
    }

    if (!this.blastZone && bounds) {
      const points = [
        new THREE.Vector3(fpToWorld(bounds.left), fpToWorld(bounds.top), 0),
        new THREE.Vector3(fpToWorld(bounds.right), fpToWorld(bounds.top), 0),
        new THREE.Vector3(fpToWorld(bounds.right), fpToWorld(bounds.bottom), 0),
        new THREE.Vector3(fpToWorld(bounds.left), fpToWorld(bounds.bottom), 0),
        new THREE.Vector3(fpToWorld(bounds.left), fpToWorld(bounds.top), 0),
      ];
      const geo = new THREE.BufferGeometry().setFromPoints(points);
      this.blastZone = new THREE.LineSegments(
        geo,
        new THREE.LineBasicMaterial({ color: 0xff6b6b, transparent: true, opacity: 0.5 }),
      );
      this.group.add(this.blastZone);
    }
    if (this.blastZone) this.blastZone.visible = true;
  }
}
