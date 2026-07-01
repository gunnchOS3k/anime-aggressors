import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { BLAST_LEFT, BLAST_RIGHT, isOutsideBlastZone } from "../src/combat/blastZones.js";
import { stubPlayer } from "./helpers/playerStub.js";

function playerAt(x: number, y: number) {
  return stubPlayer({ x, y, staminaHp: 100, maxStaminaHp: 100 });
}

describe("blast zones", () => {
  it("detects outside left and right blast zones", () => {
    assert.equal(isOutsideBlastZone(playerAt(BLAST_LEFT - 1, 50000)), true);
    assert.equal(isOutsideBlastZone(playerAt(BLAST_RIGHT + 1, 50000)), true);
    assert.equal(isOutsideBlastZone(playerAt((BLAST_LEFT + BLAST_RIGHT) / 2, 50000)), false);
  });
});
