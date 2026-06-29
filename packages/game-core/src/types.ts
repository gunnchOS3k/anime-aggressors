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
  | "auraCharging"
  | "dodging"
  | "hitstun"
  | "defeated";

export type PlayerState = {
  id: number;
  characterId: string;
  fighterName: string;
  fighterSize: import("./sizeClasses.js").FighterSize;
  fighterColor: import("./elements.js").FighterColor;
  elementEffect: import("./elements.js").ElementEffect;
  burnFramesRemaining: number;
  slowFramesRemaining: number;
  slowMultiplierFp: number;
  airDriftBonusFrames: number;
  x: number;
  y: number;
  vx: number;
  vy: number;
  facing: 1 | -1;
  damage: number;
  stocks: number;
  staminaHp: number;
  maxStaminaHp: number;
  score: number;
  teamId: number;
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
  aura: import("./aura/auraTypes.js").AuraChargeState;
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
  fighterProfiles?: import("./createdFighter.js").CreatedFighter[];
  ruleset?: import("./rulesets.js").GameRuleset;
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
  lastHitEvents: import("./combat/hitEvents.js").HitEvent[];
  energyAttacks?: import("./combat/beamTypes.js").EnergyAttackState[];
  energyClashes?: import("./combat/beamTypes.js").EnergyClashState[];
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
