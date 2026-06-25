/**
 * Anime Aggressors Combo System
 * Multi-input combinations inspired by the most beloved anime techniques
 * Handles complex combo sequences with timing, direction, and elemental requirements
 */

import { ElementalNature } from './FightingSystem';

export interface ComboSequence {
  id: string;
  name: string;
  description: string;
  inspiration: {
    anime: string;
    character: string;
    technique: string;
    description: string;
    powerLevel: number;
    popularity: number;
  };
  inputs: ComboInput[];
  damage: number;
  chakraCost: number;
  element: ElementalNature;
  requirements: ComboRequirement[];
  effects: ComboEffect[];
  animation: string;
  visualEffects: string[];
}

export interface ComboInput {
  button: 'attack' | 'special' | 'shield' | 'grab' | 'jump';
  direction?: 'forward' | 'back' | 'up' | 'down' | 'neutral';
  timing: number; // milliseconds between inputs
  hold?: boolean;
  release?: boolean;
  charge?: boolean;
}

export interface ComboRequirement {
  type: 'health' | 'chakra' | 'element' | 'position' | 'previous_move' | 'combo_count';
  value: number | ElementalNature | string;
  operator: 'greater' | 'less' | 'equal' | 'not_equal';
}

export interface ComboEffect {
  type: 'damage' | 'heal' | 'buff' | 'debuff' | 'status' | 'knockback' | 'launch' | 'elemental';
  value: number;
  duration?: number;
  target: 'self' | 'enemy' | 'area';
  element?: ElementalNature;
}

export interface ComboState {
  activeCombo: ComboSequence | null;
  inputSequence: ComboInput[];
  lastInputTime: number;
  comboProgress: number;
  comboBuffer: number; // milliseconds
  comboTimer: number; // milliseconds
}

export interface ComboResult {
  success: boolean;
  combo?: ComboSequence;
  damage?: number;
  effects?: ComboEffect[];
  message?: string;
}

export class ComboSystem {
  private comboDatabase: Map<string, ComboSequence> = new Map();
  private activeCombos: Map<string, ComboState> = new Map();
  private comboBuffer: number = 300; // 300ms combo buffer
  private comboTimer: number = 2000; // 2 second combo timer

  constructor() {
    this.initializeComboDatabase();
  }

  private initializeComboDatabase(): void {
    // NARUTO INSPIRED COMBOS
    this.comboDatabase.set('naruto_shadow_clone_combo', {
      id: 'naruto_shadow_clone_combo',
      name: 'Shadow Clone Combo',
      description: 'Basic shadow clone combination inspired by Naruto\'s signature technique',
      inspiration: {
        anime: 'Naruto',
        character: 'Naruto Uzumaki',
        technique: 'Shadow Clone Jutsu',
        description: 'Creates multiple shadow clones to assist in combat',
        powerLevel: 7,
        popularity: 10
      },
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'attack', direction: 'neutral', timing: 300 },
        { button: 'special', direction: 'forward', timing: 600 }
      ],
      damage: 55,
      chakraCost: 25,
      element: ElementalNature.WIND,
      requirements: [],
      effects: [
        { type: 'damage', value: 55, target: 'enemy' },
        { type: 'elemental', value: 10, target: 'enemy', element: ElementalNature.WIND }
      ],
      animation: 'shadow_clone_combo',
      visualEffects: ['clone_appearance', 'wind_trail', 'combo_impact']
    });

    this.comboDatabase.set('naruto_rasengan_combo', {
      id: 'naruto_rasengan_combo',
      name: 'Rasengan Combo',
      description: 'Advanced Rasengan combination inspired by Naruto\'s signature technique',
      inspiration: {
        anime: 'Naruto',
        character: 'Naruto Uzumaki',
        technique: 'Rasengan',
        description: 'Spinning chakra sphere that causes massive damage',
        powerLevel: 9,
        popularity: 10
      },
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'special', direction: 'neutral', timing: 200 },
        { button: 'special', direction: 'forward', timing: 400 }
      ],
      damage: 80,
      chakraCost: 45,
      element: ElementalNature.WIND,
      requirements: [
        { type: 'chakra', value: 45, operator: 'greater' }
      ],
      effects: [
        { type: 'damage', value: 80, target: 'enemy' },
        { type: 'knockback', value: 100, target: 'enemy' },
        { type: 'elemental', value: 20, target: 'enemy', element: ElementalNature.WIND }
      ],
      animation: 'rasengan_combo',
      visualEffects: ['spinning_energy', 'wind_vortex', 'combo_impact']
    });

    // DRAGON BALL Z INSPIRED COMBOS
    this.comboDatabase.set('goku_ki_combo', {
      id: 'goku_ki_combo',
      name: 'Ki Combo',
      description: 'Basic ki combination inspired by Goku\'s fighting style',
      inspiration: {
        anime: 'Dragon Ball Z',
        character: 'Son Goku',
        technique: 'Ki Manipulation',
        description: 'Energy manipulation for combat',
        powerLevel: 8,
        popularity: 10
      },
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'attack', direction: 'neutral', timing: 200 },
        { button: 'special', direction: 'forward', timing: 400 }
      ],
      damage: 65,
      chakraCost: 30,
      element: ElementalNature.LIGHTNING,
      requirements: [],
      effects: [
        { type: 'damage', value: 65, target: 'enemy' },
        { type: 'elemental', value: 15, target: 'enemy', element: ElementalNature.LIGHTNING }
      ],
      animation: 'ki_combo',
      visualEffects: ['ki_energy', 'lightning_trail', 'combo_impact']
    });

    this.comboDatabase.set('goku_dragon_combo', {
      id: 'goku_dragon_combo',
      name: 'Dragon Combo',
      description: 'Advanced ki combination inspired by Goku\'s signature techniques',
      inspiration: {
        anime: 'Dragon Ball Z',
        character: 'Son Goku',
        technique: 'Dragon Fist',
        description: 'Powerful ki-enhanced punch technique',
        powerLevel: 9,
        popularity: 9
      },
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'special', direction: 'up', timing: 300 },
        { button: 'special', direction: 'down', timing: 600 }
      ],
      damage: 95,
      chakraCost: 50,
      element: ElementalNature.LIGHTNING,
      requirements: [
        { type: 'chakra', value: 50, operator: 'greater' }
      ],
      effects: [
        { type: 'damage', value: 95, target: 'enemy' },
        { type: 'knockback', value: 120, target: 'enemy' },
        { type: 'elemental', value: 25, target: 'enemy', element: ElementalNature.LIGHTNING }
      ],
      animation: 'dragon_combo',
      visualEffects: ['dragon_energy', 'lightning_impact', 'combo_impact']
    });

    // ONE PIECE INSPIRED COMBOS
    this.comboDatabase.set('luffy_gum_gum_combo', {
      id: 'luffy_gum_gum_combo',
      name: 'Gum-Gum Combo',
      description: 'Rubber combination inspired by Luffy\'s fighting style',
      inspiration: {
        anime: 'One Piece',
        character: 'Monkey D. Luffy',
        technique: 'Gum-Gum Fruit',
        description: 'Rubber body powers for combat',
        powerLevel: 7,
        popularity: 9
      },
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'attack', direction: 'forward', timing: 300 },
        { button: 'special', direction: 'forward', timing: 600 }
      ],
      damage: 70,
      chakraCost: 35,
      element: ElementalNature.RUBBER, // Custom element
      requirements: [],
      effects: [
        { type: 'damage', value: 70, target: 'enemy' },
        { type: 'knockback', value: 80, target: 'enemy' }
      ],
      animation: 'gum_gum_combo',
      visualEffects: ['rubber_stretch', 'impact_effect', 'combo_impact']
    });

    // BLEACH INSPIRED COMBOS
    this.comboDatabase.set('ichigo_zanpakuto_combo', {
      id: 'ichigo_zanpakuto_combo',
      name: 'Zanpakuto Combo',
      description: 'Spiritual sword combination inspired by Ichigo\'s techniques',
      inspiration: {
        anime: 'Bleach',
        character: 'Ichigo Kurosaki',
        technique: 'Zanpakuto Techniques',
        description: 'Spiritual energy sword techniques',
        powerLevel: 8,
        popularity: 8
      },
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'attack', direction: 'up', timing: 250 },
        { button: 'special', direction: 'forward', timing: 500 }
      ],
      damage: 75,
      chakraCost: 40,
      element: ElementalNature.SHADOW,
      requirements: [],
      effects: [
        { type: 'damage', value: 75, target: 'enemy' },
        { type: 'elemental', value: 20, target: 'enemy', element: ElementalNature.SHADOW }
      ],
      animation: 'zanpakuto_combo',
      visualEffects: ['spiritual_energy', 'sword_trail', 'combo_impact']
    });

    // DEMON SLAYER INSPIRED COMBOS
    this.comboDatabase.set('tanjiro_water_breathing_combo', {
      id: 'tanjiro_water_breathing_combo',
      name: 'Water Breathing Combo',
      description: 'Water breathing combination inspired by Tanjiro\'s techniques',
      inspiration: {
        anime: 'Demon Slayer',
        character: 'Tanjiro Kamado',
        technique: 'Water Breathing',
        description: 'Sword technique that mimics water flow',
        powerLevel: 6,
        popularity: 8
      },
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'attack', direction: 'up', timing: 300 },
        { button: 'attack', direction: 'down', timing: 600 }
      ],
      damage: 60,
      chakraCost: 25,
      element: ElementalNature.WATER,
      requirements: [],
      effects: [
        { type: 'damage', value: 60, target: 'enemy' },
        { type: 'elemental', value: 15, target: 'enemy', element: ElementalNature.WATER }
      ],
      animation: 'water_breathing_combo',
      visualEffects: ['water_trail', 'sword_flow', 'combo_impact']
    });

    // MY HERO ACADEMIA INSPIRED COMBOS
    this.comboDatabase.set('deku_one_for_all_combo', {
      id: 'deku_one_for_all_combo',
      name: 'One For All Combo',
      description: 'Superhuman strength combination inspired by Deku\'s quirk',
      inspiration: {
        anime: 'My Hero Academia',
        character: 'Izuku Midoriya',
        technique: 'One For All',
        description: 'Superhuman strength quirk',
        powerLevel: 9,
        popularity: 9
      },
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'special', direction: 'forward', timing: 400 },
        { button: 'attack', direction: 'up', timing: 800 }
      ],
      damage: 85,
      chakraCost: 45,
      element: ElementalNature.LIGHTNING,
      requirements: [],
      effects: [
        { type: 'damage', value: 85, target: 'enemy' },
        { type: 'knockback', value: 100, target: 'enemy' }
      ],
      animation: 'one_for_all_combo',
      visualEffects: ['lightning_energy', 'impact_crater', 'combo_impact']
    });

    // JUJUTSU KAISEN INSPIRED COMBOS
    this.comboDatabase.set('yuji_cursed_energy_combo', {
      id: 'yuji_cursed_energy_combo',
      name: 'Cursed Energy Combo',
      description: 'Cursed energy combination inspired by Yuji\'s techniques',
      inspiration: {
        anime: 'Jujutsu Kaisen',
        character: 'Yuji Itadori',
        technique: 'Cursed Energy',
        description: 'Supernatural energy for combat',
        powerLevel: 7,
        popularity: 8
      },
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'attack', direction: 'forward', timing: 300 },
        { button: 'special', direction: 'forward', timing: 600 }
      ],
      damage: 75,
      chakraCost: 40,
      element: ElementalNature.CURSE, // Custom element
      requirements: [],
      effects: [
        { type: 'damage', value: 75, target: 'enemy' },
        { type: 'elemental', value: 20, target: 'enemy', element: ElementalNature.CURSE }
      ],
      animation: 'cursed_energy_combo',
      visualEffects: ['cursed_energy_aura', 'dark_impact', 'combo_impact']
    });

    // ATTACK ON TITAN INSPIRED COMBOS
    this.comboDatabase.set('eren_titan_combo', {
      id: 'eren_titan_combo',
      name: 'Titan Combo',
      description: 'Titan transformation combination inspired by Eren\'s techniques',
      inspiration: {
        anime: 'Attack on Titan',
        character: 'Eren Yeager',
        technique: 'Titan Transformation',
        description: 'Transform into a massive titan for combat',
        powerLevel: 8,
        popularity: 9
      },
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'attack', direction: 'down', timing: 400 },
        { button: 'special', direction: 'forward', timing: 800 }
      ],
      damage: 90,
      chakraCost: 50,
      element: ElementalNature.EARTH,
      requirements: [],
      effects: [
        { type: 'damage', value: 90, target: 'enemy' },
        { type: 'knockback', value: 120, target: 'enemy' }
      ],
      animation: 'titan_combo',
      visualEffects: ['titan_fist', 'earth_impact', 'combo_impact']
    });

    // Add more combos from other anime...
    this.addMoreAnimeCombos();
  }

  private addMoreAnimeCombos(): void {
    // Add combos from other popular anime
    // This would include combos from:
    // - Fullmetal Alchemist
    // - Hunter x Hunter
    // - JoJo's Bizarre Adventure
    // - Death Note
    // - Tokyo Ghoul
    // - And many more...
  }

  public processInput(fighterId: string, input: ComboInput): ComboResult {
    const currentTime = Date.now();
    const comboState = this.activeCombos.get(fighterId) || this.createInitialComboState();
    
    // Update combo state
    comboState.inputSequence.push(input);
    comboState.lastInputTime = currentTime;
    
    // Clean old inputs
    this.cleanInputSequence(comboState, currentTime);
    
    // Check for combo matches
    for (const [comboId, combo] of this.comboDatabase) {
      if (this.checkComboMatch(combo, comboState, currentTime)) {
        // Combo completed!
        this.activeCombos.delete(fighterId);
        return {
          success: true,
          combo: combo,
          damage: combo.damage,
          effects: combo.effects,
          message: `Combo executed: ${combo.name}!`
        };
      }
    }
    
    // Update active combo state
    this.activeCombos.set(fighterId, comboState);
    
    return { success: false };
  }

  private createInitialComboState(): ComboState {
    return {
      activeCombo: null,
      inputSequence: [],
      lastInputTime: 0,
      comboProgress: 0,
      comboBuffer: this.comboBuffer,
      comboTimer: this.comboTimer
    };
  }

  private cleanInputSequence(comboState: ComboState, currentTime: number): void {
    comboState.inputSequence = comboState.inputSequence.filter(
      input => currentTime - input.timing <= comboState.comboBuffer
    );
  }

  private checkComboMatch(combo: ComboSequence, comboState: ComboState, currentTime: number): boolean {
    const inputSequence = comboState.inputSequence;
    const comboInputs = combo.inputs;
    
    if (inputSequence.length < comboInputs.length) {
      return false;
    }
    
    // Check if the last N inputs match the combo sequence
    const startIndex = inputSequence.length - comboInputs.length;
    const recentInputs = inputSequence.slice(startIndex);
    
    for (let i = 0; i < comboInputs.length; i++) {
      const comboInput = comboInputs[i];
      const actualInput = recentInputs[i];
      
      if (!this.checkInputMatch(comboInput, actualInput, currentTime)) {
        return false;
      }
    }
    
    return true;
  }

  private checkInputMatch(comboInput: ComboInput, actualInput: ComboInput, currentTime: number): boolean {
    // Check button match
    if (comboInput.button !== actualInput.button) return false;
    
    // Check direction match
    if (comboInput.direction && comboInput.direction !== actualInput.direction) return false;
    
    // Check timing match (with tolerance)
    const timingTolerance = 100; // milliseconds
    const expectedTiming = comboInput.timing;
    const actualTiming = actualInput.timing;
    
    if (Math.abs(actualTiming - expectedTiming) > timingTolerance) return false;
    
    // Check hold requirement
    if (comboInput.hold && !actualInput.hold) return false;
    
    // Check release requirement
    if (comboInput.release && !actualInput.release) return false;
    
    // Check charge requirement
    if (comboInput.charge && !actualInput.charge) return false;
    
    return true;
  }

  public getCombo(comboId: string): ComboSequence | undefined {
    return this.comboDatabase.get(comboId);
  }

  public getAllCombos(): ComboSequence[] {
    return Array.from(this.comboDatabase.values());
  }

  public getCombosByElement(element: ElementalNature): ComboSequence[] {
    return this.getAllCombos().filter(combo => combo.element === element);
  }

  public getCombosByAnime(anime: string): ComboSequence[] {
    return this.getAllCombos().filter(combo => combo.inspiration.anime === anime);
  }

  public getCombosByPowerLevel(powerLevel: number): ComboSequence[] {
    return this.getAllCombos().filter(combo => combo.inspiration.powerLevel === powerLevel);
  }

  public getRandomCombo(): ComboSequence {
    const combos = this.getAllCombos();
    return combos[Math.floor(Math.random() * combos.length)];
  }

  public getRandomComboByElement(element: ElementalNature): ComboSequence {
    const combos = this.getCombosByElement(element);
    return combos[Math.floor(Math.random() * combos.length)];
  }

  public getRandomComboByAnime(anime: string): ComboSequence {
    const combos = this.getCombosByAnime(anime);
    return combos[Math.floor(Math.random() * combos.length)];
  }

  public searchCombos(query: string): ComboSequence[] {
    const results: ComboSequence[] = [];
    const lowerQuery = query.toLowerCase();

    for (const combo of this.getAllCombos()) {
      if (
        combo.name.toLowerCase().includes(lowerQuery) ||
        combo.description.toLowerCase().includes(lowerQuery) ||
        combo.inspiration.anime.toLowerCase().includes(lowerQuery) ||
        combo.inspiration.character.toLowerCase().includes(lowerQuery) ||
        combo.inspiration.technique.toLowerCase().includes(lowerQuery)
      ) {
        results.push(combo);
      }
    }

    return results;
  }

  public getComboState(fighterId: string): ComboState | undefined {
    return this.activeCombos.get(fighterId);
  }

  public clearComboState(fighterId: string): void {
    this.activeCombos.delete(fighterId);
  }

  public clearAllComboStates(): void {
    this.activeCombos.clear();
  }
}

// Custom elemental natures for unique anime-inspired combos
export enum CustomElementalNature {
  RUBBER = 'rubber',
  CURSE = 'curse',
  QUIRK = 'quirk',
  BREATHING = 'breathing',
  TITAN = 'titan',
  ALCHEMY = 'alchemy',
  NEN = 'nen',
  STAND = 'stand',
  SHINIGAMI = 'shinigami',
  GHUL = 'ghoul'
}

export { CustomElementalNature };

