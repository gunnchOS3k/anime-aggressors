import * as THREE from "three";
import { createNeonMaterial, createStageMaterial } from "../materials/AnimeMaterialLibrary.ts";

export type MenuDioramaResult = {
  group: THREE.Group;
  lightSweep: THREE.DirectionalLight;
  platformTopY: number;
};

export function createMenuStageDiorama(): MenuDioramaResult {
  const group = new THREE.Group();

  const mainPlatform = new THREE.Mesh(
    new THREE.BoxGeometry(5.2, 0.45, 2.4),
    createStageMaterial(0x1a1a2e),
  );
  mainPlatform.position.set(0, -0.22, 0);
  mainPlatform.receiveShadow = true;
  group.add(mainPlatform);

  const lip = new THREE.Mesh(
    new THREE.BoxGeometry(5.4, 0.12, 2.55),
    createNeonMaterial(0x4ecdc4),
  );
  lip.position.set(0, 0.02, 0.05);
  group.add(lip);

  const sideLeft = new THREE.Mesh(
    new THREE.BoxGeometry(1.6, 0.32, 1.4),
    createStageMaterial(0x222244),
  );
  sideLeft.position.set(-2.4, 0.35, -0.3);
  group.add(sideLeft);

  const sideRight = new THREE.Mesh(
    new THREE.BoxGeometry(1.6, 0.32, 1.4),
    createStageMaterial(0x222244),
  );
  sideRight.position.set(2.4, 0.55, -0.2);
  group.add(sideRight);

  const skyline = new THREE.Group();
  for (let i = 0; i < 8; i++) {
    const h = 1.2 + Math.random() * 2.5;
    const building = new THREE.Mesh(
      new THREE.BoxGeometry(0.5 + Math.random() * 0.4, h, 0.35),
      new THREE.MeshBasicMaterial({ color: 0x0d1028, transparent: true, opacity: 0.85 }),
    );
    building.position.set(-3.5 + i * 1.0, h / 2 + 0.5, -3.5);
    skyline.add(building);
    const windowStrip = new THREE.Mesh(
      new THREE.PlaneGeometry(0.35, h * 0.7),
      new THREE.MeshBasicMaterial({ color: 0xff6b35, transparent: true, opacity: 0.15 }),
    );
    windowStrip.position.set(building.position.x, building.position.y, -3.32);
    skyline.add(windowStrip);
  }
  group.add(skyline);

  const backdrop = new THREE.Mesh(
    new THREE.PlaneGeometry(14, 7),
    new THREE.MeshBasicMaterial({ color: 0x080818, transparent: true, opacity: 0.9 }),
  );
  backdrop.position.set(0, 2.5, -4.5);
  group.add(backdrop);

  const glow = new THREE.Mesh(
    new THREE.PlaneGeometry(8, 4),
    new THREE.MeshBasicMaterial({ color: 0x7744cc, transparent: true, opacity: 0.14 }),
  );
  glow.position.set(0, 1.6, -3.8);
  group.add(glow);

  const lightSweep = new THREE.DirectionalLight(0xffaa66, 0.55);
  lightSweep.position.set(-4, 5, 3);
  group.add(lightSweep);

  return { group, lightSweep, platformTopY: 0.02 };
}

export function updateMenuStageLightSweep(light: THREE.DirectionalLight, t: number): void {
  light.position.x = Math.sin(t * 0.35) * 5;
  light.position.z = 2 + Math.cos(t * 0.25) * 2;
  light.intensity = 0.45 + Math.sin(t * 0.5) * 0.15;
}
