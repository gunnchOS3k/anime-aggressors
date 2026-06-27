import * as THREE from "three";
import type { PlayerState } from "@anime-aggressors/game-core";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { fpToWorld } from "./RenderTypes.js";
import { resolveFighterAppearance, resolveFighterAppearanceFromPlayer } from "./fighters/FighterAppearance.ts";
import { createFighterModel, destroyFighterModel, type LowPolyHumanoidParts } from "./fighters/FighterModelFactory.ts";
import { applyFighterPose, computeFighterPose } from "./fighters/FighterAnimator.ts";

export class CharacterView {
  readonly group = new THREE.Group();
  private parts: LowPolyHumanoidParts;
  private shieldMesh: THREE.Mesh;
  private appearanceKey = "";
  private baseTorsoColor = new THREE.Color();

  constructor(playerId: number) {
    const appearance = resolveFighterAppearance(getDefaultCreatedFighter(playerId));
    this.parts = createFighterModel(appearance);
    this.group.add(this.parts.root);
    this.baseTorsoColor.setHex(appearance.primaryHex);

    this.shieldMesh = new THREE.Mesh(
      new THREE.SphereGeometry(1.15, 16, 16),
      new THREE.MeshBasicMaterial({ color: appearance.vfx.shield, transparent: true, opacity: 0.22 }),
    );
    this.shieldMesh.visible = false;
    this.group.add(this.shieldMesh);
    this.appearanceKey = `${appearance.name}-${appearance.color}-${appearance.size}`;
  }

  update(player: PlayerState, frame = 0): void {
    const appearance = resolveFighterAppearanceFromPlayer(player);
    const key = `${appearance.name}-${appearance.color}-${appearance.size}`;
    if (key !== this.appearanceKey) {
      this.group.remove(this.parts.root);
      destroyFighterModel(this.parts);
      this.parts = createFighterModel(appearance);
      this.group.add(this.parts.root);
      this.appearanceKey = key;
      this.baseTorsoColor.setHex(appearance.primaryHex);
      (this.shieldMesh.material as THREE.MeshBasicMaterial).color.setHex(appearance.vfx.shield);
    }

    const pose = computeFighterPose(player, frame);
    applyFighterPose(this.parts, pose, player.facing);

    this.group.position.set(fpToWorld(player.x), fpToWorld(player.y), player.id * 0.35);
    this.shieldMesh.visible = player.actionState === "shielding";
    this.shieldMesh.position.set(0, 1.1, 0.1);

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
      torsoMat.emissiveIntensity = 0.08;
    }
  }

  dispose(): void {
    destroyFighterModel(this.parts);
    this.shieldMesh.geometry.dispose();
    (this.shieldMesh.material as THREE.Material).dispose();
  }
}

export async function loadCharacterModel(_characterId: string): Promise<THREE.Group> {
  return new THREE.Group();
}
