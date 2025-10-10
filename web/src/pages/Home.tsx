import React, { useState } from 'react';
import MiniGames from '../components/MiniGames';

const Home: React.FC = () => {
  const [showMiniGames, setShowMiniGames] = useState(false);

  return (
    <div>
      {/* Hero Section */}
      <section className="hero">
        <h1>🥊 Anime Aggressors</h1>
        <p>Shōnen-style PvP Arena Brawler with Edge-IO Integration</p>
      </section>

      {/* Feature Cards */}
      <section className="cards">
        <article className="card">
          <h2>⚡ Fast PvP Arena</h2>
          <p>Punk-retro 1v1 with bots. Ultra-snappy controls with sub-50ms latency rollback netcode.</p>
        </article>
        
        <article className="card">
          <h2>🎮 Edge IO Ready</h2>
          <p>Hands / voice optional inputs when enabled. Gesture-driven combat with haptic feedback.</p>
        </article>
        
        <article className="card">
          <h2>🌐 Cross-Platform</h2>
          <p>Web, mobile, and desktop with unified rollback netcode and cross-play support.</p>
        </article>
      </section>

      {/* Mini-games Demo */}
      <section className="demo">
        <h3>🎮 Play the Demo</h3>
        {!showMiniGames ? (
          <button 
            className="load-demo" 
            onClick={() => setShowMiniGames(true)}
          >
            Load Mini-Games
          </button>
        ) : (
          <MiniGames onClose={() => setShowMiniGames(false)} />
        )}
      </section>

      {/* Start Match Button */}
      <section className="demo">
        <h3>🥊 Ready for the Arena?</h3>
        <button 
          className="start-match"
          onClick={() => window.location.href = '/play'}
        >
          Start Match
        </button>
        <p style={{ marginTop: '1rem', fontSize: '0.9rem', color: '#ccc' }}>
          Full 3D arena with loading mini-games
        </p>
      </section>

      <footer className="footer">
        <a href="https://github.com/gunnchOS3k/anime-aggressors" target="_blank" rel="noopener noreferrer">GitHub</a>
        <a href="https://discord.gg/anime-aggressors" target="_blank" rel="noopener noreferrer">Discord</a>
        <a href="https://twitter.com/gunnchOS3k" target="_blank" rel="noopener noreferrer">Twitter</a>
      </footer>
    </div>
  );
};

export default Home;
