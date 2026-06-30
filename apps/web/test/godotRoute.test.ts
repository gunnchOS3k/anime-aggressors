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

  it("GodotRuntimeScreen exists with project-safe embed path", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/screens/GodotRuntimeScreen.ts"), "utf8");
    assert.match(src, /godot-runtime-frame/);
    assert.match(src, /godotIndexPath/);
    assert.match(src, /probeGodotExport/);
  });

  it("public godot boot shell and runtime artifacts exist after export", () => {
    assert.ok(fs.existsSync(path.join(webRoot, "public/godot/index.html")));
    assert.ok(fs.existsSync(path.join(webRoot, "public/godot/rescue-runtime.js")));
    const runtimeDir = path.join(webRoot, "public/godot/runtime");
    const files = fs.readdirSync(runtimeDir);
    assert.ok(files.some((f) => f.endsWith(".wasm")));
    assert.ok(files.some((f) => f.endsWith(".pck")));
    assert.ok(files.some((f) => f.endsWith(".js")));
    assert.ok(files.some((f) => f === "index.html"));
  });

  it("godot project file exists", () => {
    assert.ok(fs.existsSync(path.join(webRoot, "../../game/godot/project.godot")));
  });
});
