import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { godotIndexPath } from "../src/godot/godotExportStatus.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

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

  it("exported index.html uses relative asset paths", () => {
    const html = fs.readFileSync(path.join(webRoot, "public/godot/index.html"), "utf8");
    assert.match(html, /src="index\.js"/);
    assert.doesNotMatch(html, /src="\/godot\//);
    assert.doesNotMatch(html, /src="\/index\.wasm"/);
    assert.match(html, /"executable":"index"/);
  });

  it("single-threaded export is flagged in generated html", () => {
    const html = fs.readFileSync(path.join(webRoot, "public/godot/index.html"), "utf8");
    assert.match(html, /GODOT_THREADS_ENABLED = false/);
  });
});
