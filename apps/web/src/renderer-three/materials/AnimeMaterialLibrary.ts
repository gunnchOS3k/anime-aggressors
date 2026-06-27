import * as THREE from "three";

export function createToonMaterial(color: number, emissive = 0): THREE.MeshToonMaterial {
  return new THREE.MeshToonMaterial({
    color,
    emissive: emissive || color,
    emissiveIntensity: emissive ? 0.35 : 0.08,
  });
}

export function createAccentMaterial(color: number): THREE.MeshStandardMaterial {
  return new THREE.MeshStandardMaterial({
    color,
    emissive: color,
    emissiveIntensity: 0.25,
    roughness: 0.55,
    metalness: 0.15,
  });
}

export function createToonMesh(geo: THREE.BufferGeometry, color: number, emissive = 0): THREE.Mesh {
  const mesh = new THREE.Mesh(geo, createToonMaterial(color, emissive));
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  return mesh;
}

export function addOutline(mesh: THREE.Mesh, color = 0x0a0a12, scale = 1.05): void {
  const outline = mesh.clone();
  outline.material = new THREE.MeshBasicMaterial({ color, side: THREE.BackSide });
  outline.scale.multiplyScalar(scale);
  mesh.add(outline);
}

export function createStageMaterial(color: number | string): THREE.MeshStandardMaterial {
  return new THREE.MeshStandardMaterial({
    color,
    roughness: 0.82,
    metalness: 0.08,
  });
}

export function createNeonMaterial(color: number): THREE.MeshBasicMaterial {
  return new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.85 });
}
