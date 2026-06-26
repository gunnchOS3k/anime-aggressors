import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getNextRoomIndex } from "../src/modes/flaglineProgression.js";

describe("flagline progression", () => {
  it("Solar wins center → -1", () => {
    assert.equal(getNextRoomIndex(0, "solar"), -1);
  });

  it("Lunar wins center → +1", () => {
    assert.equal(getNextRoomIndex(0, "lunar"), 1);
  });

  it("Solar wins -1 → -2", () => {
    assert.equal(getNextRoomIndex(-1, "solar"), -2);
  });

  it("Solar wins -2 → solarWinsGame", () => {
    assert.equal(getNextRoomIndex(-2, "solar"), "solarWinsGame");
  });

  it("Lunar wins +1 → +2", () => {
    assert.equal(getNextRoomIndex(1, "lunar"), 2);
  });

  it("Lunar wins +2 → lunarWinsGame", () => {
    assert.equal(getNextRoomIndex(2, "lunar"), "lunarWinsGame");
  });

  it("Solar wins +2 → +1", () => {
    assert.equal(getNextRoomIndex(2, "solar"), 1);
  });

  it("Lunar wins -2 → -1", () => {
    assert.equal(getNextRoomIndex(-2, "lunar"), -1);
  });
});
