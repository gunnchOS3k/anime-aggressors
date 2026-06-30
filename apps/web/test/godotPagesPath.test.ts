import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { godotIndexPath } from "../src/godot/godotExportStatus.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const publicGodot = path.join(webRoot, "public/godot");
const publicRuntime = path.join(publicGodot, "runtime");

describe("godot GitHub Pages paths", () => {
  it("godotIndexPath is project-site safe under /anime-aggressors/", () => {
    assert.equal(godotIndexPath("/anime-aggressors/"), "/anime-aggressors/godot/index.html");
    assert.doesNotMatch(godotIndexPath("/anime-aggressors/"), /^\/godot\//);
  });

  it("GodotRuntimeScreen iframe uses godotIndexPath not root /godot/", () => {
    const screen = fs.readFileSync(path.join(webRoot, "src/screens/GodotRuntimeScreen.ts"), "utf8");
    assert.match(screen, /godotIndexPath/);
    assert.doesNotMatch(screen, /src="\/godot\/index\.html"/);
  });

  it("boot shell references nested runtime and rescue fallback", () => {
    const html = fs.readFileSync(path.join(publicGodot, "index.html"), "utf8");
    assert.match(html, /runtime\/index\.html/);
    assert.match(html, /rescue-runtime\.js/);
    assert.match(html, /rescue runtime|AARescueRuntime/i);
    assert.doesNotMatch(html, /src="\/godot\//);
    assert.doesNotMatch(html, /src="\/index\.wasm"/);
  });

  it("raw runtime export uses relative asset paths and single-threaded mode", () => {
    const html = fs.readFileSync(path.join(publicRuntime, "index.html"), "utf8");
    assert.match(html, /src="index\.js"/);
    assert.doesNotMatch(html, /src="\/godot\//);
    assert.doesNotMatch(html, /src="\/index\.wasm"/);
    assert.match(html, /"executable":"index"/);
    assert.match(html, /GODOT_THREADS_ENABLED = false/);
  });
});
