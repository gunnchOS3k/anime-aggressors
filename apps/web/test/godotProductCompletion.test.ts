import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const legacyDataRoot = path.join(repoRoot, "game/godot/data");
const primaryMovesRoot = path.join(repoRoot, "game-godot/data/moves");

const FIGHTERS = [
  "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
  "nix-calder", "orion-vell", "vesper-nyx",
];

const PRIMARY_MOVE_IDS = [
  "jab_1", "jab_2", "jab_finisher", "forward_tilt", "up_tilt", "down_tilt",
  "dash_attack", "heavy_attack", "neutral_air", "forward_air", "up_air", "down_air",
  "neutral_special_projectile", "side_special", "up_special_recovery", "down_special",
  "grab", "throw_forward", "throw_back", "throw_up", "throw_down",
  "aura_charge", "aura_burst",
];

describe("product completion data contracts", () => {
  it("legacy game/godot move catalog still present for reference", () => {
    const catalogPath = path.join(legacyDataRoot, "moves/move_catalog.json");
    assert.ok(fs.existsSync(catalogPath), "legacy move catalog");
    const catalog = JSON.parse(fs.readFileSync(catalogPath, "utf8")) as Record<string, unknown>;
    for (const fighterId of FIGHTERS) {
      assert.ok(catalog[fighterId], fighterId);
    }
  });

  it("primary game-godot move manifests cover full-scope starter kit", () => {
    for (const fighterId of FIGHTERS) {
      const manifest = JSON.parse(
        fs.readFileSync(path.join(primaryMovesRoot, `${fighterId}.json`), "utf8"),
      ) as { schema_version: number; moves: Array<{ move_id: string }> };
      assert.equal(manifest.schema_version, 2, `${fighterId} schema_version`);
      const ids = manifest.moves.map((m) => m.move_id);
      for (const moveId of PRIMARY_MOVE_IDS) {
        assert.ok(ids.includes(moveId), `${fighterId}/${moveId}`);
      }
    }
  });

  it("validate:full-scope-production passes", () => {
    const out = execSync("npm run validate:full-scope-production", { cwd: repoRoot, encoding: "utf8" });
    assert.match(out, /all checks passed/);
  });

  it("README states product-completion mode and full-scope framing", () => {
    const readme = fs.readFileSync(path.join(repoRoot, "README.md"), "utf8");
    assert.match(readme, /product-completion mode/i);
    assert.match(readme, /not complete.*all 7 fighters/i);
    assert.match(readme, /game-godot/i);
  });
});
