import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { CameraDirector } from "../src/renderer-three/CameraDirector.ts";
import { isBattleCameraAngled } from "../src/renderer-three/camera/BattleCamera.ts";
import { createInitialGameState, gameConfigFromRuleset, DEFAULT_RULESET } from "@anime-aggressors/game-core";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("battle 2.5D presentation", () => {
  it("camera director uses angled 2.5D orthographic camera", () => {
    const director = new CameraDirector(16 / 9, false);
    const cam = director.getCamera();
    assert.ok(isBattleCameraAngled(cam));
    assert.ok(cam.position.z > 100);
    assert.ok(cam.position.y > cam.position.z * 0.3);
  });

  it("battle uses contact shadows and 2.5D camera module", () => {
    const charView = fs.readFileSync(path.join(webRoot, "src/renderer-three/CharacterView.ts"), "utf8");
    assert.match(charView, /ContactShadow/);
    assert.match(charView, /player\.id \* 1\.4/);
    const cam = fs.readFileSync(path.join(webRoot, "src/renderer-three/camera/BattleCamera.ts"), "utf8");
    assert.match(cam, /BATTLE_CAM_ELEVATION/);
  });

  it("ember vs orion battle config creates two players", () => {
    const ember = getAllDefaultCreatedFighters().find((f) => f.id === "ember-vale")!;
    const orion = getAllDefaultCreatedFighters().find((f) => f.id === "orion-vell")!;
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [ember, orion], 7);
    const state = createInitialGameState(config);
    assert.equal(state.players.length, 2);
    assert.match(state.players[0]!.fighterName, /Ember/i);
    assert.match(state.players[1]!.fighterName, /Orion/i);
  });
});
