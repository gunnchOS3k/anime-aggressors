import React, { useEffect, useRef, useState } from 'react';

const HomeRun: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [gameState, setGameState] = useState({
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
    setGameState(prev => ({ ...prev, ball: { ...prev.ball, y: height - 100 } }));

    const update = (dt: number) => {
      setGameState(prev => {
        if (prev.state === 'charging') {
          const newCharge = Math.min(prev.charge + 60 * dt, prev.maxCharge);
          if (newCharge >= prev.maxCharge) {
            return { ...prev, charge: prev.maxCharge, state: 'releasing' };
          }
          return { ...prev, charge: newCharge };
        } else if (prev.state === 'releasing') {
          const accuracy = prev.charge / prev.maxCharge;
          if (accuracy >= prev.targetZone.start && accuracy <= prev.targetZone.end) {
            const power = accuracy * 100;
            return {
              ...prev,
              power,
              state: 'flying',
              ball: { ...prev.ball, vx: power * 0.5, vy: -power * 0.3 }
            };
          } else {
            const power = accuracy * 50;
            return {
              ...prev,
              power,
              state: 'flying',
              ball: { ...prev.ball, vx: power * 0.3, vy: -power * 0.2 }
            };
          }
        } else if (prev.state === 'flying') {
          const newBall = {
            x: prev.ball.x + prev.ball.vx * dt,
            y: prev.ball.y + prev.ball.vy * dt,
            vx: prev.ball.vx,
            vy: prev.ball.vy + 200 * dt, // Gravity
            size: prev.ball.size
          };
          
          if (newBall.y > height - 50) {
            newBall.y = height - 50;
            return {
              ...prev,
              ball: newBall,
              state: 'landed',
              score: Math.floor(newBall.x / 10)
            };
          }
          return { ...prev, ball: newBall };
        }
        return prev;
      });
    };

    const render = () => {
      const state = gameState;
      
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
        ctx.fillText('Press SPACE to start charging!', 20, 60);
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
        ctx.fillText('Press SPACE to restart', 20, 90);
      }
    };

    const gameLoop = () => {
      update(1/60);
      render();
      requestAnimationFrame(gameLoop);
    };

    // Keyboard controls
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.code === 'Space') {
        e.preventDefault();
        setGameState(prev => {
          if (prev.state === 'waiting' || prev.state === 'landed') {
            if (prev.state === 'landed') {
              // Reset game
              return {
                state: 'waiting',
                charge: 0,
                ball: { x: 50, y: height - 100, vx: 0, vy: 0, size: 20 },
                score: 0,
                power: 0,
                maxCharge: 100,
                targetZone: { start: 0.7, end: 0.9 }
              };
            } else {
              return { ...prev, state: 'charging' };
            }
          }
          return prev;
        });
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      if (e.code === 'Space') {
        e.preventDefault();
        setGameState(prev => {
          if (prev.state === 'charging') {
            return { ...prev, state: 'releasing' };
          }
          return prev;
        });
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    document.addEventListener('keyup', handleKeyUp);

    gameLoop();

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.removeEventListener('keyup', handleKeyUp);
    };
  }, [gameState]);

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
        Hold SPACE to charge, release in the green zone for max power!
      </p>
    </div>
  );
};

export default HomeRun;