import React, { useEffect, useRef, useState } from 'react';

const Lanes: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [gameState, setGameState] = useState({
    lanes: 4,
    laneWidth: 0,
    players: [
      { lane: 0, lives: 3, y: 0 },
      { lane: 2, lives: 3, y: 0 }
    ],
    bullets: [] as Array<{ x: number, y: number, vx: number, vy: number, owner: number }>,
    enemies: [] as Array<{ x: number, y: number, lane: number, vx: number }>,
    lastEnemySpawn: 0,
    gameTime: 0
  });

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d')!;
    const width = canvas.width;
    const height = canvas.height;
    
    const lanes = 4;
    const laneWidth = width / lanes;
    
    setGameState(prev => ({
      ...prev,
      lanes,
      laneWidth,
      players: [
        { lane: 0, lives: 3, y: height - 100 },
        { lane: 2, lives: 3, y: height - 100 }
      ]
    }));

    const update = (dt: number) => {
      setGameState(prev => {
        const newGameTime = prev.gameTime + dt;
        
        // Spawn enemies
        let newEnemies = [...prev.enemies];
        if (newGameTime - prev.lastEnemySpawn > 2) {
          const lane = Math.floor(Math.random() * prev.lanes);
          newEnemies.push({
            x: lane * prev.laneWidth + prev.laneWidth / 2,
            y: -50,
            lane: lane,
            vx: 0
          });
        }
        
        // Update bullets
        const newBullets = prev.bullets
          .map(bullet => ({
            ...bullet,
            x: bullet.x + bullet.vx * dt,
            y: bullet.y + bullet.vy * dt
          }))
          .filter(bullet => bullet.x >= 0 && bullet.x <= width && bullet.y >= 0 && bullet.y <= height);
        
        // Update enemies
        const updatedEnemies = newEnemies
          .map(enemy => ({
            ...enemy,
            y: enemy.y + 100 * dt
          }))
          .filter(enemy => enemy.y <= height);
        
        // Check collisions
        const finalBullets = [...newBullets];
        const finalEnemies = [...updatedEnemies];
        
        finalBullets.forEach((bullet, bulletIndex) => {
          finalEnemies.forEach((enemy, enemyIndex) => {
            if (Math.abs(bullet.x - enemy.x) < 30 && Math.abs(bullet.y - enemy.y) < 30) {
              finalBullets.splice(bulletIndex, 1);
              finalEnemies.splice(enemyIndex, 1);
            }
          });
        });
        
        // Check player collisions with enemies
        const newPlayers = [...prev.players];
        finalEnemies.forEach((enemy, enemyIndex) => {
          newPlayers.forEach(player => {
            if (enemy.lane === player.lane && Math.abs(enemy.y - player.y) < 50) {
              player.lives--;
              finalEnemies.splice(enemyIndex, 1);
            }
          });
        });
        
        return {
          ...prev,
          gameTime: newGameTime,
          lastEnemySpawn: newGameTime - prev.lastEnemySpawn > 2 ? newGameTime : prev.lastEnemySpawn,
          bullets: finalBullets,
          enemies: finalEnemies,
          players: newPlayers
        };
      });
    };

    const render = () => {
      const state = gameState;
      
      // Clear canvas
      ctx.fillStyle = '#000';
      ctx.fillRect(0, 0, width, height);
      
      // Draw lanes
      ctx.strokeStyle = '#333';
      ctx.lineWidth = 2;
      for (let i = 1; i < state.lanes; i++) {
        ctx.beginPath();
        ctx.moveTo(i * state.laneWidth, 0);
        ctx.lineTo(i * state.laneWidth, height);
        ctx.stroke();
      }
      
      // Draw players
      state.players.forEach((player, i) => {
        ctx.fillStyle = i === 0 ? '#FF6B6B' : '#4ECDC4';
        ctx.fillRect(
          player.lane * state.laneWidth + 20,
          player.y - 20,
          40,
          40
        );
        
        // Draw lives
        ctx.fillStyle = '#FFF';
        ctx.font = '16px Arial';
        ctx.fillText(`P${i + 1}: ${player.lives}`, 20, 30 + i * 20);
      });
      
      // Draw bullets
      ctx.fillStyle = '#FFD700';
      state.bullets.forEach(bullet => {
        ctx.fillRect(bullet.x - 2, bullet.y - 2, 4, 4);
      });
      
      // Draw enemies
      ctx.fillStyle = '#FF0000';
      state.enemies.forEach(enemy => {
        ctx.fillRect(enemy.x - 15, enemy.y - 15, 30, 30);
      });
      
      // Game over check
      const alivePlayers = state.players.filter(p => p.lives > 0);
      if (alivePlayers.length === 0) {
        ctx.fillStyle = '#FFF';
        ctx.font = '30px Arial';
        ctx.fillText('GAME OVER', width / 2 - 100, height / 2);
      }
    };

    const gameLoop = () => {
      update(1/60);
      render();
      requestAnimationFrame(gameLoop);
    };

    // Keyboard controls
    const handleKeyDown = (e: KeyboardEvent) => {
      setGameState(prev => {
        const newPlayers = [...prev.players];
        
        // Player 1 movement (WASD)
        if (e.key === 'a' && newPlayers[0].lane > 0) newPlayers[0].lane--;
        if (e.key === 'd' && newPlayers[0].lane < prev.lanes - 1) newPlayers[0].lane++;
        
        // Player 2 movement (Arrow keys)
        if (e.key === 'ArrowLeft' && newPlayers[1].lane > 0) newPlayers[1].lane--;
        if (e.key === 'ArrowRight' && newPlayers[1].lane < prev.lanes - 1) newPlayers[1].lane++;
        
        // Shooting
        if (e.key === ' ') { // Space for P1
          const newBullets = [...prev.bullets];
          newBullets.push({
            x: newPlayers[0].lane * prev.laneWidth + prev.laneWidth / 2,
            y: newPlayers[0].y - 20,
            vx: 0,
            vy: -200,
            owner: 0
          });
          return { ...prev, players: newPlayers, bullets: newBullets };
        }
        if (e.key === 'Enter') { // Enter for P2
          const newBullets = [...prev.bullets];
          newBullets.push({
            x: newPlayers[1].lane * prev.laneWidth + prev.laneWidth / 2,
            y: newPlayers[1].y - 20,
            vx: 0,
            vy: -200,
            owner: 1
          });
          return { ...prev, players: newPlayers, bullets: newBullets };
        }
        
        return { ...prev, players: newPlayers };
      });
    };

    document.addEventListener('keydown', handleKeyDown);

    gameLoop();

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [gameState]);

  return (
    <div style={{ textAlign: 'center' }}>
      <h3 style={{ color: 'white', marginBottom: '1rem' }}>🚀 4-Lane Blaster</h3>
      <canvas 
        ref={canvasRef}
        width={960}
        height={540}
        style={{ border: '2px solid rgba(255,255,255,0.3)', borderRadius: '10px', background: '#000' }}
      />
      <p style={{ color: '#ccc', marginTop: '1rem', fontSize: '0.9rem' }}>
        P1: A/D to move, SPACE to shoot. P2: Arrow keys to move, ENTER to shoot. 3 lives each!
      </p>
    </div>
  );
};

export default Lanes;