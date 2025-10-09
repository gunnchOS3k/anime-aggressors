import * as THREE from 'three';

export class RenderSystem {
  private renderer: THREE.WebGLRenderer;
  private composer?: any; // For post-processing effects

  constructor(renderer: THREE.WebGLRenderer) {
    this.renderer = renderer;
    this.setupRenderer();
  }

  private setupRenderer(): void {
    // Enable shadows
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    
    // Set clear color
    this.renderer.setClearColor(0x87CEEB); // Sky blue
    
    // Enable antialiasing
    this.renderer.antialias = true;
  }

  render(scene: THREE.Scene, camera?: THREE.Camera): void {
    if (camera) {
      this.renderer.render(scene, camera);
    } else {
      // Use default camera if none provided
      const defaultCamera = new THREE.PerspectiveCamera(
        75,
        window.innerWidth / window.innerHeight,
        0.1,
        1000
      );
      this.renderer.render(scene, defaultCamera);
    }
  }

  setSize(width: number, height: number): void {
    this.renderer.setSize(width, height);
  }

  setPixelRatio(ratio: number): void {
    this.renderer.setPixelRatio(ratio);
  }

  destroy(): void {
    this.renderer.dispose();
  }
}
