import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const publicGodot = path.join(webRoot, "public/godot");

describe("godot cache busting", () => {
  it("build-manifest.json exists with buildId", () => {
    const manifestPath = path.join(publicGodot, "build-manifest.json");
    assert.ok(fs.existsSync(manifestPath));
    const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8")) as {
      buildId: string;
      runtimePath: string;
    };
    assert.ok(manifest.buildId);
    assert.ok(manifest.runtimePath);
  });

  it("boot shell uses versioned runtime and rescue paths", () => {
    const html = fs.readFileSync(path.join(publicGodot, "index.html"), "utf8");
    assert.match(html, /runtime\/[^"']+\/index\.html\?v=/);
    assert.match(html, /rescue-runtime\.js\?v=/);
  });
});
