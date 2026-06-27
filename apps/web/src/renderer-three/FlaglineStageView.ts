import * as THREE from "three";
import type { TeamId } from "@anime-aggressors/game-core";
import { buildStageModel } from "./stages/StageModelFactory.ts";

const FLAGLINE_STAGE_BY_ROOM: Record<number, string> = {
  [-2]: "flagline-lunar-base",
  [-1]: "flagline-lunar-outpost",
  0: "flagline-center-clash",
  1: "flagline-solar-outpost",
  2: "flagline-solar-base",
};

export class FlaglineStageView {
  readonly group = new THREE.Group();
  private inner = new THREE.Group();
  private captureRing: THREE.Mesh;

  constructor() {
    this.group.add(this.inner);
    const built = buildStageModel("flagline-center-clash");
    this.inner.add(built.group);

    this.captureRing = new THREE.Mesh(
      new THREE.TorusGeometry(1.35, 0.08, 10, 40),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.55 }),
    );
    this.captureRing.rotation.x = Math.PI / 2;
    this.captureRing.position.set(12, 3.58, 0);
    this.group.add(this.captureRing);
  }

  setRoomTheme(roomIndex: number, winningBias: TeamId | null = null): void {
    const stageId = FLAGLINE_STAGE_BY_ROOM[roomIndex] ?? "flagline-center-clash";
    while (this.inner.children.length > 0) {
      const child = this.inner.children[0];
      this.inner.remove(child);
      child.traverse((obj) => {
        if (obj instanceof THREE.Mesh) {
          obj.geometry.dispose();
          if (Array.isArray(obj.material)) obj.material.forEach((m) => m.dispose());
          else obj.material.dispose();
        }
      });
    }
    this.inner.add(buildStageModel(stageId).group);

    const ringColor =
      winningBias === "solar" ? 0xffaa44 : winningBias === "lunar" ? 0x6699ff : 0xffffff;
    (this.captureRing.material as THREE.MeshBasicMaterial).color.setHex(ringColor);
  }
}
