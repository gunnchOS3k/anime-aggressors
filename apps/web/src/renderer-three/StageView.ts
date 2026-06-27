import * as THREE from "three";
import { fpToWorld } from "./RenderTypes.js";
import { buildStageModel } from "./stages/StageModelFactory.ts";

export class StageView {
  readonly group = new THREE.Group();
  private blastZone: THREE.LineSegments | null = null;
  private stageId = "";

  setStage(stageId: string): void {
    if (stageId === this.stageId) return;
    this.stageId = stageId;
    while (this.group.children.length > 0) {
      const child = this.group.children[0];
      this.group.remove(child);
      child.traverse((obj) => {
        if (obj instanceof THREE.Mesh) {
          obj.geometry.dispose();
          if (Array.isArray(obj.material)) obj.material.forEach((m) => m.dispose());
          else obj.material.dispose();
        }
      });
    }
    const built = buildStageModel(stageId);
    this.group.add(built.group);
    this.blastZone = null;
  }

  setBlastZonesVisible(visible: boolean, bounds?: { left: number; right: number; top: number; bottom: number }): void {
    if (!visible) {
      if (this.blastZone) this.blastZone.visible = false;
      return;
    }

    if (!this.blastZone && bounds) {
      const points = [
        new THREE.Vector3(fpToWorld(bounds.left), fpToWorld(bounds.top), 0),
        new THREE.Vector3(fpToWorld(bounds.right), fpToWorld(bounds.top), 0),
        new THREE.Vector3(fpToWorld(bounds.right), fpToWorld(bounds.bottom), 0),
        new THREE.Vector3(fpToWorld(bounds.left), fpToWorld(bounds.bottom), 0),
        new THREE.Vector3(fpToWorld(bounds.left), fpToWorld(bounds.top), 0),
      ];
      const geo = new THREE.BufferGeometry().setFromPoints(points);
      this.blastZone = new THREE.LineSegments(
        geo,
        new THREE.LineBasicMaterial({ color: 0xff6b6b, transparent: true, opacity: 0.5 }),
      );
      this.group.add(this.blastZone);
    }
    if (this.blastZone) this.blastZone.visible = true;
  }
}
