import React, { lazy, Suspense, useState } from 'react';

// Lazy load mini-games
const HomeRun = lazy(() => import('../games/homerun'));
const Paint = lazy(() => import('../games/paint'));
const Lanes = lazy(() => import('../games/lanes'));

interface MiniGamesProps {
  onClose: () => void;
}

const MiniGames: React.FC<MiniGamesProps> = ({ onClose }) => {
  const [selectedGame, setSelectedGame] = useState<string | null>(null);

  const games = [
    { id: 'homerun', name: '🏏 Home-Run Sandbag', component: HomeRun },
    { id: 'paint', name: '🎨 Paint the Floor', component: Paint },
    { id: 'lanes', name: '🚀 4-Lane Blaster', component: Lanes }
  ];

  if (selectedGame) {
    const game = games.find(g => g.id === selectedGame);
    if (game) {
      return (
        <div style={{ textAlign: 'center' }}>
          <button 
            onClick={() => setSelectedGame(null)}
            style={{
              background: '#ff6b6b',
              color: 'white',
              border: 'none',
              padding: '0.5rem 1rem',
              borderRadius: '5px',
              cursor: 'pointer',
              marginBottom: '1rem'
            }}
          >
            ← Back to Menu
          </button>
          <div style={{ border: '2px solid rgba(255,255,255,0.3)', borderRadius: '10px', background: '#000' }}>
            <Suspense fallback={<div style={{ color: 'white', padding: '2rem' }}>Loading game...</div>}>
              <game.component />
            </Suspense>
          </div>
        </div>
      );
    }
  }

  return (
    <div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '1rem' }}>
        {games.map(game => (
          <button
            key={game.id}
            onClick={() => setSelectedGame(game.id)}
            style={{
              background: 'rgba(255, 255, 255, 0.2)',
              color: 'white',
              border: '1px solid rgba(255, 255, 255, 0.3)',
              padding: '1rem',
              borderRadius: '10px',
              cursor: 'pointer',
              transition: 'all 0.3s ease',
              fontSize: '1rem'
            }}
            onMouseOver={(e) => {
              e.currentTarget.style.background = 'rgba(255, 255, 255, 0.3)';
              e.currentTarget.style.transform = 'translateY(-2px)';
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.background = 'rgba(255, 255, 255, 0.2)';
              e.currentTarget.style.transform = 'translateY(0)';
            }}
          >
            {game.name}
          </button>
        ))}
      </div>
      
      <p style={{ color: '#ccc', fontSize: '0.9rem', marginTop: '1rem' }}>
        Plug 2 controllers or share 1. Keyboard works too.
      </p>
      
      <button 
        onClick={onClose}
        style={{
          background: 'rgba(255, 255, 255, 0.1)',
          color: 'white',
          border: '1px solid rgba(255, 255, 255, 0.3)',
          padding: '0.5rem 1rem',
          borderRadius: '5px',
          cursor: 'pointer',
          marginTop: '1rem'
        }}
      >
        Close Mini-Games
      </button>
    </div>
  );
};

export default MiniGames;
