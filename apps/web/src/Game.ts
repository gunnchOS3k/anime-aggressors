import * as THREE from 'three';
import { GamepadManager } from '@gunnch/input';
import { SceneManager } from './scenes/SceneManager.js';
import { InputSystem } from './systems/InputSystem.js';
import { RenderSystem } from './systems/RenderSystem.js';

export class Game {
  private canvas: HTMLCanvasElement;
  private renderer: THREE.WebGLRenderer;
  private sceneManager: SceneManager;
  private inputSystem: InputSystem;
  private renderSystem: RenderSystem;
  private gamepadManager: GamepadManager;
  
  private isRunning = false;
  private lastTime = 0;
  private deltaTime = 0;

  constructor() {
    this.canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
    if (!this.canvas) {
      throw new Error('Game canvas not found');
    }

    // Initialize renderer
    this.renderer = new THREE.WebGLRenderer({
      canvas: this.canvas,
      antialias: true,
      alpha: true
    });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    // Initialize systems
    this.gamepadManager = new GamepadManager({
      deadzone: 0.15,
      enableVibration: true
    });

    this.inputSystem = new InputSystem(this.gamepadManager);
    this.sceneManager = new SceneManager();
    this.renderSystem = new RenderSystem(this.renderer);

    this.setupGamepadEvents();
  }

  async init(): Promise<void> {
    try {
      // Initialize scene manager
      await this.sceneManager.init();
      
      // Start gamepad manager
      this.gamepadManager.start();
      
      // Start game loop
      this.isRunning = true;
      this.gameLoop();
      
      console.log('🎮 Anime Aggressors initialized');
    } catch (error) {
      console.error('Failed to initialize game:', error);
    }
  }

  private setupGamepadEvents(): void {
    this.gamepadManager.onConnect = (info) => {
      console.log(`🎮 Controller connected: ${info.id}`);
      this.showToast(`Controller connected: ${info.id}`);
    };

    this.gamepadManager.onDisconnect = (info) => {
      console.log(`🎮 Controller disconnected: ${info.id}`);
      this.showToast(`Controller disconnected: ${info.id}`);
    };

    this.gamepadManager.onInput = (player, actions) => {
      this.inputSystem.updateActions(player, actions);
    };
  }

  private gameLoop = (currentTime: number = 0): void => {
    if (!this.isRunning) return;

    // Calculate delta time
    this.deltaTime = (currentTime - this.lastTime) / 1000;
    this.lastTime = currentTime;

    // Update systems
    this.inputSystem.update(this.deltaTime);
    this.sceneManager.update(this.deltaTime);

    // Render
    this.renderSystem.render(this.sceneManager.getCurrentScene());

    // Continue loop
    requestAnimationFrame(this.gameLoop);
  };

  handleResize(): void {
    const width = window.innerWidth;
    const height = window.innerHeight;

    this.renderer.setSize(width, height);
    this.sceneManager.handleResize(width, height);
  }

  private showToast(message: string): void {
    // Simple toast notification
    const toast = document.createElement('div');
    toast.textContent = message;
    toast.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      z-index: 1000;
      font-family: monospace;
      font-size: 14px;
    `;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
      document.body.removeChild(toast);
    }, 3000);
  }

  destroy(): void {
    this.isRunning = false;
    this.gamepadManager.stop();
    this.sceneManager.destroy();
    this.renderSystem.destroy();
  }
}
