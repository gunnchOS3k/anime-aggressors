import * as THREE from "three";
import type { PlayerState } from "@anime-aggressors/game-core";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { characterWorldScale, fpToWorld } from "./RenderTypes.ts";
import { resolveFighterAppearance, resolveFighterAppearanceFromPlayer } from "./fighters/FighterAppearance.ts";
import {
  createFighterModel,
  destroyFighterModel,
  createFallbackFighterModel,
  type LowPolyHumanoidParts,
} from "./fighters/FighterModelFactory.ts";
import { applyFighterPose, computeFighterPose } from "./fighters/FighterAnimator.ts";
import { ContactShadow } from "./vfx/ContactShadow.ts";

export class CharacterView {
  readonly group = new THREE.Group();
  private parts: LowPolyHumanoidParts;
  private shieldMesh: THREE.Mesh;
  private contactShadow: ContactShadow;
  private appearanceKey = "";
  private baseTorsoColor = new THREE.Color();
  private shieldColor = 0x5599ff;
  private fighterSize: import("@anime-aggressors/game-core").FighterSize = "medium";

  constructor(playerId: number) {
    let appearance;
    try {
      appearance = resolveFighterAppearance(getDefaultCreatedFighter(playerId));
      this.parts = createFighterModel(appearance);
    } catch {
      appearance = resolveFighterAppearance(getDefaultCreatedFighter(playerId));
      this.parts = createFallbackFighterModel(playerId);
    }
    this.fighterSize = appearance.size;
    this.group.add(this.parts.root);
    this.appearanceKey = `${appearance.name}-${appearance.color}-${appearance.size}`;
    this.baseTorsoColor.setHex(appearance.primaryHex);
    this.shieldColor = appearance.vfx.shield;

    const scale = characterWorldScale(appearance.size);
    this.contactShadow = new ContactShadow(scale * 0.42, 0x000000, 0.32);
    this.group.add(this.contactShadow.mesh);

    const shieldR = scale * 0.45;
    this.shieldMesh = new THREE.Mesh(
      new THREE.SphereGeometry(shieldR, 16, 16),
      new THREE.MeshBasicMaterial({ color: this.shieldColor, transparent: true, opacity: 0.22 }),
    );
    this.shieldMesh.visible = false;
    this.group.add(this.shieldMesh);
  }

  update(player: PlayerState, frame = 0): void {
    let appearance;
    try {
      appearance = resolveFighterAppearanceFromPlayer(player);
      const key = `${appearance.name}-${appearance.color}-${appearance.size}`;
      if (key !== this.appearanceKey) {
        this.group.remove(this.parts.root);
        destroyFighterModel(this.parts);
        try {
          this.parts = createFighterModel(appearance);
        } catch {
          this.parts = createFallbackFighterModel(player.id);
        }
        this.group.add(this.parts.root);
        this.appearanceKey = key;
        this.fighterSize = appearance.size;
        this.baseTorsoColor.setHex(appearance.primaryHex);
        this.shieldColor = appearance.vfx.shield;
        (this.shieldMesh.material as THREE.MeshBasicMaterial).color.setHex(this.shieldColor);
      }
    } catch {
      appearance = resolveFighterAppearance(getDefaultCreatedFighter(player.id));
    }

    const pose = computeFighterPose(player, frame);
    applyFighterPose(this.parts, pose, player.facing);

    const scale = characterWorldScale(this.fighterSize);
    this.group.position.set(fpToWorld(player.x), fpToWorld(player.y), player.id * 1.4);
    this.contactShadow.setRadius(scale * 0.42);
    this.shieldMesh.visible = player.actionState === "shielding";
    this.shieldMesh.position.set(0, scale * 1.1, scale * 0.12);

    const torsoMat = this.parts.torso.material as THREE.MeshToonMaterial;
    if (player.actionState === "hitstun") {
      torsoMat.color.set(0xff8888);
      torsoMat.emissive.setHex(0xff3333);
      torsoMat.emissiveIntensity = 0.35;
    } else if (player.actionState === "defeated") {
      this.group.visible = false;
    } else {
      this.group.visible = true;
      torsoMat.color.copy(this.baseTorsoColor);
      torsoMat.emissive.setHex(appearance.accentHex);
      torsoMat.emissiveIntensity = player.actionState === "auraCharging" ? 0.18 + player.aura.level * 0.08 : 0.12;
      const auraMat = this.parts.aura.material as THREE.MeshBasicMaterial;
      auraMat.opacity = player.actionState === "auraCharging" ? 0.25 + player.aura.level * 0.2 : 0.15 + player.aura.level * 0.05;
    }
  }

  getParts(): LowPolyHumanoidParts {
    return this.parts;
  }

  dispose(): void {
    destroyFighterModel(this.parts);
    this.contactShadow.dispose();
    this.shieldMesh.geometry.dispose();
    (this.shieldMesh.material as THREE.Material).dispose();
  }
}

export async function loadCharacterModel(_characterId: string): Promise<THREE.Group> {
  return new THREE.Group();
}
