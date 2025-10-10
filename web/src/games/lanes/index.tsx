import React, { useEffect, useRef } from 'react';
import { startPolling, stopPolling, PadState } from '../../gamepad';

const Lanes: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const gameStateRef = useRef({
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
    
    const state = gameStateRef.current;
    state.laneWidth = width / state.lanes;
    state.players[0].y = height - 100;
    state.players[1].y = height - 100;

    const update = (dt: number) => {
      state.gameTime += dt;
      
      // Spawn enemies
      if (state.gameTime - state.lastEnemySpawn > 2) {
        const lane = Math.floor(Math.random() * state.lanes);
        state.enemies.push({
          x: lane * state.laneWidth + state.laneWidth / 2,
          y: -50,
          lane: lane,
          vx: 0
        });
        state.lastEnemySpawn = state.gameTime;
      }
      
      // Update bullets
      state.bullets = state.bullets.filter(bullet => {
        bullet.x += bullet.vx * dt;
        bullet.y += bullet.vy * dt;
        
        if (bullet.x < 0 || bullet.x > width || bullet.y < 0 || bullet.y > height) {
          return false;
        }
        return true;
      });
      
      // Update enemies
      state.enemies = state.enemies.filter(enemy => {
        enemy.y += 100 * dt;
        
        if (enemy.y > height) {
          return false;
        }
        return true;
      });
      
      // Check collisions
      state.bullets.forEach((bullet, bulletIndex) => {
        state.enemies.forEach((enemy, enemyIndex) => {
          if (Math.abs(bullet.x - enemy.x) < 30 && Math.abs(bullet.y - enemy.y) < 30) {
            state.bullets.splice(bulletIndex, 1);
            state.enemies.splice(enemyIndex, 1);
          }
        });
      });
      
      // Check player collisions with enemies
      state.players.forEach(player => {
        state.enemies.forEach((enemy, enemyIndex) => {
          if (enemy.lane === player.lane && Math.abs(enemy.y - player.y) < 50) {
            player.lives--;
            state.enemies.splice(enemyIndex, 1);
          }
        });
      });
    };

    const render = () => {
      const state = gameStateRef.current;
      
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
        ctx.fillText(`Lives: ${player.lives}`, 20, 30 + i * 20);
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

    // Start gamepad tracking
    startPolling((pads: PadState[]) => {
      const p1 = pads[0];
      const p2 = pads[1] || pads[0]; // Fallback to same pad for single player
      
      if (!p1) return;
      
      const state = gameStateRef.current;
      
      // Player 1 movement
      if (p1.axes[0] < -0.5 && state.players[0].lane > 0) state.players[0].lane--;
      if (p1.axes[0] > 0.5 && state.players[0].lane < state.lanes - 1) state.players[0].lane++;
      
      // Player 2 movement
      if (p2 && p2 !== p1) {
        if (p2.axes[0] < -0.5 && state.players[1].lane > 0) state.players[1].lane--;
        if (p2.axes[0] > 0.5 && state.players[1].lane < state.lanes - 1) state.players[1].lane++;
      }
      
      // Shooting
      if (p1.buttons.A || p1.buttons.Cross) {
        state.bullets.push({
          x: state.players[0].lane * state.laneWidth + state.laneWidth / 2,
          y: state.players[0].y - 20,
          vx: 0,
          vy: -200,
          owner: 0
        });
      }
      
      if (p2 && (p2.buttons.A || p2.buttons.Cross)) {
        state.bullets.push({
          x: state.players[1].lane * state.laneWidth + state.laneWidth / 2,
          y: state.players[1].y - 20,
          vx: 0,
          vy: -200,
          owner: 1
        });
      }
    });

    gameLoop();

    return () => {
      stopPolling();
    };
  }, []);

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
        Move between lanes with stick, shoot with A/Cross. 3 lives each!
      </p>
    </div>
  );
};

export default Lanes;
