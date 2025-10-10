import * as THREE from 'three';
export class GameEngine {
    constructor(canvas) {
        this.players = [];
        this.isRunning = false;
        this.lastTime = 0;
        this.deltaTime = 0;
        this.gameLoop = (currentTime = 0) => {
            if (!this.isRunning)
                return;
            // Calculate delta time
            this.deltaTime = (currentTime - this.lastTime) / 1000;
            this.lastTime = currentTime;
            // Update players
            this.players.forEach(player => {
                if (player.isAI) {
                    this.updateAI(player);
                }
                this.updatePlayer(player);
            });
            // Update camera to follow player
            if (this.players.length > 0) {
                const player = this.players[0];
                this.camera.position.set(player.position.x, player.position.y + 10, player.position.z + 15);
                this.camera.lookAt(player.position);
            }
            // Render
            this.renderer.render(this.scene, this.camera);
            // Continue loop
            requestAnimationFrame(this.gameLoop);
        };
        this.canvas = canvas;
        this.initializeRenderer();
        this.initializeScene();
        this.initializeCamera();
        this.initializeStage();
        this.setupLighting();
        this.setupControls();
        this.gameState = {
            players: this.players,
            stage: this.stage,
            camera: this.camera,
            renderer: this.renderer,
            scene: this.scene,
            isRunning: this.isRunning,
            deltaTime: this.deltaTime
        };
    }
    initializeRenderer() {
        this.renderer = new THREE.WebGLRenderer({
            canvas: this.canvas,
            antialias: true,
            alpha: true
        });
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        this.renderer.shadowMap.enabled = true;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        this.renderer.setClearColor(0x87CEEB); // Sky blue
    }
    initializeScene() {
        this.scene = new THREE.Scene();
        this.scene.fog = new THREE.Fog(0x87CEEB, 10, 100);
    }
    initializeCamera() {
        this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
        this.camera.position.set(0, 15, 20);
        this.camera.lookAt(0, 0, 0);
    }
    initializeStage() {
        // Create arena floor
        const floorGeometry = new THREE.PlaneGeometry(30, 30);
        const floorMaterial = new THREE.MeshLambertMaterial({
            color: 0x333333,
            transparent: true,
            opacity: 0.9
        });
        const floor = new THREE.Mesh(floorGeometry, floorMaterial);
        floor.rotation.x = -Math.PI / 2;
        floor.receiveShadow = true;
        this.scene.add(floor);
        // Create arena walls
        const wallGeometry = new THREE.BoxGeometry(30, 8, 1);
        const wallMaterial = new THREE.MeshLambertMaterial({
            color: 0x666666,
            transparent: true,
            opacity: 0.7
        });
        const walls = [
            { x: 0, z: 15, rotation: 0 },
            { x: 0, z: -15, rotation: 0 },
            { x: 15, z: 0, rotation: Math.PI / 2 },
            { x: -15, z: 0, rotation: Math.PI / 2 }
        ];
        walls.forEach(wall => {
            const wallMesh = new THREE.Mesh(wallGeometry, wallMaterial);
            wallMesh.position.set(wall.x, 4, wall.z);
            wallMesh.rotation.y = wall.rotation;
            this.scene.add(wallMesh);
        });
        this.stage = {
            name: 'Training Ground',
            mesh: floor,
            boundaries: new THREE.Box3(new THREE.Vector3(-15, 0, -15), new THREE.Vector3(15, 10, 15)),
            spawnPoints: [
                new THREE.Vector3(-5, 1, 0),
                new THREE.Vector3(5, 1, 0)
            ]
        };
    }
    setupLighting() {
        // Ambient light
        const ambientLight = new THREE.AmbientLight(0x404040, 0.6);
        this.scene.add(ambientLight);
        // Directional light (sun)
        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        directionalLight.position.set(20, 20, 10);
        directionalLight.castShadow = true;
        directionalLight.shadow.mapSize.width = 2048;
        directionalLight.shadow.mapSize.height = 2048;
        directionalLight.shadow.camera.near = 0.5;
        directionalLight.shadow.camera.far = 50;
        directionalLight.shadow.camera.left = -25;
        directionalLight.shadow.camera.right = 25;
        directionalLight.shadow.camera.top = 25;
        directionalLight.shadow.camera.bottom = -25;
        this.scene.add(directionalLight);
        // Point lights for atmosphere
        const pointLight1 = new THREE.PointLight(0xff6b6b, 0.5, 30);
        pointLight1.position.set(-10, 8, -10);
        this.scene.add(pointLight1);
        const pointLight2 = new THREE.PointLight(0x4ecdc4, 0.5, 30);
        pointLight2.position.set(10, 8, 10);
        this.scene.add(pointLight2);
    }
    setupControls() {
        // Keyboard controls
        document.addEventListener('keydown', (event) => {
            this.handleKeyDown(event);
        });
        document.addEventListener('keyup', (event) => {
            this.handleKeyUp(event);
        });
        // Mouse controls
        this.canvas.addEventListener('mousemove', (event) => {
            this.handleMouseMove(event);
        });
        this.canvas.addEventListener('click', (event) => {
            this.handleMouseClick(event);
        });
    }
    handleKeyDown(event) {
        if (this.players.length === 0)
            return;
        const player = this.players[0]; // Player 1
        switch (event.code) {
            case 'ArrowLeft':
                player.input.moveX = -1;
                break;
            case 'ArrowRight':
                player.input.moveX = 1;
                break;
            case 'ArrowUp':
                player.input.moveY = -1;
                break;
            case 'ArrowDown':
                player.input.moveY = 1;
                break;
            case 'Space':
                event.preventDefault();
                player.input.jump = true;
                break;
            case 'KeyZ':
                player.input.light = true;
                break;
            case 'KeyX':
                player.input.heavy = true;
                break;
            case 'KeyC':
                player.input.special = true;
                break;
            case 'KeyA':
                player.input.dodge = true;
                break;
            case 'KeyS':
                player.input.block = true;
                break;
        }
    }
    handleKeyUp(event) {
        if (this.players.length === 0)
            return;
        const player = this.players[0];
        switch (event.code) {
            case 'ArrowLeft':
            case 'ArrowRight':
                player.input.moveX = 0;
                break;
            case 'ArrowUp':
            case 'ArrowDown':
                player.input.moveY = 0;
                break;
            case 'Space':
                player.input.jump = false;
                break;
            case 'KeyZ':
                player.input.light = false;
                break;
            case 'KeyX':
                player.input.heavy = false;
                break;
            case 'KeyC':
                player.input.special = false;
                break;
            case 'KeyA':
                player.input.dodge = false;
                break;
            case 'KeyS':
                player.input.block = false;
                break;
        }
    }
    handleMouseMove(event) {
        // Mouse look or movement could be implemented here
    }
    handleMouseClick(event) {
        // Mouse click actions
    }
    createPlayer(name, isAI = false) {
        const spawnPoint = this.stage.spawnPoints[this.players.length % this.stage.spawnPoints.length];
        // Create character mesh
        const geometry = new THREE.CapsuleGeometry(0.5, 1.5, 4, 8);
        const material = new THREE.MeshLambertMaterial({
            color: isAI ? 0xff6b6b : 0x4ecdc4,
            transparent: true,
            opacity: 0.9
        });
        const mesh = new THREE.Mesh(geometry, material);
        mesh.position.copy(spawnPoint);
        mesh.castShadow = true;
        this.scene.add(mesh);
        const player = {
            id: `player_${this.players.length + 1}`,
            name,
            position: spawnPoint.clone(),
            velocity: new THREE.Vector3(0, 0, 0),
            health: 100,
            ki: 100,
            stamina: 100,
            facing: 0,
            state: 'idle',
            mesh,
            isAI,
            input: {
                moveX: 0,
                moveY: 0,
                jump: false,
                light: false,
                heavy: false,
                special: false,
                dodge: false,
                block: false,
                pause: false
            }
        };
        this.players.push(player);
        return player;
    }
    updatePlayer(player) {
        // Update position based on input
        const moveSpeed = 5;
        const jumpForce = 8;
        // Horizontal movement
        if (player.input.moveX !== 0) {
            player.velocity.x = player.input.moveX * moveSpeed;
            player.facing = player.input.moveX > 0 ? 0 : Math.PI;
        }
        else {
            player.velocity.x *= 0.8; // Friction
        }
        if (player.input.moveY !== 0) {
            player.velocity.z = player.input.moveY * moveSpeed;
        }
        else {
            player.velocity.z *= 0.8;
        }
        // Jumping
        if (player.input.jump && player.position.y <= 1.1) {
            player.velocity.y = jumpForce;
        }
        // Apply gravity
        player.velocity.y -= 20 * this.deltaTime;
        // Update position
        player.position.add(player.velocity.clone().multiplyScalar(this.deltaTime));
        // Ground collision
        if (player.position.y <= 1) {
            player.position.y = 1;
            player.velocity.y = 0;
        }
        // Update mesh position
        player.mesh.position.copy(player.position);
        player.mesh.rotation.y = player.facing;
        // Update state
        if (player.velocity.length() > 0.1) {
            player.state = 'walking';
        }
        else {
            player.state = 'idle';
        }
        // Handle attacks
        if (player.input.light) {
            this.performLightAttack(player);
        }
        if (player.input.heavy) {
            this.performHeavyAttack(player);
        }
        if (player.input.special) {
            this.performSpecialAttack(player);
        }
    }
    performLightAttack(player) {
        // Light attack logic
        console.log(`${player.name} performs light attack!`);
    }
    performHeavyAttack(player) {
        // Heavy attack logic
        console.log(`${player.name} performs heavy attack!`);
    }
    performSpecialAttack(player) {
        // Special attack logic
        console.log(`${player.name} performs special attack!`);
    }
    updateAI(player) {
        if (!player.isAI)
            return;
        // Simple AI behavior
        const target = this.players.find(p => !p.isAI);
        if (!target)
            return;
        const distance = player.position.distanceTo(target.position);
        // Move towards player
        const direction = target.position.clone().sub(player.position).normalize();
        player.input.moveX = direction.x;
        player.input.moveY = direction.z;
        // Attack when close
        if (distance < 3) {
            player.input.light = Math.random() < 0.1;
            player.input.heavy = Math.random() < 0.05;
        }
    }
    start() {
        this.isRunning = true;
        this.gameLoop();
        console.log('🎮 Anime Aggressors Game Engine started!');
    }
    stop() {
        this.isRunning = false;
    }
    handleResize() {
        const width = window.innerWidth;
        const height = window.innerHeight;
        this.camera.aspect = width / height;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(width, height);
    }
    getGameState() {
        return {
            ...this.gameState,
            players: this.players,
            isRunning: this.isRunning,
            deltaTime: this.deltaTime
        };
    }
    destroy() {
        this.stop();
        this.renderer.dispose();
        this.scene.clear();
    }
}
