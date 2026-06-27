import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import {
  createCharacterSelectState,
  isCharacterSelectReady,
  selectFighterForActivePlayer,
  setFocusedFighter,
  tileStateForFighter,
} from "../src/characterSelect/characterSelectState.ts";

describe("character select flow", () => {
  const roster = getAllDefaultCreatedFighters();

  it("focus changes preview fighter id", () => {
    let state = createCharacterSelectState(roster);
    state = setFocusedFighter(state, roster[2]!.id);
    assert.equal(state.focusedId, roster[2]!.id);
  });

  it("selecting P1 stores fighter", () => {
    let state = createCharacterSelectState(roster);
    state = selectFighterForActivePlayer(state, roster[0]!);
    assert.equal(state.p1?.id, roster[0]!.id);
  });

  it("selecting P2 stores fighter", () => {
    let state = createCharacterSelectState(roster);
    state = selectFighterForActivePlayer(state, roster[0]!);
    state = selectFighterForActivePlayer(state, roster[1]!);
    assert.equal(state.p2?.id, roster[1]!.id);
  });

  it("continue disabled until required fighters are selected", () => {
    const state = { ...createCharacterSelectState(roster), p1: null, p2: null };
    assert.equal(isCharacterSelectReady(state), false);
    const ready = { ...state, p1: roster[0]!, p2: roster[1]! };
    assert.equal(isCharacterSelectReady(ready), true);
  });

  it("tile states mark P1 and P2", () => {
    let state = createCharacterSelectState(roster);
    state = { ...state, p1: roster[0]!, p2: roster[1]! };
    assert.equal(tileStateForFighter(state, roster[0]!.id), "p1");
    assert.equal(tileStateForFighter(state, roster[1]!.id), "p2");
  });
});
