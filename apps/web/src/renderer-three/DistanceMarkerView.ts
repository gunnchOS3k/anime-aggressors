import * as THREE from "three";

export class DistanceMarkerView {
  readonly group = new THREE.Group();
  private markers: THREE.Mesh[] = [];

  constructor(count = 12) {
    for (let i = 0; i < count; i++) {
      const m = new THREE.Mesh(
        new THREE.BoxGeometry(0.08, 1.6, 0.08),
        new THREE.MeshBasicMaterial({ color: i % 5 === 0 ? 0xaaccff : 0x556677 }),
      );
      m.position.set(4 + i * 3, 2, -0.5);
      this.group.add(m);
      this.markers.push(m);
    }
  }

  update(originX: number, currentX: number, visible: boolean): void {
    this.group.visible = visible;
    const dist = Math.max(0, currentX - originX);
    for (const m of this.markers) {
      m.position.x = originX + (m.position.x % 36) + dist * 0.02;
    }
  }
}
