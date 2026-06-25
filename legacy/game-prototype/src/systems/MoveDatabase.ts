/**
 * Anime Aggressors Move Database
 * Original moves inspired by the most beloved and powerful techniques from across all anime
 * Each move is unique to Anime Aggressors while drawing inspiration from fan-favorite techniques
 */

import { ElementalNature } from './FightingSystem';

export interface MoveDatabase {
  [key: string]: MoveEntry;
}

export interface MoveEntry {
  id: string;
  name: string;
  description: string;
  inspiration: {
    anime: string;
    character: string;
    technique: string;
    description: string;
    powerLevel: number; // 1-10
    popularity: number; // 1-10
  };
  move: {
    type: 'attack' | 'special' | 'shield' | 'grab' | 'jump';
    direction: 'forward' | 'back' | 'up' | 'down' | 'neutral';
    damage: number;
    chakraCost: number;
    cooldown: number;
    range: number;
    element: ElementalNature;
    effects: MoveEffect[];
    animation: string;
    visualEffects: string[];
  };
  combo: {
    inputs: ComboInput[];
    damage: number;
    chakraCost: number;
    element: ElementalNature;
    requirements: ComboRequirement[];
    effects: MoveEffect[];
  };
  superMove: {
    name: string;
    description: string;
    damage: number;
    chakraCost: number;
    element: ElementalNature;
    requirements: SuperMoveRequirement[];
    effects: MoveEffect[];
    animation: string;
    inspiration: string;
  };
  chargeAttack: {
    name: string;
    description: string;
    chargeTime: number;
    damage: number;
    chakraCost: number;
    element: ElementalNature;
    effects: MoveEffect[];
    inspiration: string;
  };
}

export interface MoveEffect {
  type: 'damage' | 'heal' | 'buff' | 'debuff' | 'status' | 'knockback' | 'launch' | 'elemental';
  value: number;
  duration?: number;
  target: 'self' | 'enemy' | 'area';
  element?: ElementalNature;
}

export interface ComboInput {
  button: 'attack' | 'special' | 'shield' | 'grab' | 'jump';
  direction?: 'forward' | 'back' | 'up' | 'down' | 'neutral';
  timing: number; // milliseconds between inputs
  hold?: boolean;
}

export interface ComboRequirement {
  type: 'health' | 'chakra' | 'element' | 'position' | 'previous_move';
  value: number | ElementalNature;
  operator: 'greater' | 'less' | 'equal';
}

export interface SuperMoveRequirement {
  type: 'chakra' | 'health' | 'combo_count' | 'element_affinity';
  value: number;
  operator: 'greater' | 'less' | 'equal';
}

export class MoveDatabaseManager {
  private moveDatabase: MoveDatabase = {};
  private elementalMoves: Map<ElementalNature, MoveEntry[]> = new Map();
  private animeMoves: Map<string, MoveEntry[]> = new Map();
  private powerLevelMoves: Map<number, MoveEntry[]> = new Map();

  constructor() {
    this.initializeMoveDatabase();
    this.organizeMoves();
  }

  private initializeMoveDatabase(): void {
    // NARUTO INSPIRED MOVES
    this.moveDatabase['shadow_clone_strike'] = {
      id: 'shadow_clone_strike',
      name: 'Shadow Clone Strike',
      description: 'Basic punch with shadow clone assistance - inspired by Naruto\'s signature technique',
      inspiration: {
        anime: 'Naruto',
        character: 'Naruto Uzumaki',
        technique: 'Shadow Clone Jutsu',
        description: 'Creates multiple shadow clones to assist in combat',
        powerLevel: 7,
        popularity: 10
      },
      move: {
        type: 'attack',
        direction: 'neutral',
        damage: 18,
        chakraCost: 8,
        cooldown: 0.8,
        range: 2,
        element: ElementalNature.WIND,
        effects: [
          { type: 'damage', value: 18, target: 'enemy' },
          { type: 'elemental', value: 5, target: 'enemy', element: ElementalNature.WIND }
        ],
        animation: 'shadow_clone_punch',
        visualEffects: ['clone_appearance', 'wind_trail']
      },
      combo: {
        inputs: [
          { button: 'attack', direction: 'forward', timing: 0 },
          { button: 'attack', direction: 'neutral', timing: 300 },
          { button: 'special', direction: 'forward', timing: 600 }
        ],
        damage: 45,
        chakraCost: 20,
        element: ElementalNature.WIND,
        requirements: [],
        effects: [{ type: 'damage', value: 45, target: 'enemy' }]
      },
      superMove: {
        name: 'Shadow Clone Army Assault',
        description: 'Summon an army of shadow clones for a devastating attack',
        damage: 100,
        chakraCost: 70,
        element: ElementalNature.WIND,
        requirements: [{ type: 'chakra', value: 70, operator: 'greater' }],
        effects: [{ type: 'damage', value: 100, target: 'enemy' }],
        animation: 'shadow_clone_army',
        inspiration: 'Naruto - Shadow Clone Jutsu'
      },
      chargeAttack: {
        name: 'Charged Shadow Clone Barrage',
        description: 'Hold to charge up multiple shadow clones for a powerful attack',
        chargeTime: 2,
        damage: 60,
        chakraCost: 35,
        element: ElementalNature.WIND,
        effects: [{ type: 'damage', value: 60, target: 'enemy' }],
        inspiration: 'Naruto - Shadow Clone Jutsu'
      }
    };

    this.moveDatabase['rasengan_sphere'] = {
      id: 'rasengan_sphere',
      name: 'Rasengan Sphere',
      description: 'Spinning chakra sphere attack - inspired by Naruto\'s signature technique',
      inspiration: {
        anime: 'Naruto',
        character: 'Naruto Uzumaki',
        technique: 'Rasengan',
        description: 'Spinning chakra sphere that causes massive damage',
        powerLevel: 9,
        popularity: 10
      },
      move: {
        type: 'special',
        direction: 'forward',
        damage: 45,
        chakraCost: 25,
        cooldown: 2.5,
        range: 4,
        element: ElementalNature.WIND,
        effects: [
          { type: 'damage', value: 45, target: 'enemy' },
          { type: 'knockback', value: 60, target: 'enemy' },
          { type: 'elemental', value: 10, target: 'enemy', element: ElementalNature.WIND }
        ],
        animation: 'rasengan_charge',
        visualEffects: ['spinning_energy', 'wind_vortex']
      },
      combo: {
        inputs: [
          { button: 'attack', direction: 'forward', timing: 0 },
          { button: 'special', direction: 'forward', timing: 400 },
          { button: 'attack', direction: 'up', timing: 800 }
        ],
        damage: 70,
        chakraCost: 35,
        element: ElementalNature.WIND,
        requirements: [],
        effects: [{ type: 'damage', value: 70, target: 'enemy' }]
      },
      superMove: {
        name: 'Sage Mode: Massive Rasengan',
        description: 'Ultimate Rasengan in Sage Mode with enhanced power',
        damage: 120,
        chakraCost: 80,
        element: ElementalNature.WIND,
        requirements: [{ type: 'chakra', value: 80, operator: 'greater' }],
        effects: [{ type: 'damage', value: 120, target: 'enemy' }],
        animation: 'sage_mode_rasengan',
        inspiration: 'Naruto - Sage Mode Rasengan'
      },
      chargeAttack: {
        name: 'Charged Rasengan',
        description: 'Hold to charge up a more powerful Rasengan',
        chargeTime: 3,
        damage: 80,
        chakraCost: 45,
        element: ElementalNature.WIND,
        effects: [{ type: 'damage', value: 80, target: 'enemy' }],
        inspiration: 'Naruto - Rasengan'
      }
    };

    // DRAGON BALL Z INSPIRED MOVES
    this.moveDatabase['ki_blast_wave'] = {
      id: 'ki_blast_wave',
      name: 'Ki Blast Wave',
      description: 'Energy wave attack - inspired by Goku\'s signature technique',
      inspiration: {
        anime: 'Dragon Ball Z',
        character: 'Son Goku',
        technique: 'Kamehameha',
        description: 'Famous energy wave attack that can destroy planets',
        powerLevel: 10,
        popularity: 10
      },
      move: {
        type: 'special',
        direction: 'forward',
        damage: 50,
        chakraCost: 30,
        cooldown: 3,
        range: 8,
        element: ElementalNature.LIGHTNING,
        effects: [
          { type: 'damage', value: 50, target: 'enemy' },
          { type: 'knockback', value: 80, target: 'enemy' },
          { type: 'elemental', value: 15, target: 'enemy', element: ElementalNature.LIGHTNING }
        ],
        animation: 'kamehameha_charge',
        visualEffects: ['energy_charge', 'blue_energy_beam']
      },
      combo: {
        inputs: [
          { button: 'attack', direction: 'forward', timing: 0 },
          { button: 'special', direction: 'forward', timing: 300 },
          { button: 'attack', direction: 'up', timing: 600 }
        ],
        damage: 80,
        chakraCost: 40,
        element: ElementalNature.LIGHTNING,
        requirements: [],
        effects: [{ type: 'damage', value: 80, target: 'enemy' }]
      },
      superMove: {
        name: 'Super Saiyan Kamehameha',
        description: 'Ultimate Kamehameha in Super Saiyan form',
        damage: 150,
        chakraCost: 100,
        element: ElementalNature.LIGHTNING,
        requirements: [{ type: 'chakra', value: 100, operator: 'greater' }],
        effects: [{ type: 'damage', value: 150, target: 'enemy' }],
        animation: 'super_saiyan_kamehameha',
        inspiration: 'Dragon Ball Z - Super Saiyan Kamehameha'
      },
      chargeAttack: {
        name: 'Charged Kamehameha',
        description: 'Hold to charge up a more powerful Kamehameha',
        chargeTime: 4,
        damage: 100,
        chakraCost: 60,
        element: ElementalNature.LIGHTNING,
        effects: [{ type: 'damage', value: 100, target: 'enemy' }],
        inspiration: 'Dragon Ball Z - Kamehameha'
      }
    };

    this.moveDatabase['instant_transmission'] = {
      id: 'instant_transmission',
      name: 'Instant Transmission',
      description: 'Teleport behind enemy and strike - inspired by Goku\'s technique',
      inspiration: {
        anime: 'Dragon Ball Z',
        character: 'Son Goku',
        technique: 'Instant Transmission',
        description: 'Teleportation technique that allows instant movement',
        powerLevel: 8,
        popularity: 9
      },
      move: {
        type: 'special',
        direction: 'back',
        damage: 35,
        chakraCost: 25,
        cooldown: 3,
        range: 6,
        element: ElementalNature.LIGHTNING,
        effects: [
          { type: 'damage', value: 35, target: 'enemy' },
          { type: 'knockback', value: 50, target: 'enemy' }
        ],
        animation: 'instant_transmission',
        visualEffects: ['teleport_effect', 'lightning_flash']
      },
      combo: {
        inputs: [
          { button: 'special', direction: 'back', timing: 0 },
          { button: 'attack', direction: 'forward', timing: 200 },
          { button: 'special', direction: 'forward', timing: 500 }
        ],
        damage: 65,
        chakraCost: 40,
        element: ElementalNature.LIGHTNING,
        requirements: [],
        effects: [{ type: 'damage', value: 65, target: 'enemy' }]
      },
      superMove: {
        name: 'Super Saiyan Instant Transmission',
        description: 'Enhanced teleportation with Super Saiyan power',
        damage: 0,
        chakraCost: 50,
        element: ElementalNature.LIGHTNING,
        requirements: [{ type: 'chakra', value: 50, operator: 'greater' }],
        effects: [{ type: 'buff', value: 100, target: 'self', duration: 10 }],
        animation: 'super_saiyan_teleport',
        inspiration: 'Dragon Ball Z - Super Saiyan Instant Transmission'
      },
      chargeAttack: {
        name: 'Charged Teleport Strike',
        description: 'Hold to charge up a more powerful teleport attack',
        chargeTime: 2,
        damage: 55,
        chakraCost: 35,
        element: ElementalNature.LIGHTNING,
        effects: [{ type: 'damage', value: 55, target: 'enemy' }],
        inspiration: 'Dragon Ball Z - Instant Transmission'
      }
    };

    // ONE PIECE INSPIRED MOVES
    this.moveDatabase['gum_gum_pistol'] = {
      id: 'gum_gum_pistol',
      name: 'Gum-Gum Pistol',
      description: 'Rubber punch attack - inspired by Luffy\'s signature technique',
      inspiration: {
        anime: 'One Piece',
        character: 'Monkey D. Luffy',
        technique: 'Gum-Gum Pistol',
        description: 'Rubber arm punch that extends and retracts',
        powerLevel: 6,
        popularity: 9
      },
      move: {
        type: 'attack',
        direction: 'forward',
        damage: 25,
        chakraCost: 10,
        cooldown: 1,
        range: 4,
        element: ElementalNature.RUBBER, // Custom element
        effects: [
          { type: 'damage', value: 25, target: 'enemy' },
          { type: 'knockback', value: 40, target: 'enemy' }
        ],
        animation: 'gum_gum_pistol',
        visualEffects: ['rubber_stretch', 'impact_effect']
      },
      combo: {
        inputs: [
          { button: 'attack', direction: 'forward', timing: 0 },
          { button: 'attack', direction: 'forward', timing: 300 },
          { button: 'special', direction: 'forward', timing: 600 }
        ],
        damage: 60,
        chakraCost: 25,
        element: ElementalNature.RUBBER,
        requirements: [],
        effects: [{ type: 'damage', value: 60, target: 'enemy' }]
      },
      superMove: {
        name: 'Gear Second: Jet Pistol',
        description: 'Enhanced rubber punch with Gear Second power',
        damage: 80,
        chakraCost: 60,
        element: ElementalNature.RUBBER,
        requirements: [{ type: 'chakra', value: 60, operator: 'greater' }],
        effects: [{ type: 'damage', value: 80, target: 'enemy' }],
        animation: 'gear_second_jet_pistol',
        inspiration: 'One Piece - Gear Second Jet Pistol'
      },
      chargeAttack: {
        name: 'Charged Gum-Gum Pistol',
        description: 'Hold to charge up a more powerful rubber punch',
        chargeTime: 2,
        damage: 45,
        chakraCost: 20,
        element: ElementalNature.RUBBER,
        effects: [{ type: 'damage', value: 45, target: 'enemy' }],
        inspiration: 'One Piece - Gum-Gum Pistol'
      }
    };

    // BLEACH INSPIRED MOVES
    this.moveDatabase['zanpakuto_slash'] = {
      id: 'zanpakuto_slash',
      name: 'Zanpakuto Slash',
      description: 'Spiritual sword strike - inspired by Ichigo\'s technique',
      inspiration: {
        anime: 'Bleach',
        character: 'Ichigo Kurosaki',
        technique: 'Zanpakuto Slash',
        description: 'Spiritual energy sword attack',
        powerLevel: 7,
        popularity: 8
      },
      move: {
        type: 'attack',
        direction: 'forward',
        damage: 28,
        chakraCost: 12,
        cooldown: 1.2,
        range: 3,
        element: ElementalNature.SHADOW,
        effects: [
          { type: 'damage', value: 28, target: 'enemy' },
          { type: 'elemental', value: 8, target: 'enemy', element: ElementalNature.SHADOW }
        ],
        animation: 'zanpakuto_slash',
        visualEffects: ['spiritual_energy', 'sword_trail']
      },
      combo: {
        inputs: [
          { button: 'attack', direction: 'forward', timing: 0 },
          { button: 'attack', direction: 'up', timing: 250 },
          { button: 'special', direction: 'forward', timing: 500 }
        ],
        damage: 65,
        chakraCost: 30,
        element: ElementalNature.SHADOW,
        requirements: [],
        effects: [{ type: 'damage', value: 65, target: 'enemy' }]
      },
      superMove: {
        name: 'Bankai: Tensa Zangetsu',
        description: 'Ultimate sword technique in Bankai form',
        damage: 110,
        chakraCost: 75,
        element: ElementalNature.SHADOW,
        requirements: [{ type: 'chakra', value: 75, operator: 'greater' }],
        effects: [{ type: 'damage', value: 110, target: 'enemy' }],
        animation: 'bankai_tensa_zangetsu',
        inspiration: 'Bleach - Bankai Tensa Zangetsu'
      },
      chargeAttack: {
        name: 'Charged Zanpakuto Slash',
        description: 'Hold to charge up a more powerful sword strike',
        chargeTime: 2,
        damage: 50,
        chakraCost: 25,
        element: ElementalNature.SHADOW,
        effects: [{ type: 'damage', value: 50, target: 'enemy' }],
        inspiration: 'Bleach - Zanpakuto Slash'
      }
    };

    // DEMON SLAYER INSPIRED MOVES
    this.moveDatabase['water_breathing_slash'] = {
      id: 'water_breathing_slash',
      name: 'Water Breathing Slash',
      description: 'Water-enhanced sword technique - inspired by Tanjiro\'s technique',
      inspiration: {
        anime: 'Demon Slayer',
        character: 'Tanjiro Kamado',
        technique: 'Water Breathing',
        description: 'Sword technique that mimics water flow',
        powerLevel: 6,
        popularity: 8
      },
      move: {
        type: 'attack',
        direction: 'forward',
        damage: 22,
        chakraCost: 8,
        cooldown: 1,
        range: 3,
        element: ElementalNature.WATER,
        effects: [
          { type: 'damage', value: 22, target: 'enemy' },
          { type: 'elemental', value: 6, target: 'enemy', element: ElementalNature.WATER }
        ],
        animation: 'water_breathing_slash',
        visualEffects: ['water_trail', 'sword_flow']
      },
      combo: {
        inputs: [
          { button: 'attack', direction: 'forward', timing: 0 },
          { button: 'attack', direction: 'up', timing: 300 },
          { button: 'attack', direction: 'down', timing: 600 }
        ],
        damage: 55,
        chakraCost: 20,
        element: ElementalNature.WATER,
        requirements: [],
        effects: [{ type: 'damage', value: 55, target: 'enemy' }]
      },
      superMove: {
        name: 'Hinokami Kagura: Dance of the Fire God',
        description: 'Ultimate fire breathing technique',
        damage: 95,
        chakraCost: 70,
        element: ElementalNature.FIRE,
        requirements: [{ type: 'chakra', value: 70, operator: 'greater' }],
        effects: [{ type: 'damage', value: 95, target: 'enemy' }],
        animation: 'hinokami_kagura_dance',
        inspiration: 'Demon Slayer - Hinokami Kagura'
      },
      chargeAttack: {
        name: 'Charged Water Breathing',
        description: 'Hold to charge up a more powerful water slash',
        chargeTime: 2,
        damage: 40,
        chakraCost: 18,
        element: ElementalNature.WATER,
        effects: [{ type: 'damage', value: 40, target: 'enemy' }],
        inspiration: 'Demon Slayer - Water Breathing'
      }
    };

    // MY HERO ACADEMIA INSPIRED MOVES
    this.moveDatabase['one_for_all_punch'] = {
      id: 'one_for_all_punch',
      name: 'One For All Punch',
      description: 'Superhuman strength punch - inspired by Deku\'s quirk',
      inspiration: {
        anime: 'My Hero Academia',
        character: 'Izuku Midoriya',
        technique: 'One For All',
        description: 'Superhuman strength quirk that can destroy buildings',
        powerLevel: 9,
        popularity: 9
      },
      move: {
        type: 'attack',
        direction: 'forward',
        damage: 35,
        chakraCost: 15,
        cooldown: 1.5,
        range: 4,
        element: ElementalNature.LIGHTNING,
        effects: [
          { type: 'damage', value: 35, target: 'enemy' },
          { type: 'knockback', value: 60, target: 'enemy' }
        ],
        animation: 'one_for_all_punch',
        visualEffects: ['lightning_energy', 'impact_crater']
      },
      combo: {
        inputs: [
          { button: 'attack', direction: 'forward', timing: 0 },
          { button: 'special', direction: 'forward', timing: 400 },
          { button: 'attack', direction: 'up', timing: 800 }
        ],
        damage: 75,
        chakraCost: 35,
        element: ElementalNature.LIGHTNING,
        requirements: [],
        effects: [{ type: 'damage', value: 75, target: 'enemy' }]
      },
      superMove: {
        name: 'One For All: 100%',
        description: 'Ultimate One For All power at 100%',
        damage: 130,
        chakraCost: 90,
        element: ElementalNature.LIGHTNING,
        requirements: [{ type: 'chakra', value: 90, operator: 'greater' }],
        effects: [{ type: 'damage', value: 130, target: 'enemy' }],
        animation: 'one_for_all_100_percent',
        inspiration: 'My Hero Academia - One For All 100%'
      },
      chargeAttack: {
        name: 'Charged One For All',
        description: 'Hold to charge up a more powerful One For All punch',
        chargeTime: 3,
        damage: 65,
        chakraCost: 30,
        element: ElementalNature.LIGHTNING,
        effects: [{ type: 'damage', value: 65, target: 'enemy' }],
        inspiration: 'My Hero Academia - One For All'
      }
    };

    // JUJUTSU KAISEN INSPIRED MOVES
    this.moveDatabase['cursed_energy_punch'] = {
      id: 'cursed_energy_punch',
      name: 'Cursed Energy Punch',
      description: 'Cursed energy enhanced punch - inspired by Yuji\'s technique',
      inspiration: {
        anime: 'Jujutsu Kaisen',
        character: 'Yuji Itadori',
        technique: 'Cursed Energy',
        description: 'Supernatural energy that can harm curses',
        powerLevel: 7,
        popularity: 8
      },
      move: {
        type: 'attack',
        direction: 'forward',
        damage: 30,
        chakraCost: 12,
        cooldown: 1.2,
        range: 3,
        element: ElementalNature.CURSE, // Custom element
        effects: [
          { type: 'damage', value: 30, target: 'enemy' },
          { type: 'elemental', value: 10, target: 'enemy', element: ElementalNature.CURSE }
        ],
        animation: 'cursed_energy_punch',
        visualEffects: ['cursed_energy_aura', 'dark_impact']
      },
      combo: {
        inputs: [
          { button: 'attack', direction: 'forward', timing: 0 },
          { button: 'attack', direction: 'forward', timing: 300 },
          { button: 'special', direction: 'forward', timing: 600 }
        ],
        damage: 70,
        chakraCost: 30,
        element: ElementalNature.CURSE,
        requirements: [],
        effects: [{ type: 'damage', value: 70, target: 'enemy' }]
      },
      superMove: {
        name: 'Divergent Fist: Maximum Output',
        description: 'Ultimate cursed energy technique',
        damage: 105,
        chakraCost: 80,
        element: ElementalNature.CURSE,
        requirements: [{ type: 'chakra', value: 80, operator: 'greater' }],
        effects: [{ type: 'damage', value: 105, target: 'enemy' }],
        animation: 'divergent_fist_maximum',
        inspiration: 'Jujutsu Kaisen - Divergent Fist'
      },
      chargeAttack: {
        name: 'Charged Cursed Energy',
        description: 'Hold to charge up more powerful cursed energy',
        chargeTime: 2,
        damage: 55,
        chakraCost: 25,
        element: ElementalNature.CURSE,
        effects: [{ type: 'damage', value: 55, target: 'enemy' }],
        inspiration: 'Jujutsu Kaisen - Cursed Energy'
      }
    };

    // ATTACK ON TITAN INSPIRED MOVES
    this.moveDatabase['titan_punch'] = {
      id: 'titan_punch',
      name: 'Titan Punch',
      description: 'Massive titan fist strike - inspired by Eren\'s titan form',
      inspiration: {
        anime: 'Attack on Titan',
        character: 'Eren Yeager',
        technique: 'Titan Transformation',
        description: 'Transform into a massive titan for combat',
        powerLevel: 8,
        popularity: 9
      },
      move: {
        type: 'attack',
        direction: 'forward',
        damage: 40,
        chakraCost: 20,
        cooldown: 2,
        range: 5,
        element: ElementalNature.EARTH,
        effects: [
          { type: 'damage', value: 40, target: 'enemy' },
          { type: 'knockback', value: 70, target: 'enemy' }
        ],
        animation: 'titan_punch',
        visualEffects: ['titan_fist', 'earth_impact']
      },
      combo: {
        inputs: [
          { button: 'attack', direction: 'forward', timing: 0 },
          { button: 'attack', direction: 'down', timing: 400 },
          { button: 'special', direction: 'forward', timing: 800 }
        ],
        damage: 85,
        chakraCost: 40,
        element: ElementalNature.EARTH,
        requirements: [],
        effects: [{ type: 'damage', value: 85, target: 'enemy' }]
      },
      superMove: {
        name: 'Attack Titan: Rumbling',
        description: 'Ultimate titan transformation with devastating power',
        damage: 140,
        chakraCost: 100,
        element: ElementalNature.EARTH,
        requirements: [{ type: 'chakra', value: 100, operator: 'greater' }],
        effects: [{ type: 'damage', value: 140, target: 'enemy' }],
        animation: 'attack_titan_rumbling',
        inspiration: 'Attack on Titan - Attack Titan'
      },
      chargeAttack: {
        name: 'Charged Titan Punch',
        description: 'Hold to charge up a more powerful titan punch',
        chargeTime: 3,
        damage: 70,
        chakraCost: 35,
        element: ElementalNature.EARTH,
        effects: [{ type: 'damage', value: 70, target: 'enemy' }],
        inspiration: 'Attack on Titan - Titan Transformation'
      }
    };

    // Add more moves from other anime...
    this.addMoreAnimeMoves();
  }

  private addMoreAnimeMoves(): void {
    // Add moves from other popular anime
    // This would include moves from:
    // - Fullmetal Alchemist
    // - Hunter x Hunter
    // - JoJo's Bizarre Adventure
    // - Death Note
    // - Tokyo Ghoul
    // - And many more...
  }

  private organizeMoves(): void {
    // Organize moves by element
    for (const [moveId, move] of Object.entries(this.moveDatabase)) {
      const element = move.move.element;
      if (!this.elementalMoves.has(element)) {
        this.elementalMoves.set(element, []);
      }
      this.elementalMoves.get(element)!.push(move);
    }

    // Organize moves by anime
    for (const [moveId, move] of Object.entries(this.moveDatabase)) {
      const anime = move.inspiration.anime;
      if (!this.animeMoves.has(anime)) {
        this.animeMoves.set(anime, []);
      }
      this.animeMoves.get(anime)!.push(move);
    }

    // Organize moves by power level
    for (const [moveId, move] of Object.entries(this.moveDatabase)) {
      const powerLevel = move.inspiration.powerLevel;
      if (!this.powerLevelMoves.has(powerLevel)) {
        this.powerLevelMoves.set(powerLevel, []);
      }
      this.powerLevelMoves.get(powerLevel)!.push(move);
    }
  }

  public getMove(moveId: string): MoveEntry | undefined {
    return this.moveDatabase[moveId];
  }

  public getMovesByElement(element: ElementalNature): MoveEntry[] {
    return this.elementalMoves.get(element) || [];
  }

  public getMovesByAnime(anime: string): MoveEntry[] {
    return this.animeMoves.get(anime) || [];
  }

  public getMovesByPowerLevel(powerLevel: number): MoveEntry[] {
    return this.powerLevelMoves.get(powerLevel) || [];
  }

  public getAllMoves(): MoveEntry[] {
    return Object.values(this.moveDatabase);
  }

  public getRandomMove(): MoveEntry {
    const moves = this.getAllMoves();
    return moves[Math.floor(Math.random() * moves.length)];
  }

  public getRandomMoveByElement(element: ElementalNature): MoveEntry {
    const moves = this.getMovesByElement(element);
    return moves[Math.floor(Math.random() * moves.length)];
  }

  public getRandomMoveByAnime(anime: string): MoveEntry {
    const moves = this.getMovesByAnime(anime);
    return moves[Math.floor(Math.random() * moves.length)];
  }

  public getRandomMoveByPowerLevel(powerLevel: number): MoveEntry {
    const moves = this.getMovesByPowerLevel(powerLevel);
    return moves[Math.floor(Math.random() * moves.length)];
  }

  public searchMoves(query: string): MoveEntry[] {
    const results: MoveEntry[] = [];
    const lowerQuery = query.toLowerCase();

    for (const move of this.getAllMoves()) {
      if (
        move.name.toLowerCase().includes(lowerQuery) ||
        move.description.toLowerCase().includes(lowerQuery) ||
        move.inspiration.anime.toLowerCase().includes(lowerQuery) ||
        move.inspiration.character.toLowerCase().includes(lowerQuery) ||
        move.inspiration.technique.toLowerCase().includes(lowerQuery)
      ) {
        results.push(move);
      }
    }

    return results;
  }
}

// Custom elemental natures for unique anime-inspired moves
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

