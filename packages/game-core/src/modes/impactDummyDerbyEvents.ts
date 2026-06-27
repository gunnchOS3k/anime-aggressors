export type ImpactDummyDerbyEvent =
  | { type: "phaseChanged"; frame: number; phase: string }
  | { type: "hitLanded"; frame: number; damage: number; combo: number }
  | { type: "comboBroken"; frame: number }
  | { type: "batEquipped"; frame: number }
  | { type: "batSwing"; frame: number; sweetSpot: boolean }
  | { type: "launch"; frame: number; speed: number; angleDeg: number }
  | { type: "landed"; frame: number; distance: number }
  | { type: "scored"; frame: number; score: number; grade: string };

export function pushDerbyEvent(
  events: ImpactDummyDerbyEvent[],
  event: ImpactDummyDerbyEvent,
): ImpactDummyDerbyEvent[] {
  return [...events, event];
}
