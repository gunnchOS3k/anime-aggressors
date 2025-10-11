import React, { useEffect, useRef, useState } from 'react';

const Paint: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [gameState, setGameState] = useState({
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
    
    const gridSize = 20;
    const cols = Math.floor(width / gridSize);
    const rows = Math.floor(height / gridSize);
    const grid = Array(rows).fill(null).map(() => Array(cols).fill(0));
    
    setGameState(prev => ({
      ...prev,
      grid,
      cols,
      rows,
      players: [
        { x: 1, y: 1, color: 1, score: 0 },
        { x: cols - 2, y: rows - 2, color: 2, score: 0 }
      ]
    }));

    const update = (dt: number) => {
      setGameState(prev => {
        const elapsed = (Date.now() - prev.gameStart) / 1000;
        const newGameTime = Math.max(0, 60 - elapsed);
        
        // Update player scores
        const newPlayers = prev.players.map(player => {
          let score = 0;
          for (let y = 0; y < prev.rows; y++) {
            for (let x = 0; x < prev.cols; x++) {
              if (prev.grid[y][x] === player.color) {
                score++;
              }
            }
          }
          return { ...player, score };
        });
        
        return { ...prev, gameTime: newGameTime, players: newPlayers };
      });
    };

    const render = () => {
      const state = gameState;
      
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
        
        // Draw lives
        ctx.fillStyle = '#FFF';
        ctx.font = '16px Arial';
        ctx.fillText(`P${i + 1}: ${player.score}`, 20, 30 + i * 20);
      });
      
      // Draw UI
      ctx.fillStyle = '#000';
      ctx.font = '20px Arial';
      ctx.fillText(`Time: ${Math.floor(state.gameTime)}s`, 20, 30);
      
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

    // Keyboard controls
    const handleKeyDown = (e: KeyboardEvent) => {
      setGameState(prev => {
        const newPlayers = [...prev.players];
        
        // Player 1 (WASD)
        if (e.key === 'w' && newPlayers[0].y > 0) newPlayers[0].y--;
        if (e.key === 's' && newPlayers[0].y < prev.rows - 1) newPlayers[0].y++;
        if (e.key === 'a' && newPlayers[0].x > 0) newPlayers[0].x--;
        if (e.key === 'd' && newPlayers[0].x < prev.cols - 1) newPlayers[0].x++;
        
        // Player 2 (Arrow keys)
        if (e.key === 'ArrowUp' && newPlayers[1].y > 0) newPlayers[1].y--;
        if (e.key === 'ArrowDown' && newPlayers[1].y < prev.rows - 1) newPlayers[1].y++;
        if (e.key === 'ArrowLeft' && newPlayers[1].x > 0) newPlayers[1].x--;
        if (e.key === 'ArrowRight' && newPlayers[1].x < prev.cols - 1) newPlayers[1].x++;
        
        // Paint tiles
        if (e.key === ' ') { // Space for P1
          const newGrid = [...prev.grid];
          newGrid[newPlayers[0].y][newPlayers[0].x] = 1;
          return { ...prev, players: newPlayers, grid: newGrid };
        }
        if (e.key === 'Enter') { // Enter for P2
          const newGrid = [...prev.grid];
          newGrid[newPlayers[1].y][newPlayers[1].x] = 2;
          return { ...prev, players: newPlayers, grid: newGrid };
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
      <h3 style={{ color: 'white', marginBottom: '1rem' }}>🎨 Paint the Floor</h3>
      <canvas 
        ref={canvasRef}
        width={960}
        height={540}
        style={{ border: '2px solid rgba(255,255,255,0.3)', borderRadius: '10px', background: '#000' }}
      />
      <p style={{ color: '#ccc', marginTop: '1rem', fontSize: '0.9rem' }}>
        P1: WASD to move, SPACE to paint. P2: Arrow keys to move, ENTER to paint. Most tiles in 60 seconds wins!
      </p>
    </div>
  );
};

export default Paint;