export type EnergyElement = "flame" | "impact" | "volt" | "gale" | "frost" | "gravity" | "void";

export type EnergyAttackKind = "beam" | "orb" | "wave" | "shockwave";

export type EnergyAttackState = {
  id: string;
  ownerPlayerId: number;
  fighterId: string;
  moveId: string;
  kind: EnergyAttackKind;
  x: number;
  y: number;
  vx: number;
  vy: number;
  width: number;
  height: number;
  power: number;
  stability: number;
  durationFrames: number;
  element: EnergyElement;
  clashable: boolean;
  facing: 1 | -1;
  frame: number;
  lockedInClashId?: string;
};

export type EnergyClashPhase = "starting" | "struggling" | "resolved";

export type EnergyClashState = {
  id: string;
  attackAId: string;
  attackBId: string;
  playerAId: number;
  playerBId: number;
  x: number;
  y: number;
  balance: number;
  intensity: number;
  durationFrames: number;
  maxDurationFrames: number;
  winnerPlayerId?: number;
  phase: EnergyClashPhase;
  neutralBurst?: boolean;
};

export const CLASH_WIN_THRESHOLD = 100;
export const CLASH_MAX_DURATION = 120;

export const ELEMENT_ADVANTAGE: Partial<Record<EnergyElement, EnergyElement>> = {
  flame: "frost",
  frost: "gale",
  gale: "gravity",
  gravity: "volt",
  volt: "void",
  void: "impact",
  impact: "flame",
};

export function elementAdvantageBonus(attacker: EnergyElement, defender: EnergyElement): number {
  return ELEMENT_ADVANTAGE[attacker] === defender ? 8 : ELEMENT_ADVANTAGE[defender] === attacker ? -8 : 0;
}
