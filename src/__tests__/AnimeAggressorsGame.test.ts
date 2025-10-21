/**
 * Anime Aggressors Game Tests
 * Comprehensive test suite for the ultimate anime fighting game
 */

import { AnimeAggressorsGame } from '../AnimeAggressorsGame';
import { FightingSystem, ElementalNature } from '../systems/FightingSystem';
import { InputSystem } from '../systems/InputSystem';
import { MoveDatabase } from '../systems/MoveDatabase';
import { ComboSystem } from '../systems/ComboSystem';
import { SuperMovesSystem } from '../systems/SuperMovesSystem';

describe('Anime Aggressors Game', () => {
  let game: AnimeAggressorsGame;

  beforeEach(() => {
    game = new AnimeAggressorsGame();
  });

  afterEach(() => {
    game.stopGame();
  });

  describe('Game Initialization', () => {
    test('should initialize with default game state', () => {
      const gameState = game.getGameState();
      expect(gameState.isRunning).toBe(false);
      expect(gameState.currentRound).toBe(1);
      expect(gameState.maxRounds).toBe(3);
      expect(gameState.timeLimit).toBe(180);
      expect(gameState.currentTime).toBe(180);
      expect(gameState.winner).toBeUndefined();
    });

    test('should have default game mode', () => {
      const gameMode = game.getGameMode('versus');
      expect(gameMode).toBeDefined();
      expect(gameMode?.name).toBe('Versus Mode');
      expect(gameMode?.maxPlayers).toBe(2);
      expect(gameMode?.timeLimit).toBe(180);
    });

    test('should have all game modes available', () => {
      const gameModes = game.getAllGameModes();
      expect(gameModes.length).toBeGreaterThan(0);
      
      const modeNames = gameModes.map(mode => mode.name);
      expect(modeNames).toContain('Versus Mode');
      expect(modeNames).toContain('Tournament Mode');
      expect(modeNames).toContain('Training Mode');
      expect(modeNames).toContain('Survival Mode');
    });
  });

  describe('Character System', () => {
    test('should have characters from multiple anime', () => {
      const characters = game.getAllCharacters();
      expect(characters.length).toBeGreaterThan(0);

      const animeList = characters.map(char => char.anime);
      expect(animeList).toContain('Naruto');
      expect(animeList).toContain('Dragon Ball Z');
      expect(animeList).toContain('One Piece');
      expect(animeList).toContain('Bleach');
      expect(animeList).toContain('Demon Slayer');
      expect(animeList).toContain('My Hero Academia');
      expect(animeList).toContain('Jujutsu Kaisen');
      expect(animeList).toContain('Attack on Titan');
    });

    test('should have characters with proper stats', () => {
      const naruto = game.getCharacter('naruto');
      expect(naruto).toBeDefined();
      expect(naruto?.stats.health).toBe(100);
      expect(naruto?.stats.chakra).toBe(100);
      expect(naruto?.stats.speed).toBe(8);
      expect(naruto?.stats.strength).toBe(9);
      expect(naruto?.stats.defense).toBe(7);
      expect(naruto?.stats.agility).toBe(8);
    });

    test('should have characters with elemental affinities', () => {
      const naruto = game.getCharacter('naruto');
      expect(naruto?.element).toBe(ElementalNature.WIND);

      const sasuke = game.getCharacter('sasuke');
      expect(sasuke?.element).toBe(ElementalNature.LIGHTNING);

      const goku = game.getCharacter('goku');
      expect(goku?.element).toBe(ElementalNature.LIGHTNING);

      const luffy = game.getCharacter('luffy');
      expect(luffy?.element).toBe('rubber'); // Custom element
    });

    test('should have characters with special moves', () => {
      const naruto = game.getCharacter('naruto');
      expect(naruto?.specialMoves).toContain('Rasengan');
      expect(naruto?.specialMoves).toContain('Shadow Clone Jutsu');
      expect(naruto?.specialMoves).toContain('Wind Style: Rasenshuriken');

      const goku = game.getCharacter('goku');
      expect(goku?.specialMoves).toContain('Kamehameha');
      expect(goku?.specialMoves).toContain('Dragon Fist');
      expect(goku?.specialMoves).toContain('Instant Transmission');
    });

    test('should have characters with super moves', () => {
      const naruto = game.getCharacter('naruto');
      expect(naruto?.superMoves).toContain('Sage Mode: Massive Rasengan');
      expect(naruto?.superMoves).toContain('Nine-Tails Chakra Mode');

      const goku = game.getCharacter('goku');
      expect(goku?.superMoves).toContain('Super Saiyan Transformation');
      expect(goku?.superMoves).toContain('Spirit Bomb');
    });

    test('should have characters with charge attacks', () => {
      const naruto = game.getCharacter('naruto');
      expect(naruto?.chargeAttacks).toContain('Charged Rasengan');

      const goku = game.getCharacter('goku');
      expect(goku?.chargeAttacks).toContain('Charged Kamehameha');
    });

    test('should have characters with combos', () => {
      const naruto = game.getCharacter('naruto');
      expect(naruto?.combos).toContain('Rasengan Combo');
      expect(naruto?.combos).toContain('Shadow Clone Combo');

      const goku = game.getCharacter('goku');
      expect(goku?.combos).toContain('Kamehameha Combo');
      expect(goku?.combos).toContain('Dragon Fist Combo');
    });

    test('should have characters with voice lines', () => {
      const naruto = game.getCharacter('naruto');
      expect(naruto?.voiceLines).toContain('Believe it!');
      expect(naruto?.voiceLines).toContain('I\'m gonna be Hokage!');
      expect(naruto?.voiceLines).toContain('Dattebayo!');

      const goku = game.getCharacter('goku');
      expect(goku?.voiceLines).toContain('Kamehameha!');
      expect(goku?.voiceLines).toContain('I\'m not done yet!');
      expect(goku?.voiceLines).toContain('Let\'s fight!');
    });

    test('should have characters with animations', () => {
      const naruto = game.getCharacter('naruto');
      expect(naruto?.animations).toContain('rasengan_charge');
      expect(naruto?.animations).toContain('shadow_clone');
      expect(naruto?.animations).toContain('sage_mode');

      const goku = game.getCharacter('goku');
      expect(goku?.animations).toContain('kamehameha_charge');
      expect(goku?.animations).toContain('super_saiyan');
      expect(goku?.animations).toContain('spirit_bomb');
    });

    test('should have characters with visual effects', () => {
      const naruto = game.getCharacter('naruto');
      expect(naruto?.visualEffects).toContain('wind_energy');
      expect(naruto?.visualEffects).toContain('orange_chakra');
      expect(naruto?.visualEffects).toContain('sage_aura');

      const goku = game.getCharacter('goku');
      expect(goku?.visualEffects).toContain('blue_energy');
      expect(goku?.visualEffects).toContain('golden_aura');
      expect(goku?.visualEffects).toContain('spirit_energy');
    });

    test('should filter characters by anime', () => {
      const narutoCharacters = game.getCharactersByAnime('Naruto');
      expect(narutoCharacters.length).toBeGreaterThan(0);
      expect(narutoCharacters.every(char => char.anime === 'Naruto')).toBe(true);

      const dragonBallCharacters = game.getCharactersByAnime('Dragon Ball Z');
      expect(dragonBallCharacters.length).toBeGreaterThan(0);
      expect(dragonBallCharacters.every(char => char.anime === 'Dragon Ball Z')).toBe(true);
    });

    test('should filter characters by element', () => {
      const windCharacters = game.getCharactersByElement(ElementalNature.WIND);
      expect(windCharacters.length).toBeGreaterThan(0);
      expect(windCharacters.every(char => char.element === ElementalNature.WIND)).toBe(true);

      const lightningCharacters = game.getCharactersByElement(ElementalNature.LIGHTNING);
      expect(lightningCharacters.length).toBeGreaterThan(0);
      expect(lightningCharacters.every(char => char.element === ElementalNature.LIGHTNING)).toBe(true);
    });

    test('should get random character', () => {
      const randomChar = game.getRandomCharacter();
      expect(randomChar).toBeDefined();
      expect(randomChar.id).toBeDefined();
      expect(randomChar.name).toBeDefined();
      expect(randomChar.anime).toBeDefined();
      expect(randomChar.element).toBeDefined();
    });
  });

  describe('Game Modes', () => {
    test('should have versus mode', () => {
      const versusMode = game.getGameMode('versus');
      expect(versusMode).toBeDefined();
      expect(versusMode?.name).toBe('Versus Mode');
      expect(versusMode?.maxPlayers).toBe(2);
      expect(versusMode?.timeLimit).toBe(180);
      expect(versusMode?.specialRules).toContain('No items');
      expect(versusMode?.specialRules).toContain('No assists');
      expect(versusMode?.specialRules).toContain('No transformations');
    });

    test('should have tournament mode', () => {
      const tournamentMode = game.getGameMode('tournament');
      expect(tournamentMode).toBeDefined();
      expect(tournamentMode?.name).toBe('Tournament Mode');
      expect(tournamentMode?.maxPlayers).toBe(8);
      expect(tournamentMode?.timeLimit).toBe(120);
      expect(tournamentMode?.specialRules).toContain('Best of 3');
      expect(tournamentMode?.specialRules).toContain('No items');
      expect(tournamentMode?.specialRules).toContain('No assists');
    });

    test('should have training mode', () => {
      const trainingMode = game.getGameMode('training');
      expect(trainingMode).toBeDefined();
      expect(trainingMode?.name).toBe('Training Mode');
      expect(trainingMode?.maxPlayers).toBe(2);
      expect(trainingMode?.timeLimit).toBe(0);
      expect(trainingMode?.specialRules).toContain('Infinite health');
      expect(trainingMode?.specialRules).toContain('Infinite chakra');
      expect(trainingMode?.specialRules).toContain('No damage');
    });

    test('should have survival mode', () => {
      const survivalMode = game.getGameMode('survival');
      expect(survivalMode).toBeDefined();
      expect(survivalMode?.name).toBe('Survival Mode');
      expect(survivalMode?.maxPlayers).toBe(1);
      expect(survivalMode?.timeLimit).toBe(0);
      expect(survivalMode?.specialRules).toContain('Infinite waves');
      expect(survivalMode?.specialRules).toContain('Increasing difficulty');
      expect(survivalMode?.specialRules).toContain('No healing');
    });
  });

  describe('Game Start/Stop', () => {
    test('should start game with valid parameters', () => {
      const playerIds = ['player1', 'player2'];
      const success = game.startGame('versus', playerIds);
      expect(success).toBe(true);
      
      const gameState = game.getGameState();
      expect(gameState.isRunning).toBe(true);
      expect(gameState.gameMode.name).toBe('Versus Mode');
    });

    test('should not start game if already running', () => {
      const playerIds = ['player1', 'player2'];
      game.startGame('versus', playerIds);
      
      const success = game.startGame('versus', playerIds);
      expect(success).toBe(false);
    });

    test('should not start game with invalid mode', () => {
      const playerIds = ['player1', 'player2'];
      const success = game.startGame('invalid_mode', playerIds);
      expect(success).toBe(false);
    });

    test('should not start game with too many players', () => {
      const playerIds = ['player1', 'player2', 'player3'];
      const success = game.startGame('versus', playerIds);
      expect(success).toBe(false);
    });

    test('should stop game', () => {
      const playerIds = ['player1', 'player2'];
      game.startGame('versus', playerIds);
      
      game.stopGame();
      
      const gameState = game.getGameState();
      expect(gameState.isRunning).toBe(false);
    });
  });

  describe('Player Management', () => {
    test('should create players when game starts', () => {
      const playerIds = ['player1', 'player2'];
      game.startGame('versus', playerIds);
      
      const players = game.getAllPlayers();
      expect(players.length).toBe(2);
      
      const player1 = game.getPlayer('player1');
      expect(player1).toBeDefined();
      expect(player1?.id).toBe('player1');
      expect(player1?.character).toBeDefined();
      expect(player1?.health).toBe(player1?.maxHealth);
      expect(player1?.chakra).toBe(player1?.maxChakra);
    });

    test('should initialize player stats correctly', () => {
      const playerIds = ['player1', 'player2'];
      game.startGame('versus', playerIds);
      
      const player1 = game.getPlayer('player1');
      expect(player1?.position).toEqual({ x: 0, y: 0 });
      expect(player1?.velocity).toEqual({ x: 0, y: 0 });
      expect(player1?.isGrounded).toBe(true);
      expect(player1?.isBlocking).toBe(false);
      expect(player1?.isStunned).toBe(false);
      expect(player1?.isInvulnerable).toBe(false);
      expect(player1?.score).toBe(0);
      expect(player1?.wins).toBe(0);
      expect(player1?.losses).toBe(0);
    });

    test('should assign random characters to players', () => {
      const playerIds = ['player1', 'player2'];
      game.startGame('versus', playerIds);
      
      const player1 = game.getPlayer('player1');
      const player2 = game.getPlayer('player2');
      
      expect(player1?.character).toBeDefined();
      expect(player2?.character).toBeDefined();
      expect(player1?.character.id).toBeDefined();
      expect(player2?.character.id).toBeDefined();
    });
  });

  describe('Game State Management', () => {
    test('should track game time', () => {
      const playerIds = ['player1', 'player2'];
      game.startGame('versus', playerIds);
      
      const gameState = game.getGameState();
      expect(gameState.currentTime).toBe(180);
      expect(gameState.timeLimit).toBe(180);
    });

    test('should track current round', () => {
      const gameState = game.getGameState();
      expect(gameState.currentRound).toBe(1);
      expect(gameState.maxRounds).toBe(3);
    });

    test('should track winner', () => {
      const gameState = game.getGameState();
      expect(gameState.winner).toBeUndefined();
    });
  });

  describe('Game Result Tracking', () => {
    test('should return null result when no winner', () => {
      const result = game.getGameResult();
      expect(result).toBeNull();
    });

    test('should calculate game statistics', () => {
      const playerIds = ['player1', 'player2'];
      game.startGame('versus', playerIds);
      
      // Simulate some gameplay
      const player1 = game.getPlayer('player1');
      if (player1) {
        player1.health = 50;
        player1.chakra = 80;
        player1.score = 100;
      }
      
      const result = game.getGameResult();
      if (result) {
        expect(result.winner).toBeDefined();
        expect(result.loser).toBeDefined();
        expect(result.duration).toBeDefined();
        expect(result.finalScore).toBeDefined();
        expect(result.statistics).toBeDefined();
      }
    });
  });

  describe('Integration Tests', () => {
    test('should integrate all systems correctly', () => {
      const playerIds = ['player1', 'player2'];
      const success = game.startGame('versus', playerIds);
      expect(success).toBe(true);
      
      const gameState = game.getGameState();
      expect(gameState.isRunning).toBe(true);
      
      const players = game.getAllPlayers();
      expect(players.length).toBe(2);
      
      const characters = game.getAllCharacters();
      expect(characters.length).toBeGreaterThan(0);
      
      const gameModes = game.getAllGameModes();
      expect(gameModes.length).toBeGreaterThan(0);
    });

    test('should handle multiple game sessions', () => {
      // First game
      const playerIds1 = ['player1', 'player2'];
      game.startGame('versus', playerIds1);
      expect(game.getGameState().isRunning).toBe(true);
      
      game.stopGame();
      expect(game.getGameState().isRunning).toBe(false);
      
      // Second game
      const playerIds2 = ['player3', 'player4'];
      game.startGame('tournament', playerIds2);
      expect(game.getGameState().isRunning).toBe(true);
      expect(game.getGameState().gameMode.name).toBe('Tournament Mode');
      
      game.stopGame();
      expect(game.getGameState().isRunning).toBe(false);
    });
  });

  describe('Error Handling', () => {
    test('should handle invalid player IDs gracefully', () => {
      const playerIds = ['invalid_player'];
      const success = game.startGame('versus', playerIds);
      expect(success).toBe(false);
    });

    test('should handle empty player list gracefully', () => {
      const playerIds: string[] = [];
      const success = game.startGame('versus', playerIds);
      expect(success).toBe(false);
    });

    test('should handle undefined game mode gracefully', () => {
      const playerIds = ['player1', 'player2'];
      const success = game.startGame('undefined_mode', playerIds);
      expect(success).toBe(false);
    });
  });

  describe('Performance Tests', () => {
    test('should handle large character roster efficiently', () => {
      const characters = game.getAllCharacters();
      expect(characters.length).toBeGreaterThan(0);
      
      // Test character lookup performance
      const startTime = Date.now();
      for (let i = 0; i < 1000; i++) {
        game.getRandomCharacter();
      }
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(1000); // Should complete in less than 1 second
    });

    test('should handle multiple game modes efficiently', () => {
      const gameModes = game.getAllGameModes();
      expect(gameModes.length).toBeGreaterThan(0);
      
      // Test game mode lookup performance
      const startTime = Date.now();
      for (let i = 0; i < 1000; i++) {
        game.getGameMode('versus');
      }
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      expect(duration).toBeLessThan(1000); // Should complete in less than 1 second
    });
  });
});

