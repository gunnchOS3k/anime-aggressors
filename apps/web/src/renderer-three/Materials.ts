import * as THREE from "three";

export function createPlayerMaterial(color: string): THREE.MeshToonMaterial {
  return new THREE.MeshToonMaterial({ color });
}

export function createStageMaterial(color: string | number): THREE.MeshStandardMaterial {
  return new THREE.MeshStandardMaterial({ color, roughness: 0.85, metalness: 0.05 });
}

export function createHitboxMaterial(): THREE.MeshBasicMaterial {
  return new THREE.MeshBasicMaterial({
    color: 0xff4444,
    transparent: true,
    opacity: 0.35,
    depthWrite: false,
  });
}

export function createHurtboxMaterial(): THREE.MeshBasicMaterial {
  return new THREE.MeshBasicMaterial({
    color: 0x4488ff,
    transparent: true,
    opacity: 0.25,
    depthWrite: false,
  });
}

export function addOutline(mesh: THREE.Mesh, color = 0x111111, scale = 1.04): THREE.Mesh {
  const outline = mesh.clone();
  outline.material = new THREE.MeshBasicMaterial({
    color,
    side: THREE.BackSide,
  });
  outline.scale.multiplyScalar(scale);
  mesh.add(outline);
  return outline;
}

export const PLAYER_COLORS = ["#ff6b35", "#4ecdc4"] as const;
