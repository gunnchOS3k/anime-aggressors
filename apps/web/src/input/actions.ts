export type GameAction =
  | "moveLeft"
  | "moveRight"
  | "moveUp"
  | "moveDown"
  | "jump"
  | "attack"
  | "special"
  | "shield"
  | "dodge"
  | "grab"
  | "pause"
  | "taunt"
  | "debugToggle";

export const GAME_ACTIONS: GameAction[] = [
  "moveLeft",
  "moveRight",
  "moveUp",
  "moveDown",
  "jump",
  "attack",
  "special",
  "shield",
  "dodge",
  "grab",
  "pause",
  "taunt",
  "debugToggle",
];

export const ACTION_LABELS: Record<GameAction, string> = {
  moveLeft: "Move Left",
  moveRight: "Move Right",
  moveUp: "Move Up",
  moveDown: "Move Down",
  jump: "Jump",
  attack: "Attack",
  special: "Special",
  shield: "Shield",
  dodge: "Dodge",
  grab: "Grab",
  pause: "Pause",
  taunt: "Taunt",
  debugToggle: "Debug Toggle",
};
