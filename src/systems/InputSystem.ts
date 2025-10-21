/**
 * Anime Aggressors Input System
 * Smash Bros-inspired controls with multi-input combos
 * Core Controls: Attack, Special, Shield, Grab, Jump + Movement + Multi-input
 */

export interface InputState {
  attack: boolean;
  special: boolean;
  shield: boolean;
  grab: boolean;
  jump: boolean;
  
  // Directional inputs
  forward: boolean;
  back: boolean;
  up: boolean;
  down: boolean;
  
  // Movement
  left: boolean;
  right: boolean;
  
  // Multi-input tracking
  inputSequence: InputEvent[];
  lastInputTime: number;
  comboBuffer: number; // milliseconds
}

export interface InputEvent {
  button: InputButton;
  direction?: InputDirection;
  timestamp: number;
  pressed: boolean;
  hold?: boolean;
}

export enum InputButton {
  ATTACK = 'attack',
  SPECIAL = 'special',
  SHIELD = 'shield',
  GRAB = 'grab',
  JUMP = 'jump'
}

export enum InputDirection {
  FORWARD = 'forward',
  BACK = 'back',
  UP = 'up',
  DOWN = 'down',
  NEUTRAL = 'neutral'
}

export interface ComboInput {
  button: InputButton;
  direction?: InputDirection;
  timing: number; // milliseconds between inputs
  hold?: boolean;
  release?: boolean;
}

export interface MoveInput {
  button: InputButton;
  direction?: InputDirection;
  hold?: boolean;
  charge?: boolean;
  release?: boolean;
}

export class InputSystem {
  private inputState: InputState;
  private inputHistory: InputEvent[] = [];
  private comboSystem: ComboSystem;
  private moveSystem: MoveSystem;
  private inputBuffer: InputBuffer;

  constructor() {
    this.inputState = this.createInitialInputState();
    this.comboSystem = new ComboSystem();
    this.moveSystem = new MoveSystem();
    this.inputBuffer = new InputBuffer();
  }

  private createInitialInputState(): InputState {
    return {
      attack: false,
      special: false,
      shield: false,
      grab: false,
      jump: false,
      forward: false,
      back: false,
      up: false,
      down: false,
      left: false,
      right: false,
      inputSequence: [],
      lastInputTime: 0,
      comboBuffer: 200 // 200ms combo buffer
    };
  }

  public processInput(input: InputEvent): InputResult {
    const currentTime = Date.now();
    
    // Update input state
    this.updateInputState(input);
    
    // Add to input history
    this.inputHistory.push(input);
    this.trimInputHistory();
    
    // Check for combos
    const comboResult = this.comboSystem.processInput(input, this.inputState);
    if (comboResult.success) {
      return {
        type: 'combo',
        combo: comboResult.combo,
        damage: comboResult.damage,
        effects: comboResult.effects
      };
    }
    
    // Check for moves
    const moveResult = this.moveSystem.processInput(input, this.inputState);
    if (moveResult.success) {
      return {
        type: 'move',
        move: moveResult.move,
        damage: moveResult.damage,
        effects: moveResult.effects
      };
    }
    
    // Check for basic inputs
    const basicResult = this.processBasicInput(input);
    if (basicResult.success) {
      return {
        type: 'basic',
        move: basicResult.move,
        damage: basicResult.damage,
        effects: basicResult.effects
      };
    }
    
    return { type: 'none' };
  }

  private updateInputState(input: InputEvent): void {
    const currentTime = Date.now();
    
    // Update button states
    switch (input.button) {
      case InputButton.ATTACK:
        this.inputState.attack = input.pressed;
        break;
      case InputButton.SPECIAL:
        this.inputState.special = input.pressed;
        break;
      case InputButton.SHIELD:
        this.inputState.shield = input.pressed;
        break;
      case InputButton.GRAB:
        this.inputState.grab = input.pressed;
        break;
      case InputButton.JUMP:
        this.inputState.jump = input.pressed;
        break;
    }
    
    // Update directional states
    if (input.direction) {
      switch (input.direction) {
        case InputDirection.FORWARD:
          this.inputState.forward = input.pressed;
          break;
        case InputDirection.BACK:
          this.inputState.back = input.pressed;
          break;
        case InputDirection.UP:
          this.inputState.up = input.pressed;
          break;
        case InputDirection.DOWN:
          this.inputState.down = input.pressed;
          break;
      }
    }
    
    // Update input sequence
    this.inputState.inputSequence.push(input);
    this.inputState.lastInputTime = currentTime;
    
    // Clean old inputs from sequence
    this.cleanInputSequence(currentTime);
  }

  private cleanInputSequence(currentTime: number): void {
    const bufferTime = this.inputState.comboBuffer;
    this.inputState.inputSequence = this.inputState.inputSequence.filter(
      input => currentTime - input.timestamp <= bufferTime
    );
  }

  private trimInputHistory(): void {
    const maxHistory = 100; // Keep last 100 inputs
    if (this.inputHistory.length > maxHistory) {
      this.inputHistory = this.inputHistory.slice(-maxHistory);
    }
  }

  private processBasicInput(input: InputEvent): BasicInputResult {
    // Process basic button presses
    if (input.pressed) {
      switch (input.button) {
        case InputButton.ATTACK:
          return this.processAttackInput(input);
        case InputButton.SPECIAL:
          return this.processSpecialInput(input);
        case InputButton.SHIELD:
          return this.processShieldInput(input);
        case InputButton.GRAB:
          return this.processGrabInput(input);
        case InputButton.JUMP:
          return this.processJumpInput(input);
      }
    }
    
    return { success: false };
  }

  private processAttackInput(input: InputEvent): BasicInputResult {
    const direction = input.direction || InputDirection.NEUTRAL;
    
    switch (direction) {
      case InputDirection.FORWARD:
        return {
          success: true,
          move: 'Forward Attack',
          damage: 20,
          effects: [{ type: 'damage', value: 20, target: 'enemy' }]
        };
      case InputDirection.BACK:
        return {
          success: true,
          move: 'Back Attack',
          damage: 18,
          effects: [{ type: 'damage', value: 18, target: 'enemy' }]
        };
      case InputDirection.UP:
        return {
          success: true,
          move: 'Up Attack',
          damage: 22,
          effects: [{ type: 'damage', value: 22, target: 'enemy' }]
        };
      case InputDirection.DOWN:
        return {
          success: true,
          move: 'Down Attack',
          damage: 19,
          effects: [{ type: 'damage', value: 19, target: 'enemy' }]
        };
      default:
        return {
          success: true,
          move: 'Neutral Attack',
          damage: 15,
          effects: [{ type: 'damage', value: 15, target: 'enemy' }]
        };
    }
  }

  private processSpecialInput(input: InputEvent): BasicInputResult {
    const direction = input.direction || InputDirection.NEUTRAL;
    
    switch (direction) {
      case InputDirection.FORWARD:
        return {
          success: true,
          move: 'Forward Special',
          damage: 35,
          effects: [{ type: 'damage', value: 35, target: 'enemy' }]
        };
      case InputDirection.BACK:
        return {
          success: true,
          move: 'Back Special',
          damage: 30,
          effects: [{ type: 'damage', value: 30, target: 'enemy' }]
        };
      case InputDirection.UP:
        return {
          success: true,
          move: 'Up Special',
          damage: 25,
          effects: [{ type: 'damage', value: 25, target: 'enemy' }]
        };
      case InputDirection.DOWN:
        return {
          success: true,
          move: 'Down Special',
          damage: 28,
          effects: [{ type: 'damage', value: 28, target: 'enemy' }]
        };
      default:
        return {
          success: true,
          move: 'Neutral Special',
          damage: 32,
          effects: [{ type: 'damage', value: 32, target: 'enemy' }]
        };
    }
  }

  private processShieldInput(input: InputEvent): BasicInputResult {
    return {
      success: true,
      move: 'Shield',
      damage: 0,
      effects: [{ type: 'buff', value: 50, target: 'self', duration: 2 }]
    };
  }

  private processGrabInput(input: InputEvent): BasicInputResult {
    return {
      success: true,
      move: 'Grab',
      damage: 12,
      effects: [{ type: 'damage', value: 12, target: 'enemy' }]
    };
  }

  private processJumpInput(input: InputEvent): BasicInputResult {
    return {
      success: true,
      move: 'Jump',
      damage: 0,
      effects: [{ type: 'buff', value: 30, target: 'self', duration: 1 }]
    };
  }

  public getInputState(): InputState {
    return { ...this.inputState };
  }

  public getInputHistory(): InputEvent[] {
    return [...this.inputHistory];
  }

  public clearInputBuffer(): void {
    this.inputBuffer.clear();
  }
}

export class ComboSystem {
  private comboDatabase: Map<string, Combo> = new Map();
  private activeCombos: Map<string, ComboState> = new Map();

  constructor() {
    this.initializeComboDatabase();
  }

  private initializeComboDatabase(): void {
    // Basic combos
    this.comboDatabase.set('basic_combo_1', {
      id: 'basic_combo_1',
      name: 'Basic Combo',
      description: 'Simple attack combination',
      inputs: [
        { button: InputButton.ATTACK, direction: InputDirection.FORWARD, timing: 0 },
        { button: InputButton.ATTACK, direction: InputDirection.NEUTRAL, timing: 300 },
        { button: InputButton.ATTACK, direction: InputDirection.FORWARD, timing: 600 }
      ],
      damage: 45,
      chakraCost: 15,
      element: ElementalNature.NEUTRAL,
      requirements: [],
      effects: [{ type: 'damage', value: 45, target: 'enemy' }]
    });

    this.comboDatabase.set('special_combo_1', {
      id: 'special_combo_1',
      name: 'Special Combo',
      description: 'Attack into special move',
      inputs: [
        { button: InputButton.ATTACK, direction: InputDirection.FORWARD, timing: 0 },
        { button: InputButton.SPECIAL, direction: InputDirection.FORWARD, timing: 400 }
      ],
      damage: 60,
      chakraCost: 25,
      element: ElementalNature.NEUTRAL,
      requirements: [],
      effects: [{ type: 'damage', value: 60, target: 'enemy' }]
    });

    // Advanced combos
    this.comboDatabase.set('advanced_combo_1', {
      id: 'advanced_combo_1',
      name: 'Advanced Combo',
      description: 'Complex attack sequence',
      inputs: [
        { button: InputButton.ATTACK, direction: InputDirection.FORWARD, timing: 0 },
        { button: InputButton.ATTACK, direction: InputDirection.NEUTRAL, timing: 200 },
        { button: InputButton.SPECIAL, direction: InputDirection.UP, timing: 400 },
        { button: InputButton.ATTACK, direction: InputDirection.DOWN, timing: 700 }
      ],
      damage: 80,
      chakraCost: 35,
      element: ElementalNature.NEUTRAL,
      requirements: [],
      effects: [{ type: 'damage', value: 80, target: 'enemy' }]
    });

    // Elemental combos
    this.comboDatabase.set('fire_combo', {
      id: 'fire_combo',
      name: 'Fire Combo',
      description: 'Fire elemental combination',
      inputs: [
        { button: InputButton.ATTACK, direction: InputDirection.FORWARD, timing: 0 },
        { button: InputButton.SPECIAL, direction: InputDirection.FORWARD, timing: 300 },
        { button: InputButton.ATTACK, direction: InputDirection.UP, timing: 600 }
      ],
      damage: 70,
      chakraCost: 30,
      element: ElementalNature.FIRE,
      requirements: [{ type: 'element', value: ElementalNature.FIRE, operator: 'equal' }],
      effects: [{ type: 'damage', value: 70, target: 'enemy' }]
    });

    this.comboDatabase.set('lightning_combo', {
      id: 'lightning_combo',
      name: 'Lightning Combo',
      description: 'Lightning elemental combination',
      inputs: [
        { button: InputButton.SPECIAL, direction: InputDirection.FORWARD, timing: 0 },
        { button: InputButton.ATTACK, direction: InputDirection.UP, timing: 250 },
        { button: InputButton.SPECIAL, direction: InputDirection.DOWN, timing: 500 }
      ],
      damage: 75,
      chakraCost: 35,
      element: ElementalNature.LIGHTNING,
      requirements: [{ type: 'element', value: ElementalNature.LIGHTNING, operator: 'equal' }],
      effects: [{ type: 'damage', value: 75, target: 'enemy' }]
    });

    // Add more combos...
  }

  public processInput(input: InputEvent, inputState: InputState): ComboResult {
    const currentTime = Date.now();
    
    // Check each combo in the database
    for (const [comboId, combo] of this.comboDatabase) {
      const comboState = this.activeCombos.get(comboId) || {
        progress: 0,
        lastInputTime: 0,
        inputSequence: []
      };
      
      if (this.checkComboInput(combo, input, comboState, currentTime)) {
        comboState.progress++;
        comboState.lastInputTime = currentTime;
        comboState.inputSequence.push(input);
        
        if (comboState.progress >= combo.inputs.length) {
          // Combo completed!
          this.activeCombos.delete(comboId);
          return {
            success: true,
            combo: combo,
            damage: combo.damage,
            effects: combo.effects
          };
        } else {
          this.activeCombos.set(comboId, comboState);
        }
      }
    }
    
    return { success: false };
  }

  private checkComboInput(combo: Combo, input: InputEvent, comboState: ComboState, currentTime: number): boolean {
    const expectedInput = combo.inputs[comboState.progress];
    if (!expectedInput) return false;
    
    // Check button match
    if (expectedInput.button !== input.button) return false;
    
    // Check direction match
    if (expectedInput.direction && expectedInput.direction !== input.direction) return false;
    
    // Check timing match (with tolerance)
    const timingTolerance = 100; // milliseconds
    const expectedTiming = expectedInput.timing;
    const actualTiming = currentTime - comboState.lastInputTime;
    
    if (Math.abs(actualTiming - expectedTiming) > timingTolerance) return false;
    
    return true;
  }
}

export class MoveSystem {
  private moveDatabase: Map<string, Move> = new Map();
  private activeMoves: Map<string, MoveState> = new Map();

  constructor() {
    this.initializeMoveDatabase();
  }

  private initializeMoveDatabase(): void {
    // Basic moves
    this.moveDatabase.set('basic_attack', {
      id: 'basic_attack',
      name: 'Basic Attack',
      description: 'Simple attack move',
      inputs: [{ button: InputButton.ATTACK, direction: InputDirection.NEUTRAL }],
      damage: 15,
      chakraCost: 5,
      element: ElementalNature.NEUTRAL,
      requirements: [],
      effects: [{ type: 'damage', value: 15, target: 'enemy' }]
    });

    this.moveDatabase.set('forward_attack', {
      id: 'forward_attack',
      name: 'Forward Attack',
      description: 'Forward directional attack',
      inputs: [{ button: InputButton.ATTACK, direction: InputDirection.FORWARD }],
      damage: 20,
      chakraCost: 8,
      element: ElementalNature.NEUTRAL,
      requirements: [],
      effects: [{ type: 'damage', value: 20, target: 'enemy' }]
    });

    this.moveDatabase.set('special_attack', {
      id: 'special_attack',
      name: 'Special Attack',
      description: 'Special move attack',
      inputs: [{ button: InputButton.SPECIAL, direction: InputDirection.NEUTRAL }],
      damage: 30,
      chakraCost: 15,
      element: ElementalNature.NEUTRAL,
      requirements: [],
      effects: [{ type: 'damage', value: 30, target: 'enemy' }]
    });

    // Charged moves
    this.moveDatabase.set('charged_attack', {
      id: 'charged_attack',
      name: 'Charged Attack',
      description: 'Hold attack to charge',
      inputs: [{ button: InputButton.ATTACK, direction: InputDirection.NEUTRAL, hold: true }],
      damage: 40,
      chakraCost: 20,
      element: ElementalNature.NEUTRAL,
      requirements: [],
      effects: [{ type: 'damage', value: 40, target: 'enemy' }]
    });

    // Add more moves...
  }

  public processInput(input: InputEvent, inputState: InputState): MoveResult {
    // Check for move matches
    for (const [moveId, move] of this.moveDatabase) {
      if (this.checkMoveInput(move, input)) {
        return {
          success: true,
          move: move,
          damage: move.damage,
          effects: move.effects
        };
      }
    }
    
    return { success: false };
  }

  private checkMoveInput(move: Move, input: InputEvent): boolean {
    const moveInput = move.inputs[0]; // For now, check first input
    if (!moveInput) return false;
    
    // Check button match
    if (moveInput.button !== input.button) return false;
    
    // Check direction match
    if (moveInput.direction && moveInput.direction !== input.direction) return false;
    
    // Check hold requirement
    if (moveInput.hold && !input.hold) return false;
    
    return true;
  }
}

export class InputBuffer {
  private buffer: InputEvent[] = [];
  private maxBufferSize: number = 10;
  private bufferTime: number = 100; // milliseconds

  public addInput(input: InputEvent): void {
    const currentTime = Date.now();
    
    // Clean old inputs
    this.buffer = this.buffer.filter(
      bufferedInput => currentTime - bufferedInput.timestamp <= this.bufferTime
    );
    
    // Add new input
    this.buffer.push(input);
    
    // Trim buffer if needed
    if (this.buffer.length > this.maxBufferSize) {
      this.buffer = this.buffer.slice(-this.maxBufferSize);
    }
  }

  public getBufferedInputs(): InputEvent[] {
    return [...this.buffer];
  }

  public clear(): void {
    this.buffer = [];
  }
}

// Supporting interfaces and types
interface InputResult {
  type: 'combo' | 'move' | 'basic' | 'none';
  combo?: Combo;
  move?: Move;
  damage?: number;
  effects?: MoveEffect[];
}

interface BasicInputResult {
  success: boolean;
  move?: string;
  damage?: number;
  effects?: MoveEffect[];
}

interface ComboResult {
  success: boolean;
  combo?: Combo;
  damage?: number;
  effects?: MoveEffect[];
}

interface MoveResult {
  success: boolean;
  move?: Move;
  damage?: number;
  effects?: MoveEffect[];
}

interface ComboState {
  progress: number;
  lastInputTime: number;
  inputSequence: InputEvent[];
}

interface MoveState {
  active: boolean;
  startTime: number;
  duration: number;
}

interface Combo {
  id: string;
  name: string;
  description: string;
  inputs: ComboInput[];
  damage: number;
  chakraCost: number;
  element: ElementalNature;
  requirements: ComboRequirement[];
  effects: MoveEffect[];
}

interface Move {
  id: string;
  name: string;
  description: string;
  inputs: MoveInput[];
  damage: number;
  chakraCost: number;
  element: ElementalNature;
  requirements: MoveRequirement[];
  effects: MoveEffect[];
}

interface ComboRequirement {
  type: 'health' | 'chakra' | 'element' | 'position' | 'previous_move';
  value: number | ElementalNature;
  operator: 'greater' | 'less' | 'equal';
}

interface MoveRequirement {
  type: 'health' | 'chakra' | 'element' | 'position';
  value: number | ElementalNature;
  operator: 'greater' | 'less' | 'equal';
}

interface MoveEffect {
  type: 'damage' | 'heal' | 'buff' | 'debuff' | 'status' | 'knockback' | 'launch';
  value: number;
  duration?: number;
  target: 'self' | 'enemy' | 'area';
  element?: ElementalNature;
}

enum ElementalNature {
  NEUTRAL = 'neutral',
  FIRE = 'fire',
  WATER = 'water',
  EARTH = 'earth',
  WIND = 'wind',
  LIGHTNING = 'lightning',
  ICE = 'ice',
  LAVA = 'lava',
  STORM = 'storm',
  CRYSTAL = 'crystal',
  SHADOW = 'shadow',
  VOID = 'void',
  SPACE = 'space',
  TIME = 'time',
  GRAVITY = 'gravity',
  PSYCHIC = 'psychic',
  CHAOS = 'chaos',
  ORDER = 'order',
  LIFE = 'life',
  DEATH = 'death',
  DREAM = 'dream',
  REALITY = 'reality'
}

export { ElementalNature };

