import { describe, it } from "node:test";
import assert from "node:assert/strict";
import type { InputFrame } from "@anime-aggressors/game-core";
import { createLoopbackPair } from "../src/localLoopbackTransport.js";
import { simulateLoopbackPeers } from "../src/netplaySession.js";

function input(frame: number, playerId: number): InputFrame {
  return {
    frame,
    playerId,
    left: frame % 20 < 10 && playerId === 0,
    right: frame % 15 < 8 && playerId === 1,
    up: false,
    down: false,
    jump: frame === 30 && playerId === 0,
    attack: frame === 60 && playerId === 1,
    special: false,
    shield: false,
    dodge: false,
    grab: false,
  };
}

describe("local loopback netplay", () => {
  it("two peers exchange inputs and reach same final hash", async () => {
    const transports = createLoopbackPair({ seed: 3 });
    await transports[0].connect();
    await transports[1].connect();

    const config = {
      playerCount: 2,
      stocks: 3,
      matchDurationFrames: 180 * 60,
      stageId: "skyline-arena",
      characterIds: ["ember", "tide"],
      seed: 11,
    };

    const result = simulateLoopbackPeers(90, input, transports, config);
    assert.equal(result.match, true);
    assert.ok(result.hash0.length > 0);
  });
});
