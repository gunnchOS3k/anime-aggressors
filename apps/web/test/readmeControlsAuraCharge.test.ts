import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "../../..");

describe("README aura charge controls", () => {
  it("documents Aura Charge section", () => {
    const readme = readFileSync(join(repoRoot, "README.md"), "utf8");
    assert.match(readme, /### Aura Charge/);
    assert.match(readme, /Super Ready/);
    assert.match(readme, /KeyF|Hold \*\*F\*\*/);
    assert.match(readme, /Slash|\*\*\/\*\*/);
  });

  it("hard gameplay research doc exists", () => {
    const doc = readFileSync(join(repoRoot, "docs/HARD_GAMEPLAY_REWORK_RESEARCH.md"), "utf8");
    assert.match(doc, /Aura Charge/);
    assert.match(doc, /fighter selection/);
  });
});
