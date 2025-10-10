import { SimpleGame } from './SimpleGame.js';

export class Game {
  private canvas: HTMLCanvasElement;
  private simpleGame: SimpleGame;
  private isInitialized = false;

  constructor() {
    this.canvas = document.getElementById('game-canvas') as HTMLCanvasElement;
    if (!this.canvas) {
      throw new Error('Game canvas not found');
    }

    this.simpleGame = new SimpleGame();
  }

  async init(): Promise<void> {
    try {
      // Start the simple game
      await this.simpleGame.init();
      
      this.isInitialized = true;
      console.log('🎮 Anime Aggressors Simple Demo initialized!');
    } catch (error) {
      console.error('Failed to initialize game:', error);
    }
  }

  handleResize(): void {
    this.simpleGame.handleResize();
  }

  destroy(): void {
    this.simpleGame.destroy();
  }
}
