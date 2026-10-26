import { it } from "node:test";
import assert from "node:assert/strict";
import { cloneGameState, createInitialGameState, hashState, replay, simulateFrame,
  type GameConfig, type InputFrame } from "@anime-aggressors/game-core";
import { NetplaySession } from "../src/netplaySession.js";
import type { NetplayMessage, NetplayTransport } from "../src/transport.js";

const config: GameConfig = {
  playerCount: 2, stocks: 3, matchDurationFrames: 10800,
  stageId: "training-grid", characterIds: ["kaia-windrow", "juno-spark"],
  bodyVariants: ["female", "male"], seed: 93,
};
function input(frame: number, playerId: number, extra: Partial<InputFrame> = {}): InputFrame {
  return {frame, playerId, left: false, right: false, up: false, down: false,
    jump: false, attack: false, special: false, shield: false, dodge: false,
    grab: false, ...extra};
}
class TestTransport implements NetplayTransport {
  inbox: NetplayMessage[] = [];
  sent: NetplayMessage[] = [];
  onSend?: (message: NetplayMessage) => void;
  constructor(readonly localPlayerId: number) {}
  async connect() {}
  disconnect() {}
  send(message: NetplayMessage) {
    this.sent.push(structuredClone(message));
    this.onSend?.(structuredClone(message));
  }
  poll() { return this.inbox.splice(0); }
}

it("outgoing input and envelope identify the same actual simulation frame", () => {
  const transport = new TestTransport(0);
  const session = new NetplaySession(transport, {gameConfig: config, localPlayerId: 0});
  session.advanceLocal([input(0, 0)]);
  const message = transport.sent[0];
  assert.equal(message.type, "input");
  if (message.type !== "input") return;
  assert.equal(message.frame, message.input.frame);
  assert.equal(message.frame, 0);
});

function combatInput(frame: number, playerId: number): InputFrame {
  const approaching = frame >= 180 && frame < 264;
  return input(frame, playerId, {
    right: approaching && playerId === 0,
    left: approaching && playerId === 1,
    attack: frame >= 300 && frame < 500 && frame % 32 === 12,
    shield: playerId === 1 && frame >= 330 && frame < 362,
  });
}

/** Two separately owned sessions and transport inboxes, not two inputs injected
 * into one session. This deterministic test link is not a socket/LAN test.
 */
function delayedPeers(frames: number, makeInput: typeof combatInput) {
  const transports = [new TestTransport(0), new TestTransport(1)];
  const sessions = transports.map((transport, localPlayerId) =>
    new NetplaySession(transport, {gameConfig: config, localPlayerId}));
  let now = 0;
  let duplicates = 0;
  const queue: {due: number; seat: number; message: NetplayMessage}[] = [];
  for (const transport of transports) transport.onSend = message => {
    const delay = 3 + (message.frame * 7 + transport.localPlayerId * 3) % 6;
    queue.push({due: now + delay, seat: 1 - transport.localPlayerId, message});
    if (message.frame % 11 === 0) {
      queue.push({due: now + delay + 2, seat: 1 - transport.localPlayerId, message: structuredClone(message)});
      duplicates++;
    }
  };
  function deliver(time: number) {
    now = time;
    // Reverse delivery also exercises out-of-order batches.
    for (let i = queue.length - 1; i >= 0; i--) {
      if (queue[i].due > time) continue;
      const packet = queue.splice(i, 1)[0];
      transports[packet.seat].inbox.push(packet.message);
    }
  }
  const log: InputFrame[][] = [];
  for (let f = 0; f < frames; f++) {
    deliver(f);
    log.push([makeInput(f, 0), makeInput(f, 1)]);
    for (const seat of f % 2 === 0 ? [0, 1] : [1, 0]) sessions[seat].advanceLocal([log[f][seat]]);
  }
  const tips = sessions.map(session => session.getState().frame);
  deliver(frames + 12);
  for (const session of sessions) session.pumpRemoteInputs();
  assert.deepEqual(sessions.map(session => session.getState().frame), tips, "draining confirmations cannot advance combat");
  const expected = replay(createInitialGameState(config), log);
  for (const session of sessions) {
    assert.equal(hashState(session.getState()), expected.finalHash);
    assert.deepEqual(session.getState(), expected.finalState, "damage, stocks, guard, timing and aura match the authoritative full replay");
  }
  assert.ok(sessions.some(session => session.getRollbackStats().rollbackCount > 0), "actual late predictions must have been corrected");
  assert.ok(duplicates > 0);
  return {sessions, expected, duplicates};
}

it("delayed, reordered and duplicated inputs reconcile actual post-countdown combat", () => {
  const {expected, sessions, duplicates} = delayedPeers(640, combatInput);
  assert.equal(expected.finalState.phase, "fighting");
  assert.ok(expected.finalState.players.some(player => player.damage > 0), "the test must exercise real combat, not just countdown");
  console.log(JSON.stringify({scenario: "post_countdown_melee", frames: 640, delay_frames: [3, 8],
    duplicate_packets: duplicates, damage: expected.finalState.players.map(player => player.damage),
    rollback_counts: sessions.map(session => session.getRollbackStats().rollbackCount), final_hash: expected.finalHash}));
});

it("late aura-only input differences restore an unmodified snapshot", () => {
  const {expected} = delayedPeers(230, (frame, seat) =>
    input(frame, seat, {auraCharge: seat === 1 && frame >= 222}));
  assert.ok(expected.finalState.players[1].aura.current > 0);
});

it("future input waits for its own frame; duplicate confirmation is idempotent", () => {
  const transport = new TestTransport(0);
  const session = new NetplaySession(transport, {gameConfig: config, localPlayerId: 0});
  const future = input(183, 1, {left: true});
  // Advance first so183 is inside the bounded future window.
  const log: InputFrame[][] = [];
  for (let f = 0; f < 100; f++) { session.advanceLocal([input(f, 0)]); log.push([input(f, 0), input(f, 1)]); }
  transport.inbox.push({type: "input", playerId: 1, frame: 183, input: future});
  session.pumpRemoteInputs();
  for (let f = 100; f < 190; f++) {
    session.advanceLocal([input(f, 0)]);
    log.push([input(f, 0), f === 183 ? future : input(f, 1)]);
  }
  assert.equal(hashState(session.getState()), replay(createInitialGameState(config), log).finalHash);
  const before = session.getState();
  const count = session.getRollbackStats().rollbackCount;
  transport.inbox.push({type: "input", playerId: 1, frame: 183, input: {...future}});
  session.pumpRemoteInputs();
  assert.deepEqual(session.getState(), before);
  assert.equal(session.getRollbackStats().rollbackCount, count);
  transport.inbox.push({type: "input", playerId: 1, frame: 183, input: {...future, left: false}});
  assert.throws(() => session.pumpRemoteInputs(), /Conflicting confirmed/);
  assert.deepEqual(session.getState(), before);
});

it("rejects forged seats, frame retiming, malformed buttons and unbounded future inputs", () => {
  for (const message of [
    {type: "input", frame: 0, playerId: 0, input: input(0, 0)},
    {type: "input", frame: 1, playerId: 1, input: input(0, 1)},
    {type: "input", frame: 0, playerId: 1, input: {...input(0, 1), attack: 1}},
    {type: "input", frame: 121, playerId: 1, input: input(121, 1)},
  ]) {
    const transport = new TestTransport(0);
    const session = new NetplaySession(transport, {gameConfig: config, localPlayerId: 0});
    const before = session.getState();
    transport.inbox.push(message as NetplayMessage);
    assert.throws(() => session.pumpRemoteInputs());
    assert.deepEqual(session.getState(), before);
  }
});

it("missing packets beyond restore history require resynchronization instead of fake correction", () => {
  const transport = new TestTransport(0);
  const session = new NetplaySession(transport, {gameConfig: config, localPlayerId: 0});
  for (let f = 0; f < 130; f++) session.advanceLocal([input(f, 0)]);
  transport.inbox.push({type: "input", frame: 0, playerId: 1, input: input(0, 1, {left: true})});
  const before = session.getState();
  assert.throws(() => session.pumpRemoteInputs(), /resynchronization required/);
  assert.deepEqual(session.getState(), before);
});

it("advancing real aura controls cannot mutate an older simulation snapshot", () => {
  let state = createInitialGameState(config);
  for (let f = 0; f < 180; f++) state = simulateFrame(state, [input(f, 0), input(f, 1)]);
  const saved = cloneGameState(state);
  const before = hashState(saved);
  for (let f = 180; f < 190; f++) state = simulateFrame(state, [input(f, 0, {auraCharge: true}), input(f, 1)]);
  assert.ok(state.players[0].aura.current > 0, "real charge must have occurred");
  assert.equal(hashState(saved), before, "saved aura must not share the live mutable object");
});
