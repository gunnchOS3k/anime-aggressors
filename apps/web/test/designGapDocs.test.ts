import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");

describe("design gap docs", () => {
  it("genre gap analysis exists with required sections", () => {
    const md = fs.readFileSync(path.join(root, "docs/GENRE_GAP_ANALYSIS.md"), "utf8");
    for (const section of [
      "Competitive references",
      "What Anime Aggressors already has",
      "What the genre expects",
      "Missing systems",
      "Priority roadmap",
      "Current pass scope",
      "Future pass scope",
    ]) {
      assert.match(md, new RegExp(section, "i"), section);
    }
  });

  it("accessibility and depth doc exists", () => {
    const md = fs.readFileSync(path.join(root, "docs/DESIGN_ACCESSIBILITY_AND_DEPTH.md"), "utf8");
    assert.match(md, /Aura Charge/);
    assert.match(md, /input grammar/i);
  });
});
