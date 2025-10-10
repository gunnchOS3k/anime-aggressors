import React, { useEffect, useRef } from 'react';
import { startPolling, stopPolling, PadState } from '../../gamepad';

const Paint: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const gameStateRef = useRef({
    grid: [] as number[][],
    players: [
      { x: 1, y: 1, color: 1, score: 0 },
      { x: 0, y: 0, color: 2, score: 0 }
    ],
    gameTime: 60,
    gameStart: Date.now(),
    gridSize: 20,
    cols: 0,
    rows: 0
  });

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d')!;
    const width = canvas.width;
    const height = canvas.height;
    
    const state = gameStateRef.current;
    state.gridSize = 20;
    state.cols = Math.floor(width / state.gridSize);
    state.rows = Math.floor(height / state.gridSize);
    state.grid = Array(state.rows).fill(null).map(() => Array(state.cols).fill(0));
    state.players[1].x = state.cols - 2;
    state.players[1].y = state.rows - 2;

    const update = (dt: number) => {
      const elapsed = (Date.now() - state.gameStart) / 1000;
      state.gameTime = Math.max(0, 60 - elapsed);
      
      if (state.gameTime <= 0) return;
      
      // Update player scores
      state.players.forEach(player => {
        player.score = 0;
        for (let y = 0; y < state.rows; y++) {
          for (let x = 0; x < state.cols; x++) {
            if (state.grid[y][x] === player.color) {
              player.score++;
            }
          }
        }
      });
    };

    const render = () => {
      const state = gameStateRef.current;
      
      // Clear canvas
      ctx.fillStyle = '#F0F0F0';
      ctx.fillRect(0, 0, width, height);
      
      // Draw grid
      for (let y = 0; y < state.rows; y++) {
        for (let x = 0; x < state.cols; x++) {
          if (state.grid[y][x] === 1) {
            ctx.fillStyle = '#FF6B6B';
          } else if (state.grid[y][x] === 2) {
            ctx.fillStyle = '#4ECDC4';
          } else {
            ctx.fillStyle = '#FFFFFF';
          }
          
          ctx.fillRect(x * state.gridSize, y * state.gridSize, state.gridSize - 1, state.gridSize - 1);
        }
      }
      
      // Draw players
      state.players.forEach((player, i) => {
        ctx.fillStyle = i === 0 ? '#FF6B6B' : '#4ECDC4';
        ctx.fillRect(
          player.x * state.gridSize + 2,
          player.y * state.gridSize + 2,
          state.gridSize - 4,
          state.gridSize - 4
        );
      });
      
      // Draw UI
      ctx.fillStyle = '#000';
      ctx.font = '20px Arial';
      ctx.fillText(`Time: ${Math.floor(state.gameTime)}s`, 20, 30);
      ctx.fillText(`P1: ${state.players[0].score}`, 20, 60);
      ctx.fillText(`P2: ${state.players[1].score}`, 20, 90);
      
      if (state.gameTime <= 0) {
        const winner = state.players[0].score > state.players[1].score ? 'Player 1' : 
                      state.players[1].score > state.players[0].score ? 'Player 2' : 'Tie';
        ctx.fillText(`Winner: ${winner}`, width / 2 - 100, height / 2);
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
      if (p1.axes[0] < -0.5 && state.players[0].x > 0) state.players[0].x--;
      if (p1.axes[0] > 0.5 && state.players[0].x < state.cols - 1) state.players[0].x++;
      if (p1.axes[1] < -0.5 && state.players[0].y > 0) state.players[0].y--;
      if (p1.axes[1] > 0.5 && state.players[0].y < state.rows - 1) state.players[0].y++;
      
      // Player 2 movement
      if (p2 && p2 !== p1) {
        if (p2.axes[0] < -0.5 && state.players[1].x > 0) state.players[1].x--;
        if (p2.axes[0] > 0.5 && state.players[1].x < state.cols - 1) state.players[1].x++;
        if (p2.axes[1] < -0.5 && state.players[1].y > 0) state.players[1].y--;
        if (p2.axes[1] > 0.5 && state.players[1].y < state.rows - 1) state.players[1].y++;
      }
      
      // Paint tiles
      if (p1.buttons.A || p1.buttons.Cross) {
        state.grid[state.players[0].y][state.players[0].x] = 1;
      }
      if (p2 && (p2.buttons.A || p2.buttons.Cross)) {
        state.grid[state.players[1].y][state.players[1].x] = 2;
      }
    });

    gameLoop();

    return () => {
      stopPolling();
    };
  }, []);

  return (
    <div style={{ textAlign: 'center' }}>
      <h3 style={{ color: 'white', marginBottom: '1rem' }}>🎨 Paint the Floor</h3>
      <canvas 
        ref={canvasRef}
        width={960}
        height={540}
        style={{ border: '2px solid rgba(255,255,255,0.3)', borderRadius: '10px', background: '#000' }}
      />
      <p style={{ color: '#ccc', marginTop: '1rem', fontSize: '0.9rem' }}>
        Move with stick, paint with A/Cross. Most tiles in 60 seconds wins!
      </p>
    </div>
  );
};

export default Paint;
