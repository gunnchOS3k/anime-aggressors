/**
 * Anime Aggressors Fighting System
 * Inspired by Super Smash Bros with original moves from across all anime
 * Core Controls: Attack, Special, Shield, Grab, Jump + Movement + Multi-input combos
 */

export interface Fighter {
  id: string;
  name: string;
  element: ElementalNature;
  stats: FighterStats;
  moves: MoveSet;
  combos: Combo[];
  superMoves: SuperMove[];
  chargeAttacks: ChargeAttack[];
}

export interface FighterStats {
  health: number;
  maxHealth: number;
  chakra: number;
  maxChakra: number;
  speed: number;
  power: number;
  defense: number;
  agility: number;
  elementalAffinity: number;
}

export interface MoveSet {
  // Basic Smash Bros style controls
  attack: BasicMove;
  special: BasicMove;
  shield: BasicMove;
  grab: BasicMove;
  jump: BasicMove;
  
  // Directional variations
  forwardAttack: DirectionalMove;
  backAttack: DirectionalMove;
  upAttack: DirectionalMove;
  downAttack: DirectionalMove;
  
  forwardSpecial: DirectionalMove;
  backSpecial: DirectionalMove;
  upSpecial: DirectionalMove;
  downSpecial: DirectionalMove;
  
  // Aerial moves
  aerialAttack: AerialMove;
  aerialSpecial: AerialMove;
  
  // Charged moves
  chargedAttack: ChargedMove;
  chargedSpecial: ChargedMove;
}

export interface BasicMove {
  name: string;
  description: string;
  damage: number;
  chakraCost: number;
  cooldown: number;
  range: number;
  element: ElementalNature;
  animation: string;
  effects: MoveEffect[];
}

export interface DirectionalMove extends BasicMove {
  direction: 'forward' | 'back' | 'up' | 'down';
  knockback: number;
  launchAngle: number;
}

export interface AerialMove extends BasicMove {
  aerialType: 'neutral' | 'forward' | 'back' | 'up' | 'down';
  fallSpeed: number;
  recovery: number;
}

export interface ChargedMove extends BasicMove {
  chargeTime: number;
  maxCharge: number;
  chargeMultiplier: number;
  visualEffect: string;
}

export interface Combo {
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

export interface ComboInput {
  button: 'attack' | 'special' | 'shield' | 'grab' | 'jump';
  direction?: 'forward' | 'back' | 'up' | 'down' | 'neutral';
  timing: number; // milliseconds between inputs
  hold?: boolean;
}

export interface SuperMove {
  id: string;
  name: string;
  description: string;
  damage: number;
  chakraCost: number;
  element: ElementalNature;
  requirements: SuperMoveRequirement[];
  effects: MoveEffect[];
  animation: string;
  inspiration: string; // Which anime technique inspired this
}

export interface ChargeAttack {
  id: string;
  name: string;
  description: string;
  chargeTime: number;
  damage: number;
  chakraCost: number;
  element: ElementalNature;
  effects: MoveEffect[];
  inspiration: string;
}

export interface MoveEffect {
  type: 'damage' | 'heal' | 'buff' | 'debuff' | 'status' | 'knockback' | 'launch';
  value: number;
  duration?: number;
  target: 'self' | 'enemy' | 'area';
  element?: ElementalNature;
}

export interface ComboRequirement {
  type: 'health' | 'chakra' | 'element' | 'position' | 'previous_move';
  value: number;
  operator: 'greater' | 'less' | 'equal';
}

export interface SuperMoveRequirement {
  type: 'chakra' | 'health' | 'combo_count' | 'element_affinity';
  value: number;
  operator: 'greater' | 'less' | 'equal';
}

export enum ElementalNature {
  // Naruto-inspired elements
  FIRE = 'fire',
  WATER = 'water',
  EARTH = 'earth',
  WIND = 'wind',
  LIGHTNING = 'lightning',
  
  // Advanced elements
  ICE = 'ice',
  LAVA = 'lava',
  STORM = 'storm',
  CRYSTAL = 'crystal',
  SHADOW = 'shadow',
  
  // Special elements
  VOID = 'void',
  SPACE = 'space',
  TIME = 'time',
  GRAVITY = 'gravity',
  PSYCHIC = 'psychic',
  
  // Unique elements
  CHAOS = 'chaos',
  ORDER = 'order',
  LIFE = 'life',
  DEATH = 'death',
  DREAM = 'dream',
  REALITY = 'reality'
}

export class FightingSystem {
  private fighters: Map<string, Fighter> = new Map();
  private activeFighters: Map<string, FighterState> = new Map();
  private comboSystem: ComboSystem;
  private elementalSystem: ElementalSystem;
  private moveInspiration: MoveInspirationDatabase;

  constructor() {
    this.comboSystem = new ComboSystem();
    this.elementalSystem = new ElementalSystem();
    this.moveInspiration = new MoveInspirationDatabase();
    this.initializeFighters();
  }

  private initializeFighters() {
    // Create fighters with unique move sets inspired by various anime
    this.createNarutoFighter();
    this.createDragonBallFighter();
    this.createOnePieceFighter();
    this.createBleachFighter();
    this.createDemonSlayerFighter();
    this.createAttackOnTitanFighter();
    this.createMyHeroAcademiaFighter();
    this.createJujutsuKaisenFighter();
  }

  private createNarutoFighter(): Fighter {
    return {
      id: 'naruto',
      name: 'Naruto Uzumaki',
      element: ElementalNature.WIND,
      stats: {
        health: 100,
        maxHealth: 100,
        chakra: 100,
        maxChakra: 100,
        speed: 85,
        power: 90,
        defense: 75,
        agility: 95,
        elementalAffinity: 90
      },
      moves: {
        attack: {
          name: 'Shadow Clone Strike',
          description: 'Basic punch with shadow clone assistance',
          damage: 15,
          chakraCost: 5,
          cooldown: 0.5,
          range: 2,
          element: ElementalNature.WIND,
          animation: 'punch_with_clone',
          effects: [{ type: 'damage', value: 15, target: 'enemy' }]
        },
        special: {
          name: 'Rasengan',
          description: 'Spinning chakra sphere attack',
          damage: 35,
          chakraCost: 20,
          cooldown: 2,
          range: 3,
          element: ElementalNature.WIND,
          animation: 'rasengan_spin',
          effects: [{ type: 'damage', value: 35, target: 'enemy' }, { type: 'knockback', value: 50, target: 'enemy' }]
        },
        shield: {
          name: 'Chakra Shield',
          description: 'Defensive chakra barrier',
          damage: 0,
          chakraCost: 10,
          cooldown: 1,
          range: 1,
          element: ElementalNature.WIND,
          animation: 'chakra_shield',
          effects: [{ type: 'buff', value: 50, target: 'self', duration: 3 }]
        },
        grab: {
          name: 'Shadow Clone Grab',
          description: 'Grab with shadow clone assistance',
          damage: 10,
          chakraCost: 8,
          cooldown: 1.5,
          range: 2,
          element: ElementalNature.WIND,
          animation: 'clone_grab',
          effects: [{ type: 'damage', value: 10, target: 'enemy' }]
        },
        jump: {
          name: 'Chakra Jump',
          description: 'Enhanced jump using chakra',
          damage: 0,
          chakraCost: 5,
          cooldown: 0.3,
          range: 0,
          element: ElementalNature.WIND,
          animation: 'chakra_jump',
          effects: [{ type: 'buff', value: 30, target: 'self', duration: 1 }]
        },
        forwardAttack: {
          name: 'Shadow Clone Rush',
          description: 'Forward dash with shadow clones',
          damage: 25,
          chakraCost: 15,
          cooldown: 1.5,
          range: 4,
          element: ElementalNature.WIND,
          animation: 'clone_rush',
          effects: [{ type: 'damage', value: 25, target: 'enemy' }],
          direction: 'forward',
          knockback: 30,
          launchAngle: 15
        },
        backAttack: {
          name: 'Reverse Shadow Clone',
          description: 'Backward strike with shadow clone',
          damage: 20,
          chakraCost: 12,
          cooldown: 1.2,
          range: 3,
          element: ElementalNature.WIND,
          animation: 'reverse_clone',
          effects: [{ type: 'damage', value: 20, target: 'enemy' }],
          direction: 'back',
          knockback: 25,
          launchAngle: -15
        },
        upAttack: {
          name: 'Uppercut Clone',
          description: 'Upward strike with shadow clone',
          damage: 22,
          chakraCost: 10,
          cooldown: 1,
          range: 3,
          element: ElementalNature.WIND,
          animation: 'uppercut_clone',
          effects: [{ type: 'damage', value: 22, target: 'enemy' }],
          direction: 'up',
          knockback: 40,
          launchAngle: 90
        },
        downAttack: {
          name: 'Ground Pound Clone',
          description: 'Downward strike with shadow clone',
          damage: 18,
          chakraCost: 8,
          cooldown: 0.8,
          range: 2,
          element: ElementalNature.WIND,
          animation: 'ground_pound_clone',
          effects: [{ type: 'damage', value: 18, target: 'enemy' }],
          direction: 'down',
          knockback: 20,
          launchAngle: -90
        },
        forwardSpecial: {
          name: 'Wind Style: Rasenshuriken',
          description: 'Spinning wind attack that cuts through everything',
          damage: 60,
          chakraCost: 40,
          cooldown: 4,
          range: 6,
          element: ElementalNature.WIND,
          animation: 'rasenshuriken_throw',
          effects: [{ type: 'damage', value: 60, target: 'enemy' }, { type: 'knockback', value: 80, target: 'enemy' }],
          direction: 'forward',
          knockback: 80,
          launchAngle: 0
        },
        backSpecial: {
          name: 'Shadow Clone Explosion',
          description: 'Explosive shadow clone retreat',
          damage: 30,
          chakraCost: 25,
          cooldown: 3,
          range: 4,
          element: ElementalNature.WIND,
          animation: 'clone_explosion',
          effects: [{ type: 'damage', value: 30, target: 'enemy' }],
          direction: 'back',
          knockback: 50,
          launchAngle: 180
        },
        upSpecial: {
          name: 'Chakra Jump Boost',
          description: 'Enhanced upward movement with chakra',
          damage: 0,
          chakraCost: 15,
          cooldown: 2,
          range: 0,
          element: ElementalNature.WIND,
          animation: 'chakra_boost',
          effects: [{ type: 'buff', value: 50, target: 'self', duration: 2 }],
          direction: 'up',
          knockback: 0,
          launchAngle: 90
        },
        downSpecial: {
          name: 'Earth Style: Underground Movement',
          description: 'Dive underground and emerge elsewhere',
          damage: 20,
          chakraCost: 20,
          cooldown: 3,
          range: 5,
          element: ElementalNature.EARTH,
          animation: 'underground_movement',
          effects: [{ type: 'damage', value: 20, target: 'enemy' }],
          direction: 'down',
          knockback: 30,
          launchAngle: 0
        },
        aerialAttack: {
          name: 'Aerial Shadow Clone',
          description: 'Aerial attack with shadow clone',
          damage: 20,
          chakraCost: 10,
          cooldown: 1,
          range: 3,
          element: ElementalNature.WIND,
          animation: 'aerial_clone',
          effects: [{ type: 'damage', value: 20, target: 'enemy' }],
          aerialType: 'neutral',
          fallSpeed: 0,
          recovery: 0.5
        },
        aerialSpecial: {
          name: 'Aerial Rasengan',
          description: 'Rasengan while airborne',
          damage: 30,
          chakraCost: 20,
          cooldown: 2,
          range: 3,
          element: ElementalNature.WIND,
          animation: 'aerial_rasengan',
          effects: [{ type: 'damage', value: 30, target: 'enemy' }],
          aerialType: 'neutral',
          fallSpeed: 0,
          recovery: 1
        },
        chargedAttack: {
          name: 'Charged Shadow Clone Army',
          description: 'Multiple shadow clones with charge',
          damage: 45,
          chakraCost: 30,
          cooldown: 3,
          range: 5,
          element: ElementalNature.WIND,
          animation: 'charged_clone_army',
          effects: [{ type: 'damage', value: 45, target: 'enemy' }],
          chargeTime: 2,
          maxCharge: 3,
          chargeMultiplier: 1.5,
          visualEffect: 'clone_army_charge'
        },
        chargedSpecial: {
          name: 'Charged Rasenshuriken',
          description: 'More powerful Rasenshuriken with charge',
          damage: 80,
          chakraCost: 50,
          cooldown: 5,
          range: 8,
          element: ElementalNature.WIND,
          animation: 'charged_rasenshuriken',
          effects: [{ type: 'damage', value: 80, target: 'enemy' }],
          chargeTime: 3,
          maxCharge: 4,
          chargeMultiplier: 2,
          visualEffect: 'rasenshuriken_charge'
        }
      },
      combos: [
        {
          id: 'naruto_combo_1',
          name: 'Shadow Clone Combo',
          description: 'Basic shadow clone combination',
          inputs: [
            { button: 'attack', direction: 'forward', timing: 0 },
            { button: 'attack', direction: 'neutral', timing: 300 },
            { button: 'special', direction: 'forward', timing: 600 }
          ],
          damage: 50,
          chakraCost: 25,
          element: ElementalNature.WIND,
          requirements: [],
          effects: [{ type: 'damage', value: 50, target: 'enemy' }]
        },
        {
          id: 'naruto_combo_2',
          name: 'Rasengan Combo',
          description: 'Advanced Rasengan combination',
          inputs: [
            { button: 'attack', direction: 'forward', timing: 0 },
            { button: 'special', direction: 'neutral', timing: 200 },
            { button: 'special', direction: 'forward', timing: 400 }
          ],
          damage: 70,
          chakraCost: 40,
          element: ElementalNature.WIND,
          requirements: [{ type: 'chakra', value: 40, operator: 'greater' }],
          effects: [{ type: 'damage', value: 70, target: 'enemy' }]
        }
      ],
      superMoves: [
        {
          id: 'naruto_super_1',
          name: 'Sage Mode: Massive Rasengan',
          description: 'Ultimate Rasengan in Sage Mode',
          damage: 120,
          chakraCost: 80,
          element: ElementalNature.WIND,
          requirements: [{ type: 'chakra', value: 80, operator: 'greater' }],
          effects: [{ type: 'damage', value: 120, target: 'enemy' }],
          animation: 'sage_mode_rasengan',
          inspiration: 'Naruto - Sage Mode Rasengan'
        },
        {
          id: 'naruto_super_2',
          name: 'Nine-Tails Chakra Mode',
          description: 'Transform into Nine-Tails chakra mode',
          damage: 0,
          chakraCost: 60,
          element: ElementalNature.WIND,
          requirements: [{ type: 'health', value: 30, operator: 'less' }],
          effects: [{ type: 'buff', value: 100, target: 'self', duration: 10 }],
          animation: 'nine_tails_mode',
          inspiration: 'Naruto - Nine-Tails Chakra Mode'
        }
      ],
      chargeAttacks: [
        {
          id: 'naruto_charge_1',
          name: 'Charged Shadow Clone Army',
          description: 'Multiple shadow clones with charge',
          chargeTime: 3,
          damage: 60,
          chakraCost: 40,
          element: ElementalNature.WIND,
          effects: [{ type: 'damage', value: 60, target: 'enemy' }],
          inspiration: 'Naruto - Shadow Clone Jutsu'
        }
      ]
    };
  }

  private createDragonBallFighter(): Fighter {
    return {
      id: 'goku',
      name: 'Son Goku',
      element: ElementalNature.LIGHTNING,
      stats: {
        health: 100,
        maxHealth: 100,
        chakra: 100,
        maxChakra: 100,
        speed: 95,
        power: 100,
        defense: 80,
        agility: 100,
        elementalAffinity: 95
      },
      moves: {
        attack: {
          name: 'Ki Punch',
          description: 'Basic ki-enhanced punch',
          damage: 18,
          chakraCost: 5,
          cooldown: 0.4,
          range: 2,
          element: ElementalNature.LIGHTNING,
          animation: 'ki_punch',
          effects: [{ type: 'damage', value: 18, target: 'enemy' }]
        },
        special: {
          name: 'Kamehameha',
          description: 'Classic energy wave attack',
          damage: 40,
          chakraCost: 25,
          cooldown: 2.5,
          range: 8,
          element: ElementalNature.LIGHTNING,
          animation: 'kamehameha_charge',
          effects: [{ type: 'damage', value: 40, target: 'enemy' }, { type: 'knockback', value: 60, target: 'enemy' }]
        },
        shield: {
          name: 'Ki Barrier',
          description: 'Defensive ki barrier',
          damage: 0,
          chakraCost: 12,
          cooldown: 1.2,
          range: 1,
          element: ElementalNature.LIGHTNING,
          animation: 'ki_barrier',
          effects: [{ type: 'buff', value: 60, target: 'self', duration: 3 }]
        },
        grab: {
          name: 'Ki Grab',
          description: 'Grab enhanced with ki',
          damage: 12,
          chakraCost: 8,
          cooldown: 1.5,
          range: 2,
          element: ElementalNature.LIGHTNING,
          animation: 'ki_grab',
          effects: [{ type: 'damage', value: 12, target: 'enemy' }]
        },
        jump: {
          name: 'Ki Flight',
          description: 'Enhanced jump using ki',
          damage: 0,
          chakraCost: 8,
          cooldown: 0.5,
          range: 0,
          element: ElementalNature.LIGHTNING,
          animation: 'ki_flight',
          effects: [{ type: 'buff', value: 40, target: 'self', duration: 1.5 }]
        },
        forwardAttack: {
          name: 'Dragon Fist',
          description: 'Forward ki-enhanced punch',
          damage: 30,
          chakraCost: 15,
          cooldown: 1.5,
          range: 4,
          element: ElementalNature.LIGHTNING,
          animation: 'dragon_fist',
          effects: [{ type: 'damage', value: 30, target: 'enemy' }],
          direction: 'forward',
          knockback: 40,
          launchAngle: 0
        },
        backAttack: {
          name: 'Reverse Ki Blast',
          description: 'Backward ki energy blast',
          damage: 25,
          chakraCost: 12,
          cooldown: 1.2,
          range: 3,
          element: ElementalNature.LIGHTNING,
          animation: 'reverse_ki_blast',
          effects: [{ type: 'damage', value: 25, target: 'enemy' }],
          direction: 'back',
          knockback: 35,
          launchAngle: 180
        },
        upAttack: {
          name: 'Rising Dragon',
          description: 'Upward ki-enhanced strike',
          damage: 28,
          chakraCost: 12,
          cooldown: 1.2,
          range: 3,
          element: ElementalNature.LIGHTNING,
          animation: 'rising_dragon',
          effects: [{ type: 'damage', value: 28, target: 'enemy' }],
          direction: 'up',
          knockback: 50,
          launchAngle: 90
        },
        downAttack: {
          name: 'Earth Splitter',
          description: 'Downward ki strike',
          damage: 22,
          chakraCost: 10,
          cooldown: 1,
          range: 2,
          element: ElementalNature.LIGHTNING,
          animation: 'earth_splitter',
          effects: [{ type: 'damage', value: 22, target: 'enemy' }],
          direction: 'down',
          knockback: 30,
          launchAngle: -90
        },
        forwardSpecial: {
          name: 'Super Kamehameha',
          description: 'Enhanced Kamehameha wave',
          damage: 70,
          chakraCost: 50,
          cooldown: 4,
          range: 10,
          element: ElementalNature.LIGHTNING,
          animation: 'super_kamehameha',
          effects: [{ type: 'damage', value: 70, target: 'enemy' }, { type: 'knockback', value: 100, target: 'enemy' }],
          direction: 'forward',
          knockback: 100,
          launchAngle: 0
        },
        backSpecial: {
          name: 'Instant Transmission',
          description: 'Teleport behind enemy and strike',
          damage: 35,
          chakraCost: 30,
          cooldown: 3,
          range: 6,
          element: ElementalNature.LIGHTNING,
          animation: 'instant_transmission',
          effects: [{ type: 'damage', value: 35, target: 'enemy' }],
          direction: 'back',
          knockback: 45,
          launchAngle: 180
        },
        upSpecial: {
          name: 'Ki Flight Boost',
          description: 'Enhanced upward ki movement',
          damage: 0,
          chakraCost: 20,
          cooldown: 2.5,
          range: 0,
          element: ElementalNature.LIGHTNING,
          animation: 'ki_flight_boost',
          effects: [{ type: 'buff', value: 80, target: 'self', duration: 2 }],
          direction: 'up',
          knockback: 0,
          launchAngle: 90
        },
        downSpecial: {
          name: 'Ground Pound Ki',
          description: 'Downward ki energy strike',
          damage: 40,
          chakraCost: 25,
          cooldown: 3,
          range: 4,
          element: ElementalNature.LIGHTNING,
          animation: 'ground_pound_ki',
          effects: [{ type: 'damage', value: 40, target: 'enemy' }],
          direction: 'down',
          knockback: 60,
          launchAngle: -90
        },
        aerialAttack: {
          name: 'Aerial Ki Strike',
          description: 'Aerial ki-enhanced attack',
          damage: 25,
          chakraCost: 12,
          cooldown: 1.2,
          range: 3,
          element: ElementalNature.LIGHTNING,
          animation: 'aerial_ki_strike',
          effects: [{ type: 'damage', value: 25, target: 'enemy' }],
          aerialType: 'neutral',
          fallSpeed: 0,
          recovery: 0.8
        },
        aerialSpecial: {
          name: 'Aerial Kamehameha',
          description: 'Kamehameha while airborne',
          damage: 35,
          chakraCost: 25,
          cooldown: 2.5,
          range: 6,
          element: ElementalNature.LIGHTNING,
          animation: 'aerial_kamehameha',
          effects: [{ type: 'damage', value: 35, target: 'enemy' }],
          aerialType: 'neutral',
          fallSpeed: 0,
          recovery: 1.5
        },
        chargedAttack: {
          name: 'Charged Ki Blast',
          description: 'Charged ki energy blast',
          damage: 50,
          chakraCost: 35,
          cooldown: 3,
          range: 6,
          element: ElementalNature.LIGHTNING,
          animation: 'charged_ki_blast',
          effects: [{ type: 'damage', value: 50, target: 'enemy' }],
          chargeTime: 2,
          maxCharge: 3,
          chargeMultiplier: 1.8,
          visualEffect: 'ki_charge'
        },
        chargedSpecial: {
          name: 'Charged Kamehameha',
          description: 'Fully charged Kamehameha',
          damage: 90,
          chakraCost: 60,
          cooldown: 5,
          range: 12,
          element: ElementalNature.LIGHTNING,
          animation: 'charged_kamehameha',
          effects: [{ type: 'damage', value: 90, target: 'enemy' }],
          chargeTime: 3,
          maxCharge: 4,
          chargeMultiplier: 2.5,
          visualEffect: 'kamehameha_charge'
        }
      },
      combos: [
        {
          id: 'goku_combo_1',
          name: 'Ki Combo',
          description: 'Basic ki combination',
          inputs: [
            { button: 'attack', direction: 'forward', timing: 0 },
            { button: 'attack', direction: 'neutral', timing: 200 },
            { button: 'special', direction: 'forward', timing: 400 }
          ],
          damage: 60,
          chakraCost: 30,
          element: ElementalNature.LIGHTNING,
          requirements: [],
          effects: [{ type: 'damage', value: 60, target: 'enemy' }]
        },
        {
          id: 'goku_combo_2',
          name: 'Dragon Combo',
          description: 'Advanced ki combination',
          inputs: [
            { button: 'attack', direction: 'forward', timing: 0 },
            { button: 'special', direction: 'up', timing: 300 },
            { button: 'special', direction: 'down', timing: 600 }
          ],
          damage: 80,
          chakraCost: 45,
          element: ElementalNature.LIGHTNING,
          requirements: [{ type: 'chakra', value: 45, operator: 'greater' }],
          effects: [{ type: 'damage', value: 80, target: 'enemy' }]
        }
      ],
      superMoves: [
        {
          id: 'goku_super_1',
          name: 'Super Saiyan Transformation',
          description: 'Transform into Super Saiyan',
          damage: 0,
          chakraCost: 70,
          element: ElementalNature.LIGHTNING,
          requirements: [{ type: 'health', value: 50, operator: 'less' }],
          effects: [{ type: 'buff', value: 150, target: 'self', duration: 15 }],
          animation: 'super_saiyan_transform',
          inspiration: 'Dragon Ball Z - Super Saiyan Transformation'
        },
        {
          id: 'goku_super_2',
          name: 'Spirit Bomb',
          description: 'Ultimate energy attack',
          damage: 150,
          chakraCost: 100,
          element: ElementalNature.LIGHTNING,
          requirements: [{ type: 'chakra', value: 100, operator: 'greater' }],
          effects: [{ type: 'damage', value: 150, target: 'enemy' }],
          animation: 'spirit_bomb',
          inspiration: 'Dragon Ball Z - Spirit Bomb'
        }
      ],
      chargeAttacks: [
        {
          id: 'goku_charge_1',
          name: 'Charged Kamehameha',
          description: 'Fully charged Kamehameha',
          chargeTime: 4,
          damage: 100,
          chakraCost: 70,
          element: ElementalNature.LIGHTNING,
          effects: [{ type: 'damage', value: 100, target: 'enemy' }],
          inspiration: 'Dragon Ball Z - Kamehameha'
        }
      ]
    };
  }

  // Additional fighters would be created here...
  private createOnePieceFighter(): Fighter {
    // Luffy with Gum-Gum Fruit powers
    return {
      id: 'luffy',
      name: 'Monkey D. Luffy',
      element: ElementalNature.RUBBER, // Custom element
      stats: {
        health: 100,
        maxHealth: 100,
        chakra: 100,
        maxChakra: 100,
        speed: 90,
        power: 95,
        defense: 85,
        agility: 90,
        elementalAffinity: 85
      },
      moves: {
        attack: {
          name: 'Gum-Gum Pistol',
          description: 'Basic rubber punch',
          damage: 20,
          chakraCost: 5,
          cooldown: 0.5,
          range: 3,
          element: ElementalNature.RUBBER,
          animation: 'gum_gum_pistol',
          effects: [{ type: 'damage', value: 20, target: 'enemy' }]
        },
        special: {
          name: 'Gum-Gum Bazooka',
          description: 'Double rubber punch',
          damage: 45,
          chakraCost: 25,
          cooldown: 2,
          range: 5,
          element: ElementalNature.RUBBER,
          animation: 'gum_gum_bazooka',
          effects: [{ type: 'damage', value: 45, target: 'enemy' }, { type: 'knockback', value: 70, target: 'enemy' }]
        },
        // ... other moves
      },
      // ... rest of fighter data
    };
  }

  private createBleachFighter(): Fighter {
    // Ichigo with Zanpakuto powers
    return {
      id: 'ichigo',
      name: 'Ichigo Kurosaki',
      element: ElementalNature.SHADOW,
      stats: {
        health: 100,
        maxHealth: 100,
        chakra: 100,
        maxChakra: 100,
        speed: 95,
        power: 90,
        defense: 80,
        agility: 95,
        elementalAffinity: 90
      },
      moves: {
        attack: {
          name: 'Zanpakuto Slash',
          description: 'Basic sword strike',
          damage: 22,
          chakraCost: 5,
          cooldown: 0.4,
          range: 2,
          element: ElementalNature.SHADOW,
          animation: 'zanpakuto_slash',
          effects: [{ type: 'damage', value: 22, target: 'enemy' }]
        },
        special: {
          name: 'Getsuga Tensho',
          description: 'Energy wave slash',
          damage: 50,
          chakraCost: 30,
          cooldown: 2.5,
          range: 6,
          element: ElementalNature.SHADOW,
          animation: 'getsuga_tensho',
          effects: [{ type: 'damage', value: 50, target: 'enemy' }, { type: 'knockback', value: 80, target: 'enemy' }]
        },
        // ... other moves
      },
      // ... rest of fighter data
    };
  }

  private createDemonSlayerFighter(): Fighter {
    // Tanjiro with Breathing Techniques
    return {
      id: 'tanjiro',
      name: 'Tanjiro Kamado',
      element: ElementalNature.WATER,
      stats: {
        health: 100,
        maxHealth: 100,
        chakra: 100,
        maxChakra: 100,
        speed: 90,
        power: 85,
        defense: 80,
        agility: 95,
        elementalAffinity: 85
      },
      moves: {
        attack: {
          name: 'Water Breathing Slash',
          description: 'Basic water-enhanced sword strike',
          damage: 20,
          chakraCost: 5,
          cooldown: 0.5,
          range: 2,
          element: ElementalNature.WATER,
          animation: 'water_breathing_slash',
          effects: [{ type: 'damage', value: 20, target: 'enemy' }]
        },
        special: {
          name: 'Water Breathing: First Form',
          description: 'Water dragon slash',
          damage: 40,
          chakraCost: 25,
          cooldown: 2,
          range: 4,
          element: ElementalNature.WATER,
          animation: 'water_dragon_slash',
          effects: [{ type: 'damage', value: 40, target: 'enemy' }, { type: 'knockback', value: 60, target: 'enemy' }]
        },
        // ... other moves
      },
      // ... rest of fighter data
    };
  }

  private createAttackOnTitanFighter(): Fighter {
    // Eren with Titan powers
    return {
      id: 'eren',
      name: 'Eren Yeager',
      element: ElementalNature.EARTH,
      stats: {
        health: 100,
        maxHealth: 100,
        chakra: 100,
        maxChakra: 100,
        speed: 85,
        power: 100,
        defense: 95,
        agility: 80,
        elementalAffinity: 90
      },
      moves: {
        attack: {
          name: 'Titan Punch',
          description: 'Massive titan fist strike',
          damage: 35,
          chakraCost: 10,
          cooldown: 1,
          range: 4,
          element: ElementalNature.EARTH,
          animation: 'titan_punch',
          effects: [{ type: 'damage', value: 35, target: 'enemy' }]
        },
        special: {
          name: 'Titan Transformation',
          description: 'Transform into Attack Titan',
          damage: 0,
          chakraCost: 50,
          cooldown: 5,
          range: 0,
          element: ElementalNature.EARTH,
          animation: 'titan_transform',
          effects: [{ type: 'buff', value: 200, target: 'self', duration: 20 }]
        },
        // ... other moves
      },
      // ... rest of fighter data
    };
  }

  private createMyHeroAcademiaFighter(): Fighter {
    // Deku with One For All
    return {
      id: 'deku',
      name: 'Izuku Midoriya',
      element: ElementalNature.LIGHTNING,
      stats: {
        health: 100,
        maxHealth: 100,
        chakra: 100,
        maxChakra: 100,
        speed: 90,
        power: 95,
        defense: 75,
        agility: 95,
        elementalAffinity: 90
      },
      moves: {
        attack: {
          name: 'One For All Punch',
          description: 'Basic One For All enhanced punch',
          damage: 25,
          chakraCost: 8,
          cooldown: 0.6,
          range: 3,
          element: ElementalNature.LIGHTNING,
          animation: 'one_for_all_punch',
          effects: [{ type: 'damage', value: 25, target: 'enemy' }]
        },
        special: {
          name: 'Delaware Smash',
          description: 'Finger flick air pressure attack',
          damage: 35,
          chakraCost: 20,
          cooldown: 2,
          range: 5,
          element: ElementalNature.LIGHTNING,
          animation: 'delaware_smash',
          effects: [{ type: 'damage', value: 35, target: 'enemy' }, { type: 'knockback', value: 70, target: 'enemy' }]
        },
        // ... other moves
      },
      // ... rest of fighter data
    };
  }

  private createJujutsuKaisenFighter(): Fighter {
    // Yuji with Cursed Energy
    return {
      id: 'yuji',
      name: 'Yuji Itadori',
      element: ElementalNature.CURSE, // Custom element
      stats: {
        health: 100,
        maxHealth: 100,
        chakra: 100,
        maxChakra: 100,
        speed: 90,
        power: 90,
        defense: 85,
        agility: 90,
        elementalAffinity: 85
      },
      moves: {
        attack: {
          name: 'Cursed Energy Punch',
          description: 'Basic cursed energy enhanced punch',
          damage: 22,
          chakraCost: 6,
          cooldown: 0.5,
          range: 2,
          element: ElementalNature.CURSE,
          animation: 'cursed_energy_punch',
          effects: [{ type: 'damage', value: 22, target: 'enemy' }]
        },
        special: {
          name: 'Divergent Fist',
          description: 'Delayed cursed energy attack',
          damage: 40,
          chakraCost: 25,
          cooldown: 2.5,
          range: 4,
          element: ElementalNature.CURSE,
          animation: 'divergent_fist',
          effects: [{ type: 'damage', value: 40, target: 'enemy' }, { type: 'damage', value: 20, target: 'enemy', duration: 1 }]
        },
        // ... other moves
      },
      // ... rest of fighter data
    };
  }
}

export class ComboSystem {
  private activeCombos: Map<string, ComboState> = new Map();
  private comboDatabase: Map<string, Combo> = new Map();

  constructor() {
    this.initializeComboDatabase();
  }

  private initializeComboDatabase() {
    // Initialize combo database with various anime-inspired combinations
    this.comboDatabase.set('naruto_combo_1', {
      id: 'naruto_combo_1',
      name: 'Shadow Clone Combo',
      description: 'Basic shadow clone combination',
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'attack', direction: 'neutral', timing: 300 },
        { button: 'special', direction: 'forward', timing: 600 }
      ],
      damage: 50,
      chakraCost: 25,
      element: ElementalNature.WIND,
      requirements: [],
      effects: [{ type: 'damage', value: 50, target: 'enemy' }]
    });

    this.comboDatabase.set('goku_combo_1', {
      id: 'goku_combo_1',
      name: 'Ki Combo',
      description: 'Basic ki combination',
      inputs: [
        { button: 'attack', direction: 'forward', timing: 0 },
        { button: 'attack', direction: 'neutral', timing: 200 },
        { button: 'special', direction: 'forward', timing: 400 }
      ],
      damage: 60,
      chakraCost: 30,
      element: ElementalNature.LIGHTNING,
      requirements: [],
      effects: [{ type: 'damage', value: 60, target: 'enemy' }]
    });

    // Add more combos...
  }

  public processInput(fighterId: string, input: ComboInput): ComboResult {
    const fighter = this.activeCombos.get(fighterId);
    if (!fighter) {
      this.activeCombos.set(fighterId, {
        currentCombo: null,
        inputSequence: [],
        lastInputTime: Date.now(),
        comboProgress: 0
      });
    }

    const comboState = this.activeCombos.get(fighterId)!;
    const currentTime = Date.now();
    const timeSinceLastInput = currentTime - comboState.lastInputTime;

    // Check if input matches any combo sequence
    for (const [comboId, combo] of this.comboDatabase) {
      if (this.checkComboInput(combo, input, comboState, timeSinceLastInput)) {
        comboState.comboProgress++;
        comboState.lastInputTime = currentTime;

        if (comboState.comboProgress >= combo.inputs.length) {
          // Combo completed!
          comboState.comboProgress = 0;
          comboState.inputSequence = [];
          return {
            success: true,
            combo: combo,
            damage: combo.damage,
            effects: combo.effects
          };
        }
      }
    }

    return { success: false };
  }

  private checkComboInput(combo: Combo, input: ComboInput, comboState: ComboState, timeSinceLastInput: number): boolean {
    const expectedInput = combo.inputs[comboState.comboProgress];
    if (!expectedInput) return false;

    // Check button match
    if (expectedInput.button !== input.button) return false;

    // Check direction match
    if (expectedInput.direction && expectedInput.direction !== input.direction) return false;

    // Check timing match (with some tolerance)
    const timingTolerance = 100; // milliseconds
    const expectedTiming = expectedInput.timing;
    const actualTiming = timeSinceLastInput;

    if (Math.abs(actualTiming - expectedTiming) > timingTolerance) return false;

    return true;
  }
}

export class ElementalSystem {
  private elementalInteractions: Map<string, ElementalInteraction> = new Map();

  constructor() {
    this.initializeElementalInteractions();
  }

  private initializeElementalInteractions() {
    // Fire beats Ice, Ice beats Water, Water beats Fire
    this.elementalInteractions.set('fire_vs_ice', {
      attacker: ElementalNature.FIRE,
      defender: ElementalNature.ICE,
      multiplier: 1.5,
      description: 'Fire melts ice'
    });

    this.elementalInteractions.set('ice_vs_water', {
      attacker: ElementalNature.ICE,
      defender: ElementalNature.WATER,
      multiplier: 1.5,
      description: 'Ice freezes water'
    });

    this.elementalInteractions.set('water_vs_fire', {
      attacker: ElementalNature.WATER,
      defender: ElementalNature.FIRE,
      multiplier: 1.5,
      description: 'Water extinguishes fire'
    });

    // Lightning beats Water, Earth beats Lightning
    this.elementalInteractions.set('lightning_vs_water', {
      attacker: ElementalNature.LIGHTNING,
      defender: ElementalNature.WATER,
      multiplier: 1.5,
      description: 'Lightning conducts through water'
    });

    this.elementalInteractions.set('earth_vs_lightning', {
      attacker: ElementalNature.EARTH,
      defender: ElementalNature.LIGHTNING,
      multiplier: 1.5,
      description: 'Earth grounds lightning'
    });

    // Add more elemental interactions...
  }

  public calculateElementalDamage(attackerElement: ElementalNature, defenderElement: ElementalNature, baseDamage: number): number {
    const interactionKey = `${attackerElement}_vs_${defenderElement}`;
    const interaction = this.elementalInteractions.get(interactionKey);
    
    if (interaction) {
      return baseDamage * interaction.multiplier;
    }

    return baseDamage;
  }
}

export class MoveInspirationDatabase {
  private inspirations: Map<string, MoveInspiration> = new Map();

  constructor() {
    this.initializeInspirations();
  }

  private initializeInspirations() {
    // Naruto inspirations
    this.inspirations.set('rasengan', {
      anime: 'Naruto',
      character: 'Naruto Uzumaki',
      technique: 'Rasengan',
      description: 'Spinning chakra sphere attack',
      powerLevel: 8,
      popularity: 9
    });

    this.inspirations.set('kamehameha', {
      anime: 'Dragon Ball Z',
      character: 'Son Goku',
      technique: 'Kamehameha',
      description: 'Energy wave attack',
      powerLevel: 9,
      popularity: 10
    });

    this.inspirations.set('getsuga_tensho', {
      anime: 'Bleach',
      character: 'Ichigo Kurosaki',
      technique: 'Getsuga Tensho',
      description: 'Energy wave slash',
      powerLevel: 8,
      popularity: 8
    });

    this.inspirations.set('gum_gum_pistol', {
      anime: 'One Piece',
      character: 'Monkey D. Luffy',
      technique: 'Gum-Gum Pistol',
      description: 'Rubber punch attack',
      powerLevel: 7,
      popularity: 9
    });

    this.inspirations.set('water_breathing', {
      anime: 'Demon Slayer',
      character: 'Tanjiro Kamado',
      technique: 'Water Breathing',
      description: 'Water-enhanced sword techniques',
      powerLevel: 7,
      popularity: 8
    });

    this.inspirations.set('one_for_all', {
      anime: 'My Hero Academia',
      character: 'Izuku Midoriya',
      technique: 'One For All',
      description: 'Superhuman strength quirk',
      powerLevel: 9,
      popularity: 9
    });

    this.inspirations.set('cursed_energy', {
      anime: 'Jujutsu Kaisen',
      character: 'Yuji Itadori',
      technique: 'Cursed Energy',
      description: 'Supernatural energy manipulation',
      powerLevel: 8,
      popularity: 8
    });

    // Add more inspirations...
  }

  public getInspiration(techniqueId: string): MoveInspiration | undefined {
    return this.inspirations.get(techniqueId);
  }

  public getAllInspirations(): MoveInspiration[] {
    return Array.from(this.inspirations.values());
  }
}

// Supporting interfaces and types
interface FighterState {
  currentCombo: Combo | null;
  inputSequence: ComboInput[];
  lastInputTime: number;
  comboProgress: number;
}

interface ComboResult {
  success: boolean;
  combo?: Combo;
  damage?: number;
  effects?: MoveEffect[];
}

interface ElementalInteraction {
  attacker: ElementalNature;
  defender: ElementalNature;
  multiplier: number;
  description: string;
}

interface MoveInspiration {
  anime: string;
  character: string;
  technique: string;
  description: string;
  powerLevel: number; // 1-10
  popularity: number; // 1-10
}

// Custom elements for unique fighters
enum CustomElementalNature {
  RUBBER = 'rubber',
  CURSE = 'curse',
  QUIRK = 'quirk',
  BREATHING = 'breathing',
  TITAN = 'titan'
}

export { CustomElementalNature };

