import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { renderReadyFightSequence } from "../src/ui/ReadyFightSequence.ts";

describe("ready fight sequence", () => {
  it("renders ready fight label", () => {
    const html = renderReadyFightSequence("READY… FIGHT!");
    assert.match(html, /ready-fight-sequence/);
    assert.match(html, /READY… FIGHT!/);
  });
});
