import * as THREE from "three";
import type { PlayerState } from "@anime-aggressors/game-core";
import { getDisplayColor, getVisualScale } from "@anime-aggressors/game-core";
import { fpToWorld } from "./RenderTypes.js";
import { addOutline, createPlayerMaterial } from "./Materials.js";

export class CharacterView {
  readonly group = new THREE.Group();
  private body: THREE.Mesh;
  private head: THREE.Mesh;
  private shieldMesh: THREE.Mesh;
  private label: THREE.Sprite | null = null;

  constructor(playerId: number) {
    const color = "#aaaaaa";
    const mat = createPlayerMaterial(color);

    const bodyGeo = new THREE.CapsuleGeometry(0.45, 1.0, 6, 12);
    this.body = new THREE.Mesh(bodyGeo, mat);
    this.body.position.y = 1.0;
    addOutline(this.body);

    const headGeo = new THREE.SphereGeometry(0.38, 16, 16);
    this.head = new THREE.Mesh(headGeo, mat.clone());
    this.head.position.y = 1.85;
    addOutline(this.head);

    const shieldGeo = new THREE.SphereGeometry(1.1, 16, 16);
    this.shieldMesh = new THREE.Mesh(
      shieldGeo,
      new THREE.MeshBasicMaterial({ color: 0x66ccff, transparent: true, opacity: 0.25 }),
    );
    this.shieldMesh.visible = false;

    this.group.add(this.body, this.head, this.shieldMesh);
  }

  update(player: PlayerState): void {
    const scale = getVisualScale(player);
    this.group.scale.set(scale * player.facing, scale, scale);
    this.group.position.set(fpToWorld(player.x), fpToWorld(player.y), player.id * 0.3);

    const displayColor = getDisplayColor(player);
    const matColor = new THREE.Color(displayColor);
    const squash = player.actionState === "jumping" ? 0.92 : player.actionState === "falling" ? 1.05 : 1;
    this.body.scale.y = squash;
    this.head.scale.y = 1 / squash;

    this.shieldMesh.visible = player.actionState === "shielding";
    const shieldColor = new THREE.Color(displayColor);
    (this.shieldMesh.material as THREE.MeshBasicMaterial).color.copy(shieldColor);

    if (player.actionState === "attacking") {
      this.body.rotation.z = -0.25 * player.facing;
    } else if (player.actionState === "special") {
      this.body.rotation.z = -0.45 * player.facing;
    } else {
      this.body.rotation.z = 0;
    }

    if (player.actionState === "hitstun") {
      (this.body.material as THREE.MeshToonMaterial).color.setHex(0xff8888);
    } else if (player.actionState === "defeated") {
      this.group.visible = false;
    } else {
      this.group.visible = true;
      (this.body.material as THREE.MeshToonMaterial).color.copy(matColor);
      (this.head.material as THREE.MeshToonMaterial).color.copy(matColor);
    }
  }

  dispose(): void {
    this.body.geometry.dispose();
    this.head.geometry.dispose();
    this.shieldMesh.geometry.dispose();
  }
}

export async function loadCharacterModel(_characterId: string): Promise<THREE.Group> {
  // GLB pipeline stub — returns empty group until assets land
  return new THREE.Group();
}
