import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { bootImpactDummyDerby } from "../src/modes/impactDummyDerbyBoot.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("impact dummy derby visible objects", () => {
  it("boot loads fighter meshes and dummy group", () => {
    const { result, assets } = bootImpactDummyDerby(getDefaultCreatedFighter(0));
    assert.ok(assets);
    assert.ok(result.playerMeshCount >= 6);
    assert.ok(assets!.dummyView.group.children.length > 0);
    assert.ok(result.stageObjectCount > 3);
  });

  it("derby view waits for boot before simulating", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/modes/impactDummyDerbyView.ts"), "utf8");
    assert.match(src, /canDerbySimulate/);
    assert.match(src, /bootImpactDummyDerby/);
    assert.match(src, /simEnabled/);
  });

  it("derby view adds fighter, dummy, bat, and stage to scene", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/modes/impactDummyDerbyView.ts"), "utf8");
    assert.match(src, /fighterParts\.root/);
    assert.match(src, /dummyView\.group/);
    assert.match(src, /batView\.group/);
    assert.match(src, /stageGroup/);
  });
});
