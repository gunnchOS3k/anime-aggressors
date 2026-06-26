import * as THREE from "three";

export function setupSceneLighting(scene: THREE.Scene): void {
  const ambient = new THREE.AmbientLight(0xffffff, 0.55);
  scene.add(ambient);

  const key = new THREE.DirectionalLight(0xfff0dd, 1.1);
  key.position.set(5, 12, 18);
  scene.add(key);

  const rim = new THREE.DirectionalLight(0x88ccff, 0.45);
  rim.position.set(-8, 4, -6);
  scene.add(rim);
}
