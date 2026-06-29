import * as THREE from "three";
import type { HitEvent } from "@anime-aggressors/game-core";

export type LimbTrailEmitter = {
  mesh: THREE.Mesh;
  life: number;
};

export function createLimbTrailMesh(color: number): THREE.Mesh {
  const geo = new THREE.PlaneGeometry(0.35, 0.08);
  const mat = new THREE.MeshBasicMaterial({
    color,
    transparent: true,
    opacity: 0.75,
    side: THREE.DoubleSide,
    depthWrite: false,
  });
  return new THREE.Mesh(geo, mat);
}

export function spawnLimbTrail(
  scene: THREE.Scene,
  origin: THREE.Vector3,
  color: number,
  trails: LimbTrailEmitter[],
): void {
  const mesh = createLimbTrailMesh(color);
  mesh.position.copy(origin);
  trails.push({ mesh, life: 12 });
  scene.add(mesh);
}

export function tickLimbTrails(trails: LimbTrailEmitter[], scene: THREE.Scene): void {
  for (let i = trails.length - 1; i >= 0; i--) {
    const t = trails[i]!;
    t.life -= 1;
    (t.mesh.material as THREE.MeshBasicMaterial).opacity = Math.max(0, t.life / 12) * 0.75;
    if (t.life <= 0) {
      scene.remove(t.mesh);
      t.mesh.geometry.dispose();
      (t.mesh.material as THREE.MeshBasicMaterial).dispose();
      trails.splice(i, 1);
    }
  }
}

export function hitSparkAnchorFromEvent(_event: HitEvent, victimPos: THREE.Vector3): THREE.Vector3 {
  return victimPos.clone();
}
