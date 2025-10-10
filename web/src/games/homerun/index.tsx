import React, { useEffect, useRef } from 'react';
import { startPolling, stopPolling, PadState } from '../../gamepad';

const HomeRun: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const gameStateRef = useRef({
    state: 'waiting', // waiting, charging, releasing, flying, landed
    charge: 0,
    maxCharge: 100,
    targetZone: { start: 0.7, end: 0.9 },
    ball: { x: 50, y: 0, vx: 0, vy: 0, size: 20 },
    score: 0,
    power: 0
  });

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d')!;
    const width = canvas.width;
    const height = canvas.height;
    
    // Initialize ball position
    gameStateRef.current.ball.y = height - 100;

    const update = (dt: number) => {
      const state = gameStateRef.current;
      
      if (state.state === 'charging') {
        state.charge += 60 * dt;
        if (state.charge >= state.maxCharge) {
          state.charge = state.maxCharge;
          state.state = 'releasing';
        }
      } else if (state.state === 'releasing') {
        const accuracy = state.charge / state.maxCharge;
        if (accuracy >= state.targetZone.start && accuracy <= state.targetZone.end) {
          state.power = accuracy * 100;
          state.state = 'flying';
          state.ball.vx = state.power * 0.5;
          state.ball.vy = -state.power * 0.3;
        } else {
          state.power = accuracy * 50;
          state.state = 'flying';
          state.ball.vx = state.power * 0.3;
          state.ball.vy = -state.power * 0.2;
        }
      } else if (state.state === 'flying') {
        state.ball.x += state.ball.vx * dt;
        state.ball.y += state.ball.vy * dt;
        state.ball.vy += 200 * dt; // Gravity
        
        if (state.ball.y > height - 50) {
          state.ball.y = height - 50;
          state.state = 'landed';
          state.score = Math.floor(state.ball.x / 10);
        }
      }
    };

    const render = () => {
      const state = gameStateRef.current;
      
      // Clear canvas
      ctx.fillStyle = '#87CEEB';
      ctx.fillRect(0, 0, width, height);
      
      // Draw ground
      ctx.fillStyle = '#8B4513';
      ctx.fillRect(0, height - 50, width, 50);
      
      // Draw ball
      ctx.fillStyle = '#FFD700';
      ctx.beginPath();
      ctx.arc(state.ball.x, state.ball.y, state.ball.size, 0, Math.PI * 2);
      ctx.fill();
      
      // Draw UI
      ctx.fillStyle = '#000';
      ctx.font = '20px Arial';
      ctx.fillText(`Score: ${state.score}`, 20, 30);
      
      if (state.state === 'waiting') {
        ctx.fillText('Press any button to start charging!', 20, 60);
      } else if (state.state === 'charging') {
        // Draw charge bar
        ctx.fillStyle = '#FF0000';
        ctx.fillRect(20, 60, state.charge * 2, 20);
        ctx.fillStyle = '#000';
        ctx.fillText(`Charge: ${Math.floor(state.charge)}%`, 20, 80);
        
        // Draw target zone
        ctx.fillStyle = '#00FF00';
        ctx.fillRect(20 + state.targetZone.start * 200, 60, (state.targetZone.end - state.targetZone.start) * 200, 20);
      } else if (state.state === 'flying') {
        ctx.fillText(`Power: ${Math.floor(state.power)}%`, 20, 60);
      } else if (state.state === 'landed') {
        ctx.fillText(`Final Score: ${state.score}`, 20, 60);
        ctx.fillText('Press any button to restart', 20, 90);
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
      if (!p1) return;
      
      const state = gameStateRef.current;
      
      // Check for button press to start/restart
      if (p1.buttons.A || p1.buttons.Cross) {
        if (state.state === 'waiting' || state.state === 'landed') {
          if (state.state === 'landed') {
            // Reset game
            state.state = 'waiting';
            state.charge = 0;
            state.ball = { x: 50, y: height - 100, vx: 0, vy: 0, size: 20 };
            state.score = 0;
            state.power = 0;
          } else {
            state.state = 'charging';
          }
        }
      }
      
      // Check for button release during charging
      if (state.state === 'charging' && !p1.buttons.A && !p1.buttons.Cross) {
        state.state = 'releasing';
      }
    });

    gameLoop();

    return () => {
      stopPolling();
    };
  }, []);

  return (
    <div style={{ textAlign: 'center' }}>
      <h3 style={{ color: 'white', marginBottom: '1rem' }}>🏏 Home-Run Sandbag</h3>
      <canvas 
        ref={canvasRef}
        width={960}
        height={540}
        style={{ border: '2px solid rgba(255,255,255,0.3)', borderRadius: '10px', background: '#000' }}
      />
      <p style={{ color: '#ccc', marginTop: '1rem', fontSize: '0.9rem' }}>
        Charge with A/Cross, release in the green zone for max power!
      </p>
    </div>
  );
};

export default HomeRun;
