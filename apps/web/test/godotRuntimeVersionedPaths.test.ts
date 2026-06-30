import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { resolveRuntimeDirFromRoot } from "../../../scripts/godot-export-shared.mjs";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const publicGodot = path.join(webRoot, "public/godot");

describe("godot runtime versioned paths", () => {
  it("runtime lives under versioned subdirectory from manifest", () => {
    const manifest = JSON.parse(
      fs.readFileSync(path.join(publicGodot, "build-manifest.json"), "utf8"),
    ) as { runtimePath: string; buildId: string };
    assert.match(manifest.runtimePath, /^runtime\/.+\/index\.html$/);
    const runtimeDir = resolveRuntimeDirFromRoot(publicGodot);
    assert.ok(fs.existsSync(path.join(runtimeDir, "index.html")));
    assert.ok(fs.existsSync(path.join(runtimeDir, "index.wasm")));
  });

  it("runtime index references cache-busted js", () => {
    const runtimeDir = resolveRuntimeDirFromRoot(publicGodot);
    const html = fs.readFileSync(path.join(runtimeDir, "index.html"), "utf8");
    assert.match(html, /index\.js\?v=/);
  });

  it("rescue runtime is explicitly labeled fallback", () => {
    const rescue = fs.readFileSync(path.join(publicGodot, "rescue-runtime.js"), "utf8");
    assert.match(rescue, /RESCUE RUNTIME — NOT FINAL GODOT BUILD/);
    const boot = fs.readFileSync(path.join(publicGodot, "index.html"), "utf8");
    assert.match(boot, /RESCUE RUNTIME|rescue runtime/i);
    assert.match(boot, /not the production fighter scene/i);
  });
});
