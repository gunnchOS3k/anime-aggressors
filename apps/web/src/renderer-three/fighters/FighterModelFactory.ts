import * as THREE from "three";
import type { FighterSize } from "@anime-aggressors/game-core";
import type { FighterAppearance } from "./FighterAppearance.ts";
import { buildLowPolyHumanoid, disposeHumanoid, type LowPolyHumanoidParts } from "./LowPolyHumanoid.ts";
import { characterWorldScale } from "../RenderTypes.ts";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { resolveFighterAppearance } from "./FighterAppearance.ts";
import {
  takeCachedBattleScene,
  registerProvenance,
  type ModelProvenance,
  type ModelKind,
} from "../AssetLoader.ts";

export type FighterModelMode = "acceptance" | "dev";

let modelMode: FighterModelMode = "dev";

export function setFighterModelMode(mode: FighterModelMode): void {
  modelMode = mode;
}

export function getFighterModelMode(): FighterModelMode {
  return modelMode;
}

function emptyMesh(name: string): THREE.Mesh {
  const m = new THREE.Mesh(
    new THREE.BoxGeometry(0.01, 0.01, 0.01),
    new THREE.MeshBasicMaterial({ visible: false }),
  );
  m.name = name;
  return m;
}

function findBone(root: THREE.Object3D, name: string): THREE.Object3D | null {
  let found: THREE.Object3D | null = null;
  root.traverse((o) => {
    if (found) return;
    if (o.name === name || o.name.endsWith(`_${name}`) || o.name.endsWith(`:${name}`)) {
      found = o;
    }
  });
  return found;
}

function countSkinnedMeshes(root: THREE.Object3D): number {
  let n = 0;
  root.traverse((o) => {
    if ((o as THREE.SkinnedMesh).isSkinnedMesh) n += 1;
  });
  return n;
}

/**
 * Wrap an authored battle GLB into the pose-compatible parts contract.
 * Prefer real canonical deform bones when present (PRODUCTION_RIG).
 */
export function wrapAuthoredGlbAsParts(
  glbRoot: THREE.Group,
  appearance: FighterAppearance,
  provenance: ModelProvenance,
): LowPolyHumanoidParts {
  const root = new THREE.Group();
  root.name = `authored:${provenance.fighter_id}:${provenance.body_variant}`;
  root.userData.modelProvenance = provenance;
  root.userData.bodyVariant = appearance.bodyVariant;
  root.userData.storyForm = appearance.storyForm;
  root.userData.essenceTier = appearance.essenceTier;
  root.userData.prismaticGray = appearance.prismaticGray;
  root.userData.presentationKey = `${appearance.visualStyleId ?? appearance.name}:${appearance.bodyVariant}:${appearance.storyForm}:${appearance.essenceTier}`;
  root.userData.model_kind = provenance.model_kind;
  root.userData.fallback_used = provenance.fallback_used;
  root.userData.animation_binding = provenance.animation_binding;

  glbRoot.position.y = 0;
  root.add(glbRoot);

  const skinCount = countSkinnedMeshes(glbRoot);
  const hips = findBone(glbRoot, "Hips");
  const chest = findBone(glbRoot, "Chest") ?? findBone(glbRoot, "Spine");
  const headBone = findBone(glbRoot, "Head");
  const upperArmL = findBone(glbRoot, "UpperArm_L");
  const upperArmR = findBone(glbRoot, "UpperArm_R");
  const lowerArmL = findBone(glbRoot, "LowerArm_L");
  const lowerArmR = findBone(glbRoot, "LowerArm_R");
  const upperLegL = findBone(glbRoot, "UpperLeg_L");
  const upperLegR = findBone(glbRoot, "UpperLeg_R");
  const lowerLegL = findBone(glbRoot, "LowerLeg_L");
  const lowerLegR = findBone(glbRoot, "LowerLeg_R");
  const productionRig = skinCount > 0 && !!hips && !!chest && !!headBone;

  const torso = (chest as THREE.Object3D) ?? emptyMesh("proxy_torso");
  const head = (headBone as THREE.Object3D) ?? emptyMesh("proxy_head");
  const leftArm = (upperArmL as THREE.Object3D) ?? emptyMesh("proxy_leftArm");
  const rightArm = (upperArmR as THREE.Object3D) ?? emptyMesh("proxy_rightArm");
  const leftLeg = (upperLegL as THREE.Object3D) ?? emptyMesh("proxy_leftLeg");
  const rightLeg = (upperLegR as THREE.Object3D) ?? emptyMesh("proxy_rightLeg");

  if (!productionRig) {
    // Legacy proxy placement for non-skinned assets only
    if (!chest) torso.position.y = 1.05;
    if (!headBone) head.position.y = 1.78;
    if (!upperArmL) leftArm.position.set(-0.64, 1.15, 0);
    if (!upperArmR) rightArm.position.set(0.64, 1.15, 0);
    if (!upperLegL) leftLeg.position.set(-0.3, 0.4, 0);
    if (!upperLegR) rightLeg.position.set(0.3, 0.4, 0);
    if (torso.parent !== root && !(torso as THREE.Bone).isBone) root.add(torso);
    if (head.parent !== root && !(head as THREE.Bone).isBone) root.add(head);
    if (leftArm.parent !== root && !(leftArm as THREE.Bone).isBone) root.add(leftArm);
    if (rightArm.parent !== root && !(rightArm as THREE.Bone).isBone) root.add(rightArm);
    if (leftLeg.parent !== root && !(leftLeg as THREE.Bone).isBone) root.add(leftLeg);
    if (rightLeg.parent !== root && !(rightLeg as THREE.Bone).isBone) root.add(rightLeg);
  }

  root.userData.skin_count = skinCount;
  root.userData.production_rig = productionRig;
  root.userData.canonical_bones = {
    Hips: !!hips,
    Chest: !!chest,
    Head: !!headBone,
    UpperArm_L: !!upperArmL,
    UpperArm_R: !!upperArmR,
    LowerArm_L: !!lowerArmL,
    LowerArm_R: !!lowerArmR,
    UpperLeg_L: !!upperLegL,
    UpperLeg_R: !!upperLegR,
    LowerLeg_L: !!lowerLegL,
    LowerLeg_R: !!lowerLegR,
  };
  if (productionRig) {
    provenance.animation_binding = "PRODUCTION_RIG";
    root.userData.animation_binding = "PRODUCTION_RIG";
    root.userData.modelProvenance = provenance;
  }

  const aura = new THREE.Mesh(
    new THREE.RingGeometry(0.58, 0.82, 28),
    new THREE.MeshBasicMaterial({
      color: appearance.vfx.aura,
      transparent: true,
      opacity: 0.28,
      side: THREE.DoubleSide,
    }),
  );
  aura.rotation.x = -Math.PI / 2;
  aura.position.y = 0.05;
  root.add(aura);

  const extras: THREE.Object3D[] = [];
  // Store bone refs for extended rig mapping
  if (hips) extras.push(Object.assign(hips, { name: hips.name || "Hips" }));
  if (lowerArmL) extras.push(lowerArmL);
  if (lowerArmR) extras.push(lowerArmR);
  if (lowerLegL) extras.push(lowerLegL);
  if (lowerLegR) extras.push(lowerLegR);

  applyStoryPresentation(root, appearance, extras, head);

  registerProvenance(provenance.runtime_instance_id, provenance);
  return { root, torso, head, leftArm, rightArm, leftLeg, rightLeg, accessory: null, extras, aura };
}

function applyStoryPresentation(
  root: THREE.Group,
  appearance: FighterAppearance,
  extras: THREE.Object3D[],
  head: THREE.Object3D,
): void {
  // Mutate materials for puppet / gray forms on skinned meshes
  root.traverse((o) => {
    const mesh = o as THREE.Mesh;
    if (!mesh.isMesh || !mesh.material) return;
    const mats = Array.isArray(mesh.material) ? mesh.material : [mesh.material];
    for (const mat of mats) {
      const m = mat as THREE.MeshStandardMaterial & { color?: THREE.Color; emissive?: THREE.Color };
      if (!m.color) continue;
      if (appearance.storyForm === "BLACK_PUPPET") {
        m.color.multiplyScalar(0.25);
        if (m.emissive) m.emissive.setHex(appearance.accentHex).multiplyScalar(0.15);
        m.userData.puppet = "BLACK";
      } else if (appearance.storyForm === "WHITE_PUPPET") {
        m.color.lerp(new THREE.Color(0xf7f3e8), 0.85);
        if (m.emissive) m.emissive.setHex(0x111111).multiplyScalar(0.08);
        m.userData.puppet = "WHITE";
      }
      if (appearance.prismaticGray) {
        m.color.setHex(0x8a8e96);
        if (m.emissive) {
          const spectrum = [0xff0000, 0xff7a00, 0xffee00, 0x00cc44, 0x0088ff, 0x4b0082, 0xee82ee];
          m.emissive.setHex(spectrum[Math.floor(Math.random() * spectrum.length)]!);
          m.emissiveIntensity = 0.35;
        }
        m.userData.prismaticGray = true;
      }
    }
  });

  if (appearance.storyForm === "BLACK_PUPPET" || appearance.storyForm === "WHITE_PUPPET") {
    const maskMat = appearance.storyForm === "BLACK_PUPPET" ? 0x0a0a0d : 0xf7f3e8;
    const mask = new THREE.Mesh(
      new THREE.BoxGeometry(0.45, 0.35, 0.2),
      new THREE.MeshBasicMaterial({ color: maskMat }),
    );
    mask.name = "story_puppet_mask";
    mask.position.set(0, 0.05, 0.28);
    head.add(mask);
    extras.push(mask);
  }
  if (appearance.prismaticGray) {
    const prism = new THREE.Mesh(
      new THREE.BoxGeometry(0.18, 0.18, 0.18),
      new THREE.MeshBasicMaterial({ color: 0xc0c4d0 }),
    );
    prism.position.set(0.35, 0.0, 0.15);
    prism.name = "prismatic_gray_marker";
    head.add(prism);
    extras.push(prism);
  }
}

export function createAuthoredOrGeneratedModel(appearance: FighterAppearance): LowPolyHumanoidParts {
  const fighterId = appearance.fighterId;
  const bodyVariant = appearance.bodyVariant ?? "male";
  const glb = takeCachedBattleScene(fighterId, bodyVariant);
  if (glb) {
    const skinCount = countSkinnedMeshes(glb);
    const provenance: ModelProvenance = {
      fighter_id: fighterId,
      body_variant: bodyVariant,
      model_kind: "AUTHORED_GLB",
      model_path: `/anime-aggressors/assets/characters/${fighterId}/${bodyVariant}/${fighterId}_${bodyVariant}_battle.glb`,
      model_sha256: (glb.userData.sha256 as string) || "cached",
      model_exists: true,
      model_loaded: true,
      fallback_used: false,
      runtime_instance_id: `${fighterId}:${bodyVariant}@${Math.random().toString(36).slice(2, 10)}`,
      animation_binding: skinCount > 0 ? "PRODUCTION_RIG" : "ROOT_PROXY_PENDING_SKINNED_RIG",
    };
    const parts = wrapAuthoredGlbAsParts(glb, appearance, provenance);
    if (modelMode === "acceptance" && provenance.animation_binding !== "PRODUCTION_RIG") {
      throw new Error(
        `ACCEPTANCE: ${fighterId}/${bodyVariant} missing PRODUCTION_RIG (got ${provenance.animation_binding})`,
      );
    }
    const scale = characterWorldScale(appearance.size);
    parts.root.scale.setScalar(scale);
    return parts;
  }

  if (modelMode === "acceptance") {
    throw new Error(
      `ACCEPTANCE: authored battle GLB not preloaded for ${fighterId}/${bodyVariant} (model_kind would be GENERATED_LOW_POLY)`,
    );
  }

  const parts = buildLowPolyHumanoid(appearance);
  const scale = characterWorldScale(appearance.size);
  parts.root.scale.setScalar(scale);
  const provenance: ModelProvenance = {
    fighter_id: fighterId,
    body_variant: bodyVariant,
    model_kind: "GENERATED_LOW_POLY",
    model_path: "procedural:LowPolyHumanoid",
    model_sha256: "",
    model_exists: false,
    model_loaded: false,
    fallback_used: true,
    runtime_instance_id: `fallback:${fighterId}:${bodyVariant}@${Math.random().toString(36).slice(2, 8)}`,
    animation_binding: "LOW_POLY_POSE",
  };
  parts.root.userData.modelProvenance = provenance;
  parts.root.userData.model_kind = provenance.model_kind as ModelKind;
  parts.root.userData.fallback_used = true;
  registerProvenance(provenance.runtime_instance_id, provenance);
  return parts;
}

/** Preview scene uses unscaled humanoid (~2 units tall) — prefers authored when cached. */
export function createPreviewFighterModel(appearance: FighterAppearance): LowPolyHumanoidParts {
  const fighterId = appearance.fighterId;
  const glb = takeCachedBattleScene(fighterId, appearance.bodyVariant ?? "male");
  if (glb) {
    const provenance: ModelProvenance = {
      fighter_id: fighterId,
      body_variant: appearance.bodyVariant ?? "male",
      model_kind: "AUTHORED_GLB",
      model_path: `/anime-aggressors/assets/characters/${fighterId}/${appearance.bodyVariant ?? "male"}/${fighterId}_${appearance.bodyVariant ?? "male"}_battle.glb`,
      model_sha256: "cached",
      model_exists: true,
      model_loaded: true,
      fallback_used: false,
      runtime_instance_id: `preview:${fighterId}`,
      animation_binding: countSkinnedMeshes(glb) > 0 ? "PRODUCTION_RIG" : "ROOT_PROXY_PENDING_SKINNED_RIG",
    };
    const parts = wrapAuthoredGlbAsParts(glb, appearance, provenance);
    parts.root.scale.setScalar(appearance.scale);
    return parts;
  }
  const parts = buildLowPolyHumanoid(appearance);
  parts.root.scale.setScalar(appearance.scale);
  parts.root.userData.model_kind = "GENERATED_LOW_POLY";
  parts.root.userData.fallback_used = true;
  return parts;
}

export function createFighterModel(appearance: FighterAppearance): LowPolyHumanoidParts {
  return createAuthoredOrGeneratedModel(appearance);
}

export function createFallbackFighterModel(playerIndex = 0): LowPolyHumanoidParts {
  const appearance = resolveFighterAppearance(getDefaultCreatedFighter(playerIndex));
  const parts = buildLowPolyHumanoid(appearance);
  const scale = characterWorldScale(appearance.size);
  parts.root.scale.setScalar(scale);
  parts.root.userData.model_kind = "DEBUG_FALLBACK";
  parts.root.userData.fallback_used = true;
  return parts;
}

export function destroyFighterModel(parts: LowPolyHumanoidParts): void {
  disposeHumanoid(parts);
}

export function countFighterMeshes(parts: LowPolyHumanoidParts): number {
  let n = 0;
  parts.root.traverse((o) => {
    if (o instanceof THREE.Mesh && (o.material as THREE.Material).visible !== false) n += 1;
  });
  return n;
}

export function getModelProvenanceFromParts(parts: LowPolyHumanoidParts): ModelProvenance | null {
  return (parts.root.userData.modelProvenance as ModelProvenance) ?? null;
}

export { buildLowPolyHumanoid, disposeHumanoid, type LowPolyHumanoidParts };
