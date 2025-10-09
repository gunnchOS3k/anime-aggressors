// Game state types
export interface GameState {
  players: PlayerState[];
  stage: StageState;
  timestamp: number;
  frame: number;
}

export interface PlayerState {
  id: string;
  position: Vector3;
  velocity: Vector3;
  health: number;
  ki: number;
  stamina: number;
  facing: number;
  state: PlayerStateType;
  inputs: InputState;
}

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export type PlayerStateType = 
  | 'idle' 
  | 'walking' 
  | 'running' 
  | 'jumping' 
  | 'attacking' 
  | 'blocking' 
  | 'dodging' 
  | 'stunned' 
  | 'knocked_down';

export interface InputState {
  moveX: number;
  moveY: number;
  jump: boolean;
  light: boolean;
  heavy: boolean;
  special: boolean;
  dodge: boolean;
  block: boolean;
  pause: boolean;
}

// Network message types
export interface NetworkMessage {
  type: MessageType;
  data: any;
  timestamp: number;
  playerId: string;
}

export type MessageType = 
  | 'player_input'
  | 'game_state'
  | 'player_join'
  | 'player_leave'
  | 'match_start'
  | 'match_end'
  | 'ping'
  | 'pong';

// Character data types
export interface CharacterData {
  id: string;
  name: string;
  stats: CharacterStats;
  moves: MoveData[];
  animations: AnimationData[];
}

export interface CharacterStats {
  health: number;
  ki: number;
  stamina: number;
  speed: number;
  jumpHeight: number;
  weight: number;
}

export interface MoveData {
  id: string;
  name: string;
  input: string;
  damage: number;
  kiCost: number;
  startup: number;
  active: number;
  recovery: number;
  cancelable: boolean;
  properties: MoveProperty[];
}

export type MoveProperty = 
  | 'overhead'
  | 'low'
  | 'mid'
  | 'launcher'
  | 'knockdown'
  | 'wall_bounce'
  | 'ground_bounce';

export interface AnimationData {
  name: string;
  duration: number;
  events: AnimationEvent[];
}

export interface AnimationEvent {
  frame: number;
  type: 'hitbox' | 'hurtbox' | 'sound' | 'effect';
  data: any;
}

// Edge-IO types
export interface EdgeIOData {
  deviceId: string;
  gesture: GestureType;
  confidence: number;
  timestamp: number;
}

export type GestureType = 
  | 'swipe_left'
  | 'swipe_right'
  | 'swipe_up'
  | 'swipe_down'
  | 'thrust'
  | 'tap'
  | 'hold';

// Match types
export interface MatchData {
  id: string;
  players: string[];
  stage: string;
  rules: MatchRules;
  startTime: number;
  endTime?: number;
  winner?: string;
}

export interface MatchRules {
  timeLimit: number;
  stockCount: number;
  damageRatio: number;
  items: boolean;
}

// Leaderboard types
export interface LeaderboardEntry {
  playerId: string;
  playerName: string;
  rating: number;
  wins: number;
  losses: number;
  streak: number;
  rank: number;
}

// Cloud service types
export interface CloudConfig {
  apiUrl: string;
  wsUrl: string;
  region: string;
  version: string;
}

export interface MatchmakingRequest {
  playerId: string;
  rating: number;
  region: string;
  preferences: MatchmakingPreferences;
}

export interface MatchmakingPreferences {
  maxPing: number;
  skillRange: number;
  stagePreferences: string[];
}
