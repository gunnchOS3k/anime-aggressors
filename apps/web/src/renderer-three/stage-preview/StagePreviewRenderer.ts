import * as THREE from "three";
import { buildStagePreviewScene, setupStagePreviewLighting } from "./StagePreviewScene.ts";
import {
  createStagePreviewCamera,
  positionStagePreviewCamera,
  updateStagePreviewCamera,
} from "./StagePreviewCamera.ts";

export type StagePreviewStats = {
  stageId: string;
  objectCount: number;
};

export class StagePreviewRenderer {
  readonly scene = new THREE.Scene();
  readonly camera: THREE.PerspectiveCamera;
  readonly renderer: THREE.WebGLRenderer;
  private stageGroup: THREE.Group | null = null;
  private currentStageId = "";
  private raf = 0;
  private t = 0;
  private canvas: HTMLCanvasElement;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.scene.background = new THREE.Color(0x060610);
    this.scene.fog = new THREE.Fog(0x060610, 400, 2200);
    this.camera = createStagePreviewCamera();
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    setupStagePreviewLighting(this.scene);
  }

  getStats(): StagePreviewStats {
    return { stageId: this.currentStageId, objectCount: this.countMeshes() };
  }

  hasVisibleGeometry(): boolean {
    return this.countMeshes() > 3;
  }

  setStage(stageId: string): void {
    if (stageId === this.currentStageId && this.stageGroup) return;
    if (this.stageGroup) {
      this.scene.remove(this.stageGroup);
      this.stageGroup = null;
    }
    const built = buildStagePreviewScene(stageId);
    this.stageGroup = built.group;
    this.currentStageId = built.stageId;
    this.scene.add(this.stageGroup);
    positionStagePreviewCamera(this.camera);
  }

  resize(width: number, height: number): void {
    const w = Math.max(width, 320);
    const h = Math.max(height, 200);
    this.renderer.setSize(w, h, false);
    updateStagePreviewCamera(this.camera, w / h);
  }

  start(): void {
    this.stop();
    const tick = () => {
      this.t += 1 / 60;
      if (this.stageGroup) {
        this.camera.position.x += Math.sin(this.t * 0.15) * 0.4;
      }
      this.renderer.render(this.scene, this.camera);
      this.raf = requestAnimationFrame(tick);
    };
    this.raf = requestAnimationFrame(tick);
  }

  stop(): void {
    if (this.raf) cancelAnimationFrame(this.raf);
    this.raf = 0;
  }

  dispose(): void {
    this.stop();
    this.renderer.dispose();
  }

  private countMeshes(): number {
    let n = 0;
    this.scene.traverse((o) => {
      if (o instanceof THREE.Mesh) n += 1;
    });
    return n;
  }
}

export function createStagePreviewRenderer(canvas: HTMLCanvasElement): StagePreviewRenderer {
  return new StagePreviewRenderer(canvas);
}
