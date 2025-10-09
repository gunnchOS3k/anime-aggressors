import * as THREE from 'three';
import { GamepadManager } from '@gunnch/input';

export class TrainingScene {
  private scene: THREE.Scene;
  private camera: THREE.PerspectiveCamera;
  private renderer: THREE.WebGLRenderer;
  private gamepadManager: GamepadManager;
  
  // Training specific
  private sandbag: THREE.Mesh;
  private inputOverlay: HTMLElement;
  private buttonMap: HTMLElement;

  constructor() {
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
  }

  async init(): Promise<void> {
    this.setupEnvironment();
    this.setupSandbag();
    this.setupUI();
    this.setupLighting();
  }

  private setupEnvironment(): void {
    // Arena floor
    const floorGeometry = new THREE.PlaneGeometry(20, 20);
    const floorMaterial = new THREE.MeshLambertMaterial({ color: 0x333333 });
    const floor = new THREE.Mesh(floorGeometry, floorMaterial);
    floor.rotation.x = -Math.PI / 2;
    floor.receiveShadow = true;
    this.scene.add(floor);

    // Arena walls (invisible collision)
    const wallGeometry = new THREE.BoxGeometry(20, 5, 1);
    const wallMaterial = new THREE.MeshBasicMaterial({ 
      color: 0x666666, 
      transparent: true, 
      opacity: 0.3 
    });

    // Create walls around the arena
    const walls = [
      { x: 0, z: 10, rotation: 0 },
      { x: 0, z: -10, rotation: 0 },
      { x: 10, z: 0, rotation: Math.PI / 2 },
      { x: -10, z: 0, rotation: Math.PI / 2 }
    ];

    walls.forEach(wall => {
      const wallMesh = new THREE.Mesh(wallGeometry, wallMaterial);
      wallMesh.position.set(wall.x, 2.5, wall.z);
      wallMesh.rotation.y = wall.rotation;
      this.scene.add(wallMesh);
    });
  }

  private setupSandbag(): void {
    // Create sandbag dummy
    const sandbagGeometry = new THREE.CylinderGeometry(0.5, 0.8, 2, 8);
    const sandbagMaterial = new THREE.MeshLambertMaterial({ color: 0x8B4513 });
    this.sandbag = new THREE.Mesh(sandbagGeometry, sandbagMaterial);
    this.sandbag.position.set(0, 1, 0);
    this.sandbag.castShadow = true;
    this.scene.add(this.sandbag);

    // Add some animation
    this.animateSandbag();
  }

  private animateSandbag(): void {
    const animate = () => {
      this.sandbag.rotation.y += 0.01;
      this.sandbag.position.y = 1 + Math.sin(Date.now() * 0.001) * 0.1;
      requestAnimationFrame(animate);
    };
    animate();
  }

  private setupUI(): void {
    // Input overlay
    this.inputOverlay = document.createElement('div');
    this.inputOverlay.id = 'input-overlay';
    this.inputOverlay.style.cssText = `
      position: fixed;
      top: 20px;
      left: 20px;
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 20px;
      border-radius: 8px;
      font-family: monospace;
      font-size: 14px;
      z-index: 1000;
      min-width: 300px;
    `;
    document.body.appendChild(this.inputOverlay);

    // Button map overlay
    this.buttonMap = document.createElement('div');
    this.buttonMap.id = 'button-map';
    this.buttonMap.style.cssText = `
      position: fixed;
      bottom: 20px;
      right: 20px;
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 20px;
      border-radius: 8px;
      font-family: monospace;
      font-size: 12px;
      z-index: 1000;
      min-width: 200px;
    `;
    document.body.appendChild(this.buttonMap);

    this.updateButtonMap();
  }

  private updateButtonMap(): void {
    this.buttonMap.innerHTML = `
      <h3>🎮 Controls</h3>
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
        <div>Move: <span style="color: #00ff00;">Left Stick</span></div>
        <div>Jump: <span style="color: #00ff00;">A/Cross</span></div>
        <div>Light: <span style="color: #00ff00;">B/Circle</span></div>
        <div>Heavy: <span style="color: #00ff00;">X/Square</span></div>
        <div>Special: <span style="color: #00ff00;">Y/Triangle</span></div>
        <div>Dodge: <span style="color: #00ff00;">L1</span></div>
        <div>Block: <span style="color: #00ff00;">R1</span></div>
        <div>Pause: <span style="color: #00ff00;">Start</span></div>
      </div>
    `;
  }

  private setupLighting(): void {
    // Ambient light
    const ambientLight = new THREE.AmbientLight(0x404040, 0.6);
    this.scene.add(ambientLight);

    // Directional light
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(10, 10, 5);
    directionalLight.castShadow = true;
    directionalLight.shadow.mapSize.width = 2048;
    directionalLight.shadow.mapSize.height = 2048;
    this.scene.add(directionalLight);
  }

  update(deltaTime: number): void {
    // Update input display
    this.updateInputDisplay();
  }

  private updateInputDisplay(): void {
    // This would be called by the input system to show live input
    // For now, just show a placeholder
    this.inputOverlay.innerHTML = `
      <h3>🎮 Live Input</h3>
      <div>Move X: <span id="move-x">0.00</span></div>
      <div>Move Y: <span id="move-y">0.00</span></div>
      <div>Jump: <span id="jump">❌</span></div>
      <div>Light: <span id="light">❌</span></div>
      <div>Heavy: <span id="heavy">❌</span></div>
      <div>Special: <span id="special">❌</span></div>
      <div>Dodge: <span id="dodge">❌</span></div>
      <div>Block: <span id="block">❌</span></div>
    `;
  }

  handleResize(width: number, height: number): void {
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
  }

  destroy(): void {
    // Clean up UI
    if (this.inputOverlay && this.inputOverlay.parentNode) {
      this.inputOverlay.parentNode.removeChild(this.inputOverlay);
    }
    if (this.buttonMap && this.buttonMap.parentNode) {
      this.buttonMap.parentNode.removeChild(this.buttonMap);
    }
  }
}
