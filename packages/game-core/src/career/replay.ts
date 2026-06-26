import type { ReplayInputFrame, ReplayRecord } from "./types.js";
import type { InputFrame } from "../types.js";
import { hashState, serializeState, deserializeState } from "../hash.js";
import { replay } from "../replay.js";
import type { GameState } from "../types.js";

export function createReplayRecord(args: {
  matchId: string;
  gameVersion: string;
  mode: string;
  ruleset: unknown;
  initialState: GameState;
  inputLog: ReplayInputFrame[];
  title: string;
  notes?: string;
}): ReplayRecord {
  const result = replay(args.initialState, args.inputLog.map((f) => f.inputs));
  return {
    id: `replay-${Date.now()}`,
    matchId: args.matchId,
    createdAt: new Date().toISOString(),
    gameVersion: args.gameVersion,
    mode: args.mode,
    ruleset: args.ruleset,
    initialStateSerialized: serializeState(args.initialState),
    inputLog: args.inputLog,
    finalStateHash: result.finalHash,
    durationFrames: result.framesSimulated,
    playerNames: args.initialState.players.map((p) => `P${p.id + 1}`),
    fighterNames: args.initialState.players.map((p) => p.fighterName),
    title: args.title,
    notes: args.notes,
  };
}

export function verifyReplayRecord(record: ReplayRecord): {
  valid: boolean;
  reproducedHash: string;
} {
  const initial = deserializeState(record.initialStateSerialized) as GameState;
  const result = replay(
    initial,
    record.inputLog.map((f) => f.inputs),
  );
  return {
    valid: result.finalHash === record.finalStateHash,
    reproducedHash: result.finalHash,
  };
}

export function inputsToReplayFrames(inputLog: InputFrame[][]): ReplayInputFrame[] {
  return inputLog.map((inputs, frame) => ({ frame, inputs }));
}
