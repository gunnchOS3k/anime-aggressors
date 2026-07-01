import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { execSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");

describe("game-godot primary validation", () => {
  it("validate-game-godot-primary.mjs passes", () => {
    const out = execSync("node scripts/validate-game-godot-primary.mjs", {
      cwd: repoRoot,
      encoding: "utf8",
    });
    assert.match(out, /all checks passed/);
  });
});
