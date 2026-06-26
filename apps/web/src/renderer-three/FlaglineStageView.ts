import * as THREE from "three";
import type { TeamId } from "@anime-aggressors/game-core";

export class FlaglineStageView {
  readonly group = new THREE.Group();
  private floor: THREE.Mesh;

  constructor() {
    this.floor = new THREE.Mesh(
      new THREE.BoxGeometry(24, 0.4, 6),
      new THREE.MeshStandardMaterial({ color: 0x333344 }),
    );
    this.floor.position.y = 3;
    this.group.add(this.floor);
  }

  setRoomTheme(roomIndex: number, winningBias: TeamId | null = null): void {
    const colors: Record<number, number> = {
      [-2]: 0x2a3555,
      [-1]: 0x334466,
      [0]: 0x3a3a4a,
      [1]: 0x554433,
      [2]: 0x553322,
    };
    let color = colors[roomIndex] ?? 0x3a3a4a;
    if (winningBias === "solar") color = 0x664422;
    if (winningBias === "lunar") color = 0x223366;
    (this.floor.material as THREE.MeshStandardMaterial).color.setHex(color);
  }
}
