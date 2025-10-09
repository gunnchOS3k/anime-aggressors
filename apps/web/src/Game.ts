import * as THREE from 'three';

export class Game {
  private canvas: HTMLCanvasElement;
  private renderer: THREE.WebGLRenderer;
  private scene: THREE.Scene;
  private camera: THREE.PerspectiveCamera;
  private cube: THREE.Mesh;
  private isRunning = false;
  private lastTime = 0;

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

    // Initialize scene
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(
      75,
      window.innerWidth / window.innerHeight,
      0.1,
      1000
    );

    this.setupScene();
    this.setupLighting();
    this.setupControls();
  }

  private setupScene(): void {
    // Create a simple arena
    const arenaGeometry = new THREE.PlaneGeometry(20, 20);
    const arenaMaterial = new THREE.MeshLambertMaterial({ 
      color: 0x333333,
      transparent: true,
      opacity: 0.8
    });
    const arena = new THREE.Mesh(arenaGeometry, arenaMaterial);
    arena.rotation.x = -Math.PI / 2;
    arena.receiveShadow = true;
    this.scene.add(arena);

    // Create a simple character (cube for now)
    const geometry = new THREE.BoxGeometry(1, 2, 1);
    const material = new THREE.MeshLambertMaterial({ 
      color: 0x4ecdc4,
      transparent: true,
      opacity: 0.9
    });
    this.cube = new THREE.Mesh(geometry, material);
    this.cube.position.y = 1;
    this.cube.castShadow = true;
    this.scene.add(this.cube);

    // Add some decorative elements
    this.addDecorativeElements();
  }

  private addDecorativeElements(): void {
    // Add some floating particles
    for (let i = 0; i < 50; i++) {
      const particleGeometry = new THREE.SphereGeometry(0.1, 8, 8);
      const particleMaterial = new THREE.MeshBasicMaterial({ 
        color: Math.random() * 0xffffff,
        transparent: true,
        opacity: 0.6
      });
      const particle = new THREE.Mesh(particleGeometry, particleMaterial);
      
      particle.position.set(
        (Math.random() - 0.5) * 40,
        Math.random() * 20 + 5,
        (Math.random() - 0.5) * 40
      );
      
      this.scene.add(particle);
    }
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

    // Point lights for atmosphere
    const pointLight1 = new THREE.PointLight(0xff6b6b, 0.5, 20);
    pointLight1.position.set(-5, 5, -5);
    this.scene.add(pointLight1);

    const pointLight2 = new THREE.PointLight(0x4ecdc4, 0.5, 20);
    pointLight2.position.set(5, 5, 5);
    this.scene.add(pointLight2);
  }

  private setupControls(): void {
    // Keyboard controls
    document.addEventListener('keydown', (event) => {
      switch (event.code) {
        case 'ArrowLeft':
          this.cube.position.x -= 0.5;
          break;
        case 'ArrowRight':
          this.cube.position.x += 0.5;
          break;
        case 'ArrowUp':
          this.cube.position.z -= 0.5;
          break;
        case 'ArrowDown':
          this.cube.position.z += 0.5;
          break;
        case 'Space':
          this.cube.position.y += 1;
          setTimeout(() => {
            this.cube.position.y = 1;
          }, 200);
          break;
      }
    });

    // Mouse controls
    this.canvas.addEventListener('mousemove', (event) => {
      const rect = this.canvas.getBoundingClientRect();
      const x = (event.clientX - rect.left) / rect.width;
      const z = (event.clientY - rect.top) / rect.height;
      
      this.cube.position.x = (x - 0.5) * 20;
      this.cube.position.z = (z - 0.5) * 20;
    });
  }

  async init(): Promise<void> {
    try {
      // Position camera
      this.camera.position.set(0, 10, 10);
      this.camera.lookAt(0, 0, 0);
      
      // Start game loop
      this.isRunning = true;
      this.gameLoop();
      
      console.log('🎮 Anime Aggressors Demo initialized');
      this.showToast('🎮 Demo loaded! Use arrow keys or mouse to move, space to jump!');
    } catch (error) {
      console.error('Failed to initialize game:', error);
    }
  }

  private gameLoop = (currentTime: number = 0): void => {
    if (!this.isRunning) return;

    // Calculate delta time
    const deltaTime = (currentTime - this.lastTime) / 1000;
    this.lastTime = currentTime;

    // Animate cube
    this.cube.rotation.x += deltaTime;
    this.cube.rotation.y += deltaTime * 0.5;

    // Animate particles
    this.scene.children.forEach((child) => {
      if (child instanceof THREE.Mesh && child.geometry instanceof THREE.SphereGeometry) {
        child.position.y += Math.sin(currentTime * 0.001 + child.position.x) * 0.01;
        child.rotation.x += deltaTime;
        child.rotation.y += deltaTime * 0.5;
      }
    });

    // Render
    this.renderer.render(this.scene, this.camera);

    // Continue loop
    requestAnimationFrame(this.gameLoop);
  };

  handleResize(): void {
    const width = window.innerWidth;
    const height = window.innerHeight;

    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(width, height);
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
      border: 1px solid #4ecdc4;
    `;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
      if (document.body.contains(toast)) {
        document.body.removeChild(toast);
      }
    }, 5000);
  }

  destroy(): void {
    this.isRunning = false;
    this.renderer.dispose();
  }
}
