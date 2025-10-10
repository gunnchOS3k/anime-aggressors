import React, { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import MiniGames from '../components/MiniGames';

const Play: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [loading, setLoading] = useState(true);
  const [progress, setProgress] = useState(0);
  const [showMiniGames, setShowMiniGames] = useState(true);
  const sceneRef = useRef<THREE.Scene | null>(null);
  const rendererRef = useRef<THREE.WebGLRenderer | null>(null);
  const cameraRef = useRef<THREE.PerspectiveCamera | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    // Initialize Three.js scene
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, canvas.width / canvas.height, 0.1, 1000);
    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
    
    sceneRef.current = scene;
    rendererRef.current = renderer;
    cameraRef.current = camera;

    // Set up basic scene
    scene.background = new THREE.Color(0x222222);
    
    // Add lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
    scene.add(ambientLight);
    
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(5, 10, 7);
    scene.add(directionalLight);

    // Add a simple arena
    const arenaGeometry = new THREE.BoxGeometry(20, 1, 20);
    const arenaMaterial = new THREE.MeshStandardMaterial({ color: 0x444444 });
    const arena = new THREE.Mesh(arenaGeometry, arenaMaterial);
    arena.position.y = -0.5;
    scene.add(arena);

    // Add walls
    const wallGeometry = new THREE.BoxGeometry(1, 5, 20);
    const wallMaterial = new THREE.MeshStandardMaterial({ color: 0x666666 });
    
    const leftWall = new THREE.Mesh(wallGeometry, wallMaterial);
    leftWall.position.set(-10, 2, 0);
    scene.add(leftWall);
    
    const rightWall = new THREE.Mesh(wallGeometry, wallMaterial);
    rightWall.position.set(10, 2, 0);
    scene.add(rightWall);

    // Add simple characters
    const playerGeometry = new THREE.CapsuleGeometry(0.5, 2, 4, 8);
    const playerMaterial = new THREE.MeshStandardMaterial({ color: 0x4ecdc4 });
    const player = new THREE.Mesh(playerGeometry, playerMaterial);
    player.position.set(-5, 1, 0);
    scene.add(player);

    const enemyGeometry = new THREE.CapsuleGeometry(0.5, 2, 4, 8);
    const enemyMaterial = new THREE.MeshStandardMaterial({ color: 0xff6b6b });
    const enemy = new THREE.Mesh(enemyGeometry, enemyMaterial);
    enemy.position.set(5, 1, 0);
    scene.add(enemy);

    // Position camera
    camera.position.set(0, 10, 15);
    camera.lookAt(0, 0, 0);

    // Simulate loading with progress
    const loadingManager = new THREE.LoadingManager();
    loadingManager.onProgress = (url, itemsLoaded, itemsTotal) => {
      const progress = (itemsLoaded / itemsTotal) * 100;
      setProgress(Math.round(progress));
    };

    loadingManager.onLoad = () => {
      // Ensure minimum loading time for mini-games
      setTimeout(() => {
        setLoading(false);
        setShowMiniGames(false);
      }, 3000);
    };

    // Simulate asset loading
    setTimeout(() => {
      loadingManager.onLoad?.();
    }, 2000);

    // Animation loop
    const animate = () => {
      requestAnimationFrame(animate);
      
      // Rotate characters
      player.rotation.y += 0.01;
      enemy.rotation.y -= 0.01;
      
      renderer.render(scene, camera);
    };
    animate();

    // Handle window resize
    const handleResize = () => {
      const width = window.innerWidth;
      const height = window.innerHeight;
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
      renderer.setSize(width, height);
    };
    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      if (renderer) {
        renderer.dispose();
      }
    };
  }, []);

  return (
    <div style={{ position: 'relative', width: '100vw', height: '100vh', background: '#000' }}>
      <canvas 
        ref={canvasRef}
        style={{ width: '100%', height: '100%', display: loading ? 'none' : 'block' }}
      />
      
      {loading && (
        <div style={{
          position: 'absolute',
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          color: 'white'
        }}>
          <h2 style={{ marginBottom: '2rem' }}>🥊 Loading Arena...</h2>
          <div style={{
            width: '400px',
            height: '20px',
            background: 'rgba(255,255,255,0.2)',
            borderRadius: '10px',
            overflow: 'hidden',
            marginBottom: '2rem'
          }}>
            <div style={{
              width: `${progress}%`,
              height: '100%',
              background: 'linear-gradient(90deg, #4ecdc4, #44a08d)',
              transition: 'width 0.3s ease'
            }} />
          </div>
          <p style={{ marginBottom: '2rem' }}>{progress}% - Loading assets...</p>
          
          {showMiniGames && (
            <div style={{ 
              background: 'rgba(0,0,0,0.8)', 
              padding: '2rem', 
              borderRadius: '15px',
              maxWidth: '800px',
              width: '90%'
            }}>
              <h3 style={{ marginBottom: '1rem' }}>🎮 Play Mini-Games While Loading</h3>
              <MiniGames onClose={() => setShowMiniGames(false)} />
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default Play;
