import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const publicGodot = path.join(webRoot, "public/godot");

describe("godot build manifest cache busting", () => {
  it("manifest includes bootPath and versioned runtimePath", () => {
    const manifest = JSON.parse(
      fs.readFileSync(path.join(publicGodot, "build-manifest.json"), "utf8"),
    ) as { buildId: string; bootPath?: string; runtimePath: string; rescueRuntimePath: string };
    assert.ok(manifest.buildId);
    assert.ok(manifest.runtimePath.includes(manifest.buildId));
    assert.equal(manifest.rescueRuntimePath, "rescue-runtime.js");
    if (manifest.bootPath) {
      assert.equal(manifest.bootPath, "index.html");
    }
  });

  it("export script writes bootPath into manifest", () => {
    const exportSrc = fs.readFileSync(
      path.join(webRoot, "../../scripts/export-godot-web.mjs"),
      "utf8",
    );
    assert.match(exportSrc, /bootPath:\s*"index\.html"/);
  });
});
