import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { shouldShowDerbyResults } from "../src/modes/impactDummyDerbyBoot.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("impact dummy derby no fake results", () => {
  it("blocks normal results when no launch occurred", () => {
    assert.equal(
      shouldShowDerbyResults({
        phase: "results",
        totalHits: 0,
        dummy: { damage: 0, launched: false },
      }),
      false,
    );
  });

  it("derby view shows no-launch message instead of scoring", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/modes/impactDummyDerbyView.ts"), "utf8");
    assert.match(src, /No launch recorded/);
    assert.match(src, /shouldShowDerbyResults/);
  });

  it("timer gated behind simEnabled boot check", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/modes/impactDummyDerbyView.ts"), "utf8");
    assert.match(src, /if \(simEnabled && state\.phase !== "results"\)/);
  });
});
