import * as THREE from 'three';
import { LoadingScene } from './LoadingScene.js';
import { MenuScene } from './MenuScene.js';
import { CreatorScene } from './CreatorScene.js';
import { TrainingScene } from './TrainingScene.js';
import { VersusScene } from './VersusScene.js';

export type SceneType = 'loading' | 'menu' | 'creator' | 'training' | 'versus';

export class SceneManager {
  private scenes: Map<SceneType, any> = new Map();
  private currentScene: SceneType = 'loading';
  private camera: THREE.PerspectiveCamera;
  private scene: THREE.Scene;

  constructor() {
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(
      75,
      window.innerWidth / window.innerHeight,
      0.1,
      1000
    );
  }

  async init(): Promise<void> {
    // Initialize all scenes
    this.scenes.set('loading', new LoadingScene());
    this.scenes.set('menu', new MenuScene());
    this.scenes.set('creator', new CreatorScene());
    this.scenes.set('training', new TrainingScene());
    this.scenes.set('versus', new VersusScene());

    // Initialize current scene
    await this.scenes.get(this.currentScene)?.init();
  }

  getCurrentScene(): THREE.Scene {
    return this.scene;
  }

  getCamera(): THREE.PerspectiveCamera {
    return this.camera;
  }

  async switchScene(sceneType: SceneType): Promise<void> {
    // Clean up current scene
    this.scenes.get(this.currentScene)?.destroy();

    // Switch to new scene
    this.currentScene = sceneType;
    const newScene = this.scenes.get(sceneType);
    
    if (newScene) {
      await newScene.init();
    }
  }

  update(deltaTime: number): void {
    this.scenes.get(this.currentScene)?.update(deltaTime);
  }

  handleResize(width: number, height: number): void {
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
    
    this.scenes.get(this.currentScene)?.handleResize(width, height);
  }

  destroy(): void {
    this.scenes.forEach(scene => scene.destroy());
  }
}
