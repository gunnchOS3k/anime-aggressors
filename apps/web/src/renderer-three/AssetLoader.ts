import * as THREE from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";

export type AssetManifest = {
  characters: Record<string, string>;
  stages: Record<string, string>;
};

export const DEFAULT_MANIFEST: AssetManifest = {
  characters: {
    ember: "/anime-aggressors/assets/characters/ember.glb",
    tide: "/anime-aggressors/assets/characters/tide.glb",
  },
  stages: {
    "skyline-arena": "/anime-aggressors/assets/stages/skyline-arena.glb",
  },
};

const loader = new GLTFLoader();

export async function loadGlb(url: string): Promise<THREE.Group | null> {
  try {
    const gltf = await loader.loadAsync(url);
    return gltf.scene;
  } catch {
    return null;
  }
}

export async function loadCharacterGlb(characterId: string, manifest = DEFAULT_MANIFEST): Promise<THREE.Group | null> {
  const url = manifest.characters[characterId];
  if (!url) return null;
  return loadGlb(url);
}

export async function loadStageGlb(stageId: string, manifest = DEFAULT_MANIFEST): Promise<THREE.Group | null> {
  const url = manifest.stages[stageId];
  if (!url) return null;
  return loadGlb(url);
}
