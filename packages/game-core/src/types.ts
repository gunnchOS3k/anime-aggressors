/** Normalized wearable gesture names (Edge-IO protocol). */
export type GestureName =
  | "swipeL"
  | "swipeR"
  | "swipeU"
  | "swipeD"
  | "thrust"
  | "tap"
  | "doubleTap"
  | "block"
  | "shake";

/** One player's inputs for a single simulation frame. */
export type InputFrame = {
  frame: number;
  playerId: number;
  left: boolean;
  right: boolean;
  up: boolean;
  down: boolean;
  jump: boolean;
  attack: boolean;
  special: boolean;
  shield: boolean;
  dodge: boolean;
  grab: boolean;
  wearableGesture?: GestureName;
};

export type MatchPhase =
  | "characterSelect"
  | "countdown"
  | "fighting"
  | "results";

export type PlayerActionState =
  | "idle"
  | "running"
  | "jumping"
  | "falling"
  | "attacking"
  | "special"
  | "shielding"
  | "dodging"
  | "hitstun"
  | "defeated";

export type PlayerState = {
  id: number;
  characterId: string;
  x: number;
  y: number;
  vx: number;
  vy: number;
  facing: 1 | -1;
  damage: number;
  stocks: number;
  actionState: PlayerActionState;
  actionFrame: number;
  hitstunFrames: number;
  shieldHealth: number;
  jumpsRemaining: number;
  onGround: boolean;
  invulnFrames: number;
  coyoteFrames: number;
  jumpBufferFrames: number;
  fastFalling: boolean;
  currentMoveId: string;
};

export type StageBounds = {
  left: number;
  right: number;
  top: number;
  bottom: number;
  floorY: number;
};

export type GameConfig = {
  playerCount: number;
  stocks: number;
  matchDurationFrames: number;
  stageId: string;
  characterIds: string[];
  seed: number;
};

export type GameState = {
  frame: number;
  phase: MatchPhase;
  config: GameConfig;
  players: PlayerState[];
  stage: StageBounds;
  countdownFrames: number;
  matchTimerFrames: number;
  winnerId: number | null;
  hitstopFrames: number;
};

export type ReplayResult = {
  finalState: GameState;
  finalHash: string;
  framesSimulated: number;
};

export type Hitbox = {
  ownerId: number;
  x: number;
  y: number;
  w: number;
  h: number;
  damage: number;
  knockbackX: number;
  knockbackY: number;
  active: boolean;
};

export type Hurtbox = {
  ownerId: number;
  x: number;
  y: number;
  w: number;
  h: number;
};
