import { SimpleGame } from './SimpleGame.js';
export class Game {
    constructor() {
        this.isInitialized = false;
        this.canvas = document.getElementById('game-canvas');
        if (!this.canvas) {
            throw new Error('Game canvas not found');
        }
        this.simpleGame = new SimpleGame();
    }
    async init() {
        try {
            // Start the simple game
            await this.simpleGame.init();
            this.isInitialized = true;
            console.log('🎮 Anime Aggressors Simple Demo initialized!');
        }
        catch (error) {
            console.error('Failed to initialize game:', error);
        }
    }
    handleResize() {
        this.simpleGame.handleResize();
    }
    destroy() {
        this.simpleGame.destroy();
    }
}
