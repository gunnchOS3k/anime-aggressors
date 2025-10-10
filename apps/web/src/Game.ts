import { GameEngine } from './GameEngine.js';

export class Game {
  private canvas: HTMLCanvasElement;
  private gameEngine: GameEngine;
  private isInitialized = false;

  constructor() {
    this.canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
    if (!this.canvas) {
      throw new Error('Game canvas not found');
    }

    this.gameEngine = new GameEngine(this.canvas);
  }

  async init(): Promise<void> {
    try {
      // Create players
      this.gameEngine.createPlayer('Player 1', false);
      this.gameEngine.createPlayer('AI Opponent', true);
      
      // Start the game engine
      this.gameEngine.start();
      
      this.isInitialized = true;
      console.log('🎮 Anime Aggressors initialized with full game engine!');
      this.showToast('🥊 Game loaded! Arrow keys to move, Z/X/C to attack, Space to jump!');
    } catch (error) {
      console.error('Failed to initialize game:', error);
    }
  }

  handleResize(): void {
    this.gameEngine.handleResize();
  }

  private showToast(message: string): void {
    // Simple toast notification
    const toast = document.createElement('div');
    toast.textContent = message;
    toast.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      z-index: 1000;
      font-family: monospace;
      font-size: 14px;
      border: 1px solid #4ecdc4;
    `;
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
      if (document.body.contains(toast)) {
        document.body.removeChild(toast);
      }
    }, 5000);
  }

  destroy(): void {
    this.gameEngine.destroy();
  }
}
