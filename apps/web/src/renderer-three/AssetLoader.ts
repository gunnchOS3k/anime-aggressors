/**
 * Battle model asset loader — V1.4 authored GLB provenance.
 * Replaces the stale two-entry DEFAULT_MANIFEST (ember/tide).
 */
import * as THREE from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { clone as cloneSkinned } from "three/examples/jsm/utils/SkeletonUtils.js";

export type ModelKind = "AUTHORED_GLB" | "GENERATED_LOW_POLY" | "DEBUG_FALLBACK" | "MISSING";

export type BattlePresentationKey = `${string}:${"male" | "female"}`;

export type BattlePresentationEntry = {
  fighter_id: string;
  body_variant: "male" | "female";
  model_kind: ModelKind;
  source_path: string;
  runtime_url: string;
  sha256: string;
  bytes: number;
  production_status?: string;
  playable_tuning_status?: string;
  animation_binding?: string;
  SKIN_PRESENT?: boolean;
  CANONICAL_DEFORM_RIG?: boolean;
  note?: string;
};

export type BattleModelManifest = {
  schema: string;
  schema_version: number;
  presentations: Record<string, BattlePresentationEntry>;
  count: number;
  AUTHORED_MODEL_MANIFEST_18_OF_18?: boolean;
};

export type ModelProvenance = {
  fighter_id: string;
  body_variant: "male" | "female";
  model_kind: ModelKind;
  model_path: string;
  model_sha256: string;
  model_exists: boolean;
  model_loaded: boolean;
  fallback_used: boolean;
  runtime_instance_id: string;
  animation_binding: string;
};

const loader = new GLTFLoader();
let manifestCache: BattleModelManifest | null = null;
const gltfCache = new Map<string, THREE.Group>();
const provenanceByInstance = new Map<string, ModelProvenance>();

export function presentationKey(fighterId: string, bodyVariant: "male" | "female"): string {
  return `${fighterId}:${bodyVariant}`;
}

export async function loadBattleModelManifest(
  url = "/anime-aggressors/assets/characters/BATTLE_MODEL_MANIFEST.json",
): Promise<BattleModelManifest> {
  if (manifestCache) return manifestCache;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`battle model manifest fetch failed: ${res.status}`);
  manifestCache = (await res.json()) as BattleModelManifest;
  return manifestCache;
}

export function getCachedManifest(): BattleModelManifest | null {
  return manifestCache;
}

export function setBattleModelManifestForTests(manifest: BattleModelManifest): void {
  manifestCache = manifest;
}

export async function loadGlb(url: string): Promise<THREE.Group | null> {
  try {
    const gltf = await loader.loadAsync(url);
    return gltf.scene;
  } catch {
    return null;
  }
}

/** Clone a cached GLTF scene safely (skinned or static). */
export function cloneBattleScene(source: THREE.Object3D): THREE.Group {
  return cloneSkinned(source) as THREE.Group;
}

export async function preloadBattlePresentation(
  fighterId: string,
  bodyVariant: "male" | "female",
): Promise<ModelProvenance> {
  const manifest = await loadBattleModelManifest();
  const key = presentationKey(fighterId, bodyVariant);
  const entry = manifest.presentations[key];
  const runtime_instance_id = `${key}@${Math.random().toString(36).slice(2, 10)}`;
  if (!entry) {
    return {
      fighter_id: fighterId,
      body_variant: bodyVariant,
      model_kind: "MISSING",
      model_path: "",
      model_sha256: "",
      model_exists: false,
      model_loaded: false,
      fallback_used: true,
      runtime_instance_id,
      animation_binding: "NONE",
    };
  }
  if (gltfCache.has(key)) {
    return {
      fighter_id: fighterId,
      body_variant: bodyVariant,
      model_kind: "AUTHORED_GLB",
      model_path: entry.runtime_url,
      model_sha256: entry.sha256,
      model_exists: true,
      model_loaded: true,
      fallback_used: false,
      runtime_instance_id,
      animation_binding: entry.animation_binding === "PRODUCTION_RIG" || (entry as { SKIN_PRESENT?: boolean }).SKIN_PRESENT
        ? "PRODUCTION_RIG"
        : "ROOT_PROXY_PENDING_SKINNED_RIG",
    };
  }
  const scene = await loadGlb(entry.runtime_url);
  if (!scene) {
    return {
      fighter_id: fighterId,
      body_variant: bodyVariant,
      model_kind: "MISSING",
      model_path: entry.runtime_url,
      model_sha256: entry.sha256,
      model_exists: true,
      model_loaded: false,
      fallback_used: true,
      runtime_instance_id,
      animation_binding: "NONE",
    };
  }
  scene.userData.sha256 = entry.sha256;
  scene.userData.runtime_url = entry.runtime_url;
  scene.userData.model_kind = "AUTHORED_GLB";
  gltfCache.set(key, scene);
  const binding =
    entry.animation_binding === "PRODUCTION_RIG" || (entry as { SKIN_PRESENT?: boolean }).SKIN_PRESENT
      ? "PRODUCTION_RIG"
      : "ROOT_PROXY_PENDING_SKINNED_RIG";
  return {
    fighter_id: fighterId,
    body_variant: bodyVariant,
    model_kind: "AUTHORED_GLB",
    model_path: entry.runtime_url,
    model_sha256: entry.sha256,
    model_exists: true,
    model_loaded: true,
    fallback_used: false,
    runtime_instance_id,
    animation_binding: binding,
  };
}

export async function preloadBattleRoster(
  seats: Array<{ fighterId: string; bodyVariant: "male" | "female" }>,
): Promise<ModelProvenance[]> {
  const out: ModelProvenance[] = [];
  for (const seat of seats) {
    out.push(await preloadBattlePresentation(seat.fighterId, seat.bodyVariant));
  }
  return out;
}

export function takeCachedBattleScene(fighterId: string, bodyVariant: "male" | "female"): THREE.Group | null {
  const key = presentationKey(fighterId, bodyVariant);
  const cached = gltfCache.get(key);
  if (!cached) return null;
  return cloneBattleScene(cached);
}

export function registerProvenance(instanceId: string, provenance: ModelProvenance): void {
  provenanceByInstance.set(instanceId, provenance);
}

export function listRuntimeProvenance(): ModelProvenance[] {
  return [...provenanceByInstance.values()];
}

export function clearRuntimeProvenance(): void {
  provenanceByInstance.clear();
}

export function clearBattleGltfCache(): void {
  gltfCache.clear();
}

/** Legacy stage loader kept for stage GLBs. */
export async function loadStageGlb(stageId: string): Promise<THREE.Group | null> {
  const url = `/anime-aggressors/assets/stages/${stageId}.glb`;
  return loadGlb(url);
}

/** @deprecated stale two-entry character map — do not use for acceptance. */
export const DEFAULT_MANIFEST = {
  characters: {
    ember: "/anime-aggressors/assets/characters/ember.glb",
    tide: "/anime-aggressors/assets/characters/tide.glb",
  },
  stages: {
    "skyline-arena": "/anime-aggressors/assets/stages/skyline-arena.glb",
  },
};

/** @deprecated use preloadBattlePresentation */
export async function loadCharacterGlb(characterId: string): Promise<THREE.Group | null> {
  return preloadBattlePresentation(characterId, "male").then((p) =>
    p.model_loaded ? takeCachedBattleScene(characterId, "male") : null,
  );
}
