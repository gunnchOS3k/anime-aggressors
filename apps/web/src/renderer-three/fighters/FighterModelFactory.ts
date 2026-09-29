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

/**
 * Wrap an authored battle GLB into the pose-compatible parts contract.
 * Static candidate meshes use invisible limb proxies until skinned rig export lands.
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

  glbRoot.position.y = 0;
  root.add(glbRoot);

  // Pose API compatibility — invisible proxies; authored mesh remains visible body.
  const torso = emptyMesh("proxy_torso");
  const head = emptyMesh("proxy_head");
  const leftArm = emptyMesh("proxy_leftArm");
  const rightArm = emptyMesh("proxy_rightArm");
  const leftLeg = emptyMesh("proxy_leftLeg");
  const rightLeg = emptyMesh("proxy_rightLeg");
  torso.position.y = 1.05;
  head.position.y = 1.78;
  leftArm.position.set(-0.64, 1.15, 0);
  rightArm.position.set(0.64, 1.15, 0);
  leftLeg.position.set(-0.3, 0.4, 0);
  rightLeg.position.set(0.3, 0.4, 0);
  root.add(torso, head, leftArm, rightArm, leftLeg, rightLeg);

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

  // Story-form visual markers on authored body
  const extras: THREE.Object3D[] = [];
  if (appearance.storyForm === "BLACK_PUPPET" || appearance.storyForm === "WHITE_PUPPET") {
    const maskMat = appearance.storyForm === "BLACK_PUPPET" ? 0x0a0a0d : 0xf7f3e8;
    const mask = new THREE.Mesh(
      new THREE.BoxGeometry(0.45, 0.35, 0.2),
      new THREE.MeshBasicMaterial({ color: maskMat }),
    );
    mask.position.set(0, 1.78, 0.35);
    mask.name = "story_puppet_mask";
    extras.push(mask);
    root.add(mask);
  }
  if (appearance.prismaticGray) {
    const prism = new THREE.Mesh(
      new THREE.BoxGeometry(0.18, 0.18, 0.18),
      new THREE.MeshBasicMaterial({ color: 0xc0c4d0 }),
    );
    prism.position.set(0.42, 1.55, 0.2);
    prism.name = "prismatic_gray_marker";
    extras.push(prism);
    root.add(prism);
  }

  registerProvenance(provenance.runtime_instance_id, provenance);
  return { root, torso, head, leftArm, rightArm, leftLeg, rightLeg, accessory: null, extras, aura };
}

function resolveFighterId(appearance: FighterAppearance): string {
  return (appearance.visualStyleId && appearance.visualStyleId.length > 2
    ? // visualStyleId is short ("ember") — prefer name mapping via userData if set
      appearance.visualStyleId
    : appearance.name
  )
    .toLowerCase()
    .replace(/\s+/g, "-");
}

/** Prefer explicit fighter id from appearance if callers pass it via visualStyleId full id. */
function fighterIdFromAppearance(appearance: FighterAppearance): string {
  const style = appearance.visualStyleId ?? "";
  const map: Record<string, string> = {
    ember: "ember-vale",
    rook: "rook-ironside",
    juno: "juno-spark",
    kaia: "kaia-windrow",
    nix: "nix-calder",
    orion: "orion-vell",
    vesper: "vesper-nyx",
    yin: "yin",
    yang: "yang",
  };
  if (style in map) return map[style]!;
  if (style.includes("-")) return style;
  // Fall back to name
  const fromName = appearance.name.toLowerCase().replace(/\s+/g, "-");
  if (fromName === "yin" || fromName === "yang") return fromName;
  return map[fromName.split("-")[0]!] ?? fromName;
}

export function createAuthoredOrGeneratedModel(appearance: FighterAppearance): LowPolyHumanoidParts {
  const fighterId = appearance.fighterId;
  const bodyVariant = appearance.bodyVariant ?? "male";
  const glb = takeCachedBattleScene(fighterId, bodyVariant);
  if (glb) {
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
      animation_binding: "ROOT_PROXY_PENDING_SKINNED_RIG",
    };
    // Prefer sha from manifest if available on window preload
    const parts = wrapAuthoredGlbAsParts(glb, appearance, provenance);
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
      animation_binding: "ROOT_PROXY_PENDING_SKINNED_RIG",
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
