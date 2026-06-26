import type { GameState, StatEvent, MatchRecord, ReplayRecord, ImpactDummyDerbyState, FlaglineClashState } from "@anime-aggressors/game-core";
import {
  buildMatchRecordFromEvents,
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
} from "@anime-aggressors/game-core";
import { recordMatchToCareer } from "../storage/careerStorage.ts";
import { saveReplay } from "../storage/replayStorage.ts";
import type { ReplayRecorder } from "../replay/ReplayRecorder.ts";

export type MatchEndContext = {
  mode: string;
  initialState: GameState;
  finalState: GameState;
  events: StatEvent[];
  recorder: ReplayRecorder | null;
  localPlayerId?: number;
};

export type MatchEndResult = {
  match: MatchRecord;
  replay: ReplayRecord | null;
};

export async function processMatchEnd(ctx: MatchEndContext): Promise<MatchEndResult> {
  const matchId = `match-${Date.now()}`;
  let replay: ReplayRecord | null = null;

  if (ctx.recorder) {
    replay = ctx.recorder.finalize(matchId, ctx.finalState);
    if (replay) {
      await saveReplay(replay);
    }
  }

  const match = buildMatchRecordFromEvents({
    initialState: ctx.initialState,
    finalState: ctx.finalState,
    events: ctx.events,
    replayId: replay?.id,
    matchId,
    startedAt: ctx.recorder?.getStartedAt(),
    endedAt: new Date().toISOString(),
  });

  await recordMatchToCareer(match, ctx.localPlayerId ?? 0);

  return { match, replay };
}

export class StatEventTracker {
  private events: StatEvent[] = [];
  private prevStocks: number[] = [];
  private prevDamage: number[] = [];
  private mode: string;

  constructor(mode: string) {
    this.mode = mode;
  }

  start(frame: number): void {
    this.events.push({ type: "matchStarted", frame, mode: this.mode });
  }

  end(frame: number, winnerPlayerId?: number, winningTeam?: "solar" | "lunar"): void {
    this.events.push({ type: "matchEnded", frame, winnerPlayerId, winningTeam });
  }

  trackFrame(state: GameState, inputs: import("@anime-aggressors/game-core").InputFrame[]): void {
    const frame = state.frame;

    for (const input of inputs) {
      if (input.attack) {
        this.events.push({ type: "attackUsed", frame, playerId: input.playerId, moveId: "attack" });
      }
      if (input.special) {
        this.events.push({ type: "specialUsed", frame, playerId: input.playerId, moveId: "special" });
      }
      if (input.shield) {
        this.events.push({ type: "shieldUsed", frame, playerId: input.playerId });
      }
      if (input.dodge) {
        this.events.push({ type: "dodgeUsed", frame, playerId: input.playerId });
      }
      if (input.grab) {
        this.events.push({ type: "grabUsed", frame, playerId: input.playerId });
      }
    }

    for (const p of state.players) {
      const prevD = this.prevDamage[p.id] ?? 0;
      if (p.damage > prevD) {
        const amount = p.damage - prevD;
        const attackerId = p.id === 0 ? 1 : 0;
        this.events.push({ type: "damage", frame, attackerPlayerId: attackerId, victimPlayerId: p.id, amount });
        this.events.push({ type: "attackLanded", frame, playerId: attackerId, moveId: "attack" });
      }

      const prevS = this.prevStocks[p.id] ?? p.stocks;
      if (p.stocks < prevS && p.actionState === "defeated") {
        const attackerId = p.id === 0 ? 1 : 0;
        this.events.push({ type: "ko", frame, attackerPlayerId: attackerId, victimPlayerId: p.id });
        this.events.push({ type: "fall", frame, victimPlayerId: p.id });
      }

      this.prevDamage[p.id] = p.damage;
      this.prevStocks[p.id] = p.stocks;
    }
  }

  addEvent(event: StatEvent): void {
    this.events.push(event);
  }

  getEvents(): StatEvent[] {
    return this.events;
  }

  initFromState(state: GameState): void {
    this.prevStocks = state.players.map((p) => p.stocks);
    this.prevDamage = state.players.map((p) => p.damage);
  }
}

function baseGameState(seed = 1): GameState {
  const fighter = getDefaultCreatedFighter(0);
  const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], seed);
  return createInitialGameState(config);
}

export async function processDerbyEnd(
  derbyState: ImpactDummyDerbyState,
  fighterId: string,
  fighterName: string,
): Promise<MatchRecord> {
  const initial = baseGameState(derbyState.seed);
  const final = baseGameState(derbyState.seed);
  final.frame = derbyState.frame;

  const events: StatEvent[] = [
    { type: "matchStarted", frame: 0, mode: "impactDummyDerby" },
    {
      type: "derbyLaunched",
      frame: derbyState.frame,
      playerId: 0,
      distance: derbyState.distance,
      score: derbyState.score,
      launchSpeed: derbyState.launchSpeed,
    },
    { type: "matchEnded", frame: derbyState.frame },
  ];

  const match = buildMatchRecordFromEvents({
    initialState: initial,
    finalState: final,
    events,
    playerMetas: [
      {
        playerId: 0,
        playerName: "P1",
        fighterId,
        fighterName,
        isBot: false,
        size: derbyState.fighter.size,
        color: derbyState.fighter.color,
        elementName: derbyState.fighter.color,
      },
    ],
  });

  await recordMatchToCareer(match, 0);
  return match;
}

export async function processFlaglineEnd(
  initialGame: GameState,
  finalFlagline: FlaglineClashState,
  events: StatEvent[],
  recorder: ReplayRecorder | null,
): Promise<MatchEndResult> {
  const winningTeam = finalFlagline.flagline.winningTeam ?? undefined;
  const mergedEvents = [
    ...events,
    { type: "matchEnded" as const, frame: finalFlagline.frame, winningTeam },
  ];

  return processMatchEnd({
    mode: "flaglineClash",
    initialState: initialGame,
    finalState: finalFlagline.game,
    events: mergedEvents,
    recorder,
    localPlayerId: 0,
  });
}
