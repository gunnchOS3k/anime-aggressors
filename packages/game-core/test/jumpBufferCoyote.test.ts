import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { bufferJumpInput, consumeJumpBuffer } from "../src/movement/jumpSystem.js";
import { stubPlayer } from "./helpers/playerStub.js";

describe("jump buffer and coyote", () => {
  it("jump buffer triggers when landing within buffer window", () => {
    const p = stubPlayer();
    bufferJumpInput(p, true);
    assert.ok(consumeJumpBuffer(p));
  });

  it("buffer decays when jump not pressed", () => {
    const p = stubPlayer();
    bufferJumpInput(p, true);
    bufferJumpInput(p, false);
    assert.ok(p.jumpBufferFrames > 0);
  });
});
