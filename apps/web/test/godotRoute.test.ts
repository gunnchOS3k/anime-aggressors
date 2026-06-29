import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { APP_ROUTES, hashToMode, MODE_TO_ROUTE } from "../src/routes.ts";
import { MAIN_MENU_PRIMARY } from "../src/ui/mainMenuConfig.ts";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("godot route", () => {
  it("defines #/godot hash route", () => {
    assert.equal(APP_ROUTES.godot, "#/godot");
    assert.equal(hashToMode("#/godot"), "godot");
    assert.equal(MODE_TO_ROUTE.godot, "#/godot");
  });

  it("main menu includes Play Godot Combat Prototype", () => {
    const item = MAIN_MENU_PRIMARY.find((m) => m.id === "btn-godot-combat");
    assert.ok(item);
    assert.match(item!.label, /Godot Combat Prototype/i);
  });

  it("GodotRuntimeScreen exists", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/screens/GodotRuntimeScreen.ts"), "utf8");
    assert.match(src, /godot-runtime-frame/);
    assert.match(src, /godot\/index\.html/);
  });

  it("godot project file exists", () => {
    assert.ok(fs.existsSync(path.join(webRoot, "../../game/godot/project.godot")));
  });
});
