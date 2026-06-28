import * as THREE from "three";
import { fpToWorld } from "./RenderTypes.ts";
import { buildStageModel, buildFallbackStageModel } from "./stages/StageModelFactory.ts";

export class StageView {
  readonly group = new THREE.Group();
  private blastZone: THREE.LineSegments | null = null;
  private stageId = "";
  private objectCount = 0;

  setStage(stageId: string): number {
    if (stageId === this.stageId && this.objectCount > 0) return this.objectCount;
    this.stageId = stageId;
    this.clearChildren();

    let built;
    try {
      built = buildStageModel(stageId);
      if (built.objectCount === 0) {
        built = buildFallbackStageModel();
      }
    } catch {
      built = buildFallbackStageModel();
    }

    this.group.add(built.group);
    this.objectCount = built.objectCount;
    this.blastZone = null;
    return this.objectCount;
  }

  getObjectCount(): number {
    return this.objectCount;
  }

  private clearChildren(): void {
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
    this.objectCount = 0;
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
