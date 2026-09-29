import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import {
  createCharacterSelectState,
  isCharacterSelectReady,
  selectFighterForActivePlayer,
  setFocusedFighter,
  setPendingBodyVariant,
  tileStateForFighter,
  seatPayload,
} from "../src/characterSelect/characterSelectState.ts";

describe("character select flow", () => {
  const roster = getAllDefaultCreatedFighters();

  it("focus changes preview fighter id", () => {
    let state = createCharacterSelectState(roster);
    state = setFocusedFighter(state, roster[2]!.id);
    assert.equal(state.focusedId, roster[2]!.id);
  });

  it("selecting P1 stores fighter and body variant", () => {
    let state = createCharacterSelectState(roster);
    state = setPendingBodyVariant(state, "female");
    state = selectFighterForActivePlayer(state, roster[0]!);
    assert.equal(state.p1.fighter?.id, roster[0]!.id);
    assert.equal(state.p1.bodyVariant, "female");
    assert.equal(state.p1.locked, true);
  });

  it("selecting P2 stores fighter", () => {
    let state = createCharacterSelectState(roster);
    state = selectFighterForActivePlayer(state, roster[0]!);
    state = selectFighterForActivePlayer(state, roster[1]!);
    assert.equal(state.p2.fighter?.id, roster[1]!.id);
  });

  it("duplicate fighter prefers opposite body presentation", () => {
    let state = createCharacterSelectState(roster);
    state = setPendingBodyVariant(state, "male");
    state = selectFighterForActivePlayer(state, roster[0]!, "male");
    state = setPendingBodyVariant(state, "male");
    state = selectFighterForActivePlayer(state, roster[0]!, "male");
    assert.equal(state.p1.bodyVariant, "male");
    assert.equal(state.p2.bodyVariant, "female");
  });

  it("continue disabled until required fighters are locked", () => {
    const state = createCharacterSelectState(roster);
    assert.equal(isCharacterSelectReady(state), false);
    let ready = selectFighterForActivePlayer(state, roster[0]!);
    ready = selectFighterForActivePlayer(ready, roster[1]!);
    assert.equal(isCharacterSelectReady(ready), true);
  });

  it("tile states mark P1 and P2", () => {
    let state = createCharacterSelectState(roster);
    state = selectFighterForActivePlayer(state, roster[0]!);
    state = selectFighterForActivePlayer(state, roster[1]!);
    assert.equal(tileStateForFighter(state, roster[0]!.id), "p1");
    assert.equal(tileStateForFighter(state, roster[1]!.id), "p2");
  });

  it("seat payload carries fighter_id + body_variant + seat_id", () => {
    let state = createCharacterSelectState(roster);
    state = selectFighterForActivePlayer(state, roster[0]!, "male");
    const payload = seatPayload(0, state.p1);
    assert.equal(payload.fighter_id, roster[0]!.id);
    assert.equal(payload.body_variant, "male");
    assert.equal(payload.seat_id, 0);
  });
});
