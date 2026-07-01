import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");

describe("aa-verify-project artifacts", () => {
  it("verification script and PR48 docs exist", () => {
    assert.ok(fs.existsSync(path.join(repoRoot, "scripts/aa-verify-project.mjs")));
    assert.ok(fs.existsSync(path.join(repoRoot, "docs/GODOT_VERIFICATION_PLAN.md")));
    assert.ok(fs.existsSync(path.join(repoRoot, "docs/GODOT_EDITOR_PLAYTEST_SIGNOFF.md")));
    assert.ok(fs.existsSync(path.join(repoRoot, "docs/PLAYTEST_EVIDENCE_GUIDE.md")));
    assert.ok(fs.existsSync(path.join(repoRoot, "docs/PR48_VERIFICATION_REPORT.md")));
    assert.ok(fs.existsSync(path.join(repoRoot, "docs/MANUAL_PLAYTEST_SIGNOFF_TEMPLATE.md")));
    assert.ok(fs.existsSync(path.join(repoRoot, "playtest-evidence/.gitkeep")));
    assert.ok(fs.existsSync(path.join(repoRoot, "docs/manual-playtests/.gitkeep")));
  });

  it("Godot smoke test suite files exist", () => {
    for (const f of [
      "smoke_runner.gd",
      "smoke_boot.gd",
      "smoke_data_load.gd",
      "smoke_fighter_scene.gd",
      "smoke_training_scene.gd",
      "smoke_battle_scene.gd",
    ]) {
      assert.ok(fs.existsSync(path.join(repoRoot, "game-godot/tests", f)), f);
    }
  });
});
