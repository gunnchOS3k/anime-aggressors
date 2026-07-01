import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { resolveMoveSlotFromInput } from "../src/moves/moveDefinitions.js";
import { stubPlayer } from "./helpers/playerStub.js";

describe("combat input grammar", () => {
  it("side attack slot from directional input", () => {
    const p = stubPlayer();
    const slot = resolveMoveSlotFromInput(p, {
      left: false,
      right: true,
      up: false,
      down: false,
      attack: true,
      special: false,
    });
    assert.equal(slot, "sideAttack");
  });
});
