import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");

describe("game start flow research docs", () => {
  it("includes gameplay market research doc", () => {
    const p = path.join(repoRoot, "docs/GAMEPLAY_MARKET_RESEARCH_PLATFORM_FIGHTERS.md");
    const text = fs.readFileSync(p, "utf8");
    assert.match(text, /Super Smash Bros/);
    assert.match(text, /Anime Aggressors Target/);
  });

  it("includes game start flow doc", () => {
    const p = path.join(repoRoot, "docs/GAME_START_FLOW_MARKET_RESEARCH.md");
    const text = fs.readFileSync(p, "utf8");
    assert.match(text, /Fighter Select/);
    assert.match(text, /Impact Dummy Derby/);
  });
});
