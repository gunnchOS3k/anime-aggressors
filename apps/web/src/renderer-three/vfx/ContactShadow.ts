import * as THREE from "three";

export class ContactShadow {
  readonly mesh: THREE.Mesh;

  constructor(radius = 1, color = 0x000000, opacity = 0.35) {
    this.mesh = new THREE.Mesh(
      new THREE.CircleGeometry(radius, 24),
      new THREE.MeshBasicMaterial({
        color,
        transparent: true,
        opacity,
        depthWrite: false,
      }),
    );
    this.mesh.rotation.x = -Math.PI / 2;
    this.mesh.position.y = 0.02;
    this.mesh.renderOrder = -1;
  }

  setRadius(radius: number): void {
    this.mesh.geometry.dispose();
    this.mesh.geometry = new THREE.CircleGeometry(radius, 24);
  }

  dispose(): void {
    this.mesh.geometry.dispose();
    (this.mesh.material as THREE.Material).dispose();
  }
}
