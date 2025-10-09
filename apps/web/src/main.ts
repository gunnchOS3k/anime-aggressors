import './style.css';
import { Game } from './Game.js';

// Initialize the game
const game = new Game();
game.init();

// Handle window events
window.addEventListener('resize', () => {
  game.handleResize();
});

window.addEventListener('beforeunload', () => {
  game.destroy();
});

// Export for debugging
(window as any).game = game;
