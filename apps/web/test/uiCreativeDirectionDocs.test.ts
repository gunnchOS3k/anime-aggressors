import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");

describe("UI creative direction docs", () => {
  it("creative direction study exists with required sections", () => {
    const md = fs.readFileSync(path.join(root, "docs/UI_CREATIVE_DIRECTION_STUDY.md"), "utf8");
    for (const section of [
      "What a main menu does emotionally",
      "What a main menu does functionally",
      "Common game menu formulas",
      "Unorthodox game menu choices",
      "Why creative directors choose physical-space menus",
      "Why some games choose minimalist menus",
      "Why fighting games emphasize character, mode, and immediacy",
      "Wireframe lifecycle from concept to final UI",
      "Anime Aggressors menu design principles",
      "Final selected direction",
      "Elemental Arena Hub",
    ]) {
      assert.match(md, new RegExp(section, "i"), section);
    }
  });

  it("wireframe lifecycle doc exists with process steps", () => {
    const md = fs.readFileSync(path.join(root, "docs/UI_WIREFRAME_LIFECYCLE.md"), "utf8");
    for (const step of [
      "Player fantasy statement",
      "First 5 seconds test",
      "Information architecture",
      "Low-fidelity wireframe",
      "Motion wireframe",
      "Controller navigation prototype",
      "Visual identity pass",
      "Usability pass",
      "Accessibility pass",
      "Build integration",
      "Playtest feedback",
      "Final polish",
    ]) {
      assert.match(md, new RegExp(step, "i"), step);
    }
  });
});
