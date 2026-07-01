import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const dataRoot = path.join(repoRoot, "game/godot/data");

const FIGHTERS = [
  "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
  "nix-calder", "orion-vell", "vesper-nyx",
];

const REQUIRED_MOVES = [
  "neutral_attack", "side_attack", "up_attack", "down_attack", "dash_attack",
  "neutral_air", "forward_air", "back_air", "up_air", "down_air",
  "neutral_special", "side_special", "up_special", "down_special",
  "grab", "throw", "super",
];

describe("product completion data contracts", () => {
  it("move catalog covers all fighters with hit_socket and vfx_socket", () => {
    const catalog = JSON.parse(
      fs.readFileSync(path.join(dataRoot, "moves/move_catalog.json"), "utf8"),
    ) as Record<string, Record<string, { input?: string; hit_socket?: string; vfx_socket?: string }>>;
    for (const fighterId of FIGHTERS) {
      assert.ok(catalog[fighterId], fighterId);
      for (const moveId of REQUIRED_MOVES) {
        const move = Object.values(catalog[fighterId]).find((m) => m.input === moveId || m.move_id === moveId);
        assert.ok(move, `${fighterId}/${moveId}`);
        assert.ok(move?.hit_socket, `${fighterId}/${moveId} hit_socket`);
        assert.ok(move?.vfx_socket, `${fighterId}/${moveId} vfx_socket`);
      }
    }
  });

  it("combo catalog has beginner/intermediate/advanced/aura/super per fighter", () => {
    const catalog = JSON.parse(
      fs.readFileSync(path.join(dataRoot, "combos/combo_catalog.json"), "utf8"),
    ) as Record<string, Array<{ difficulty: string }>>;
    for (const fighterId of FIGHTERS) {
      const combos = catalog[fighterId];
      assert.equal(combos.filter((c) => c.difficulty === "beginner").length, 3, fighterId);
      assert.equal(combos.filter((c) => c.difficulty === "intermediate").length, 3, fighterId);
      assert.equal(combos.filter((c) => c.difficulty === "advanced").length, 2, fighterId);
      assert.ok(combos.some((c) => c.difficulty === "aura"), fighterId);
      assert.ok(combos.some((c) => c.difficulty === "super"), fighterId);
    }
  });

  it("validate:godot-product passes", () => {
    const out = execSync("npm run validate:godot-product", { cwd: repoRoot, encoding: "utf8" });
    assert.match(out, /product completion OK/);
  });

  it("README states product-completion mode", () => {
    const readme = fs.readFileSync(path.join(repoRoot, "README.md"), "utf8");
    assert.match(readme, /product-completion mode/i);
    assert.match(readme, /not complete.*all 7 fighters/i);
  });
});
