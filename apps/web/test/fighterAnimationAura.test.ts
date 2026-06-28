import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { ANIMATION_STATES } from "../src/renderer-three/fighters/FighterAnimationClips.ts";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("fighter animation aura", () => {
  it("includes auraCharge animation state", () => {
    assert.ok(ANIMATION_STATES.includes("auraCharge"));
  });

  it("procedural pose handles auraCharging action", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/renderer-three/fighters/ProceduralPoseSystem.ts"), "utf8");
    assert.match(src, /case "auraCharging"/);
    assert.match(src, /player\.aura\.level/);
  });
});
